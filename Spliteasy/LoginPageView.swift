//
//  LoginPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/25/26.
//

import SwiftUI
import FirebaseAuth

struct LoginPageView: View {
    enum AuthMode: String, CaseIterable {
        case login = "Login"
        case signup = "Create Account"
    }

    @State private var selectedMode: AuthMode = .login

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phoneNumber: String = ""
    @State private var identifier: String = ""
    @State private var signupEmail: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""

    @State private var showForgotPasswordPage = false
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    let onLogin: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                VStack(spacing: 10) {
                    Text("SplitEasy")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text(selectedMode == .login ? "Login to continue" : "Create your account")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                }

                Picker("", selection: $selectedMode) {
                    ForEach(AuthMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    if selectedMode == .signup {
                        authField(title: "First Name", placeholder: "Enter first name", text: $firstName, kind: .name)
                        authField(title: "Last Name", placeholder: "Enter last name", text: $lastName, kind: .name)
                        authField(title: "Phone Number", placeholder: "(xxx) xxx-xxxx", text: $phoneNumber, kind: .phone)
                        authField(title: "Email", placeholder: "Enter email", text: $signupEmail, kind: .email)

                        passwordField(
                            title: "Create Password",
                            text: $password,
                            placeholder: "Create your password"
                        )

                        passwordField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            placeholder: "Re-enter your password"
                        )
                    } else {
                        authField(
                            title: "Email or Phone Number",
                            placeholder: "Enter email or phone number",
                            text: $identifier,
                            kind: .identifier
                        )

                        passwordField(
                            title: "Password",
                            text: $password,
                            placeholder: "Enter password"
                        )

                        HStack {
                            Spacer()

                            Button {
                                showForgotPasswordPage = true
                            } label: {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppPalette.accentMid)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if !successMessage.isEmpty {
                        Text(successMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green.opacity(0.90))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    handlePrimaryAction()
                } label: {
                    HStack(spacing: 10) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(selectedMode == .login ? "Login" : "Create Account")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .disabled(isLoading || !canSubmit)
                .opacity((isLoading || !canSubmit) ? 0.65 : 1.0)

                Spacer()
            }
        }
        .sheet(isPresented: $showForgotPasswordPage) {
            ForgotPasswordPageView()
        }
        .onChange(of: selectedMode) { _, _ in
            clearMessages()
            password = ""
            confirmPassword = ""
        }
        .onChange(of: phoneNumber) { _, newValue in
            let formatted = FirebaseService.formattedPhoneNumber(
                from: FirebaseService.normalizedPhoneDigits(newValue)
            )
            if formatted != newValue {
                phoneNumber = formatted
            }
        }
    }

    private var trimmedIdentifier: String {
        identifier.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedSignupEmail: String {
        signupEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var trimmedFirstName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedLastName: String {
        lastName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var cleanedPhoneDigits: String {
        FirebaseService.normalizedPhoneDigits(phoneNumber)
    }

    private var canSubmit: Bool {
        switch selectedMode {
        case .login:
            return !trimmedIdentifier.isEmpty && !password.isEmpty

        case .signup:
            return !trimmedFirstName.isEmpty &&
                !trimmedLastName.isEmpty &&
                cleanedPhoneDigits.count == 10 &&
                !trimmedSignupEmail.isEmpty &&
                password.count >= 6 &&
                confirmPassword == password
        }
    }

    private func handlePrimaryAction() {
        clearMessages()
        isLoading = true

        switch selectedMode {
        case .login:
            FirebaseService.shared.loginUser(
                identifier: trimmedIdentifier,
                password: password
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false

                    switch result {
                    case .success:
                        onLogin()
                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }

        case .signup:
            guard password == confirmPassword else {
                isLoading = false
                errorMessage = "Passwords do not match."
                return
            }

            FirebaseService.shared.registerUser(
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                phone: phoneNumber,
                email: trimmedSignupEmail,
                password: password
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false

                    switch result {
                    case .success:
                        successMessage = "Account created successfully. Please log in."
                        selectedMode = .login
                        identifier = trimmedSignupEmail
                        password = ""
                        confirmPassword = ""
                        firstName = ""
                        lastName = ""
                        phoneNumber = ""
                        signupEmail = ""

                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func clearMessages() {
        errorMessage = ""
        successMessage = ""
    }

    private func authField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        kind: AuthFieldKind
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            authTextField(placeholder: placeholder, text: text, kind: kind)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppPalette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )
                )
        }
    }

    @ViewBuilder
    private func authTextField(
        placeholder: String,
        text: Binding<String>,
        kind: AuthFieldKind
    ) -> some View {
        #if os(iOS)
        switch kind {
        case .email:
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)

        case .phone:
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

        case .identifier:
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)

        case .name:
            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
        }
        #else
        TextField(placeholder, text: text)
        #endif
    }

    private func passwordField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            securePasswordField(text: text, placeholder: placeholder)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppPalette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )
                )
        }
    }

    @ViewBuilder
    private func securePasswordField(text: Binding<String>, placeholder: String) -> some View {
        #if os(iOS)
        SecureField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.oneTimeCode)
        #else
        SecureField(placeholder, text: text)
        #endif
    }
}

enum AuthFieldKind {
    case email
    case phone
    case identifier
    case name
}

struct ForgotPasswordPageView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var showConfirmation = false
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                VStack(spacing: 22) {
                    Spacer()

                    VStack(spacing: 10) {
                        Text("Reset Password")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)

                        Text("Enter your registered email")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppPalette.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Email")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppPalette.secondaryText)

                        forgotPasswordEmailField
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppPalette.primaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(AppPalette.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(AppPalette.border, lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 24)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .padding(.horizontal, 24)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        sendResetLink()
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text("Send Reset Link")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .opacity(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? 0.65 : 1.0)

                    if showConfirmation {
                        VStack(spacing: 8) {
                            Image(systemName: "envelope.badge")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppPalette.accentMid)

                            Text("Reset link sent")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppPalette.primaryText)

                            Text("A password reset email has been sent.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppPalette.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                    }

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var forgotPasswordEmailField: some View {
        #if os(iOS)
        TextField("Enter email", text: $email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
        #else
        TextField("Enter email", text: $email)
        #endif
    }

    private func sendResetLink() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        errorMessage = ""
        showConfirmation = false
        isLoading = true

        FirebaseService.shared.sendPasswordReset(email: trimmedEmail) { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success:
                    showConfirmation = true
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.card)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Forgot Password")
                .font(.system(size: 24, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            Spacer()

            Color.clear.frame(width: 46, height: 46)
        }
    }
}
