// Login and signup page with forgot password support.
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

    @State private var selectedMode: AuthMode
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

    @State private var showLoginPassword = false
    @State private var showSignupPassword = false
    @State private var showConfirmPassword = false

    let onLogin: () -> Void
    let onBack: (() -> Void)?

    init(
        initialMode: AuthMode = .login,
        onLogin: @escaping () -> Void,
        onBack: (() -> Void)? = nil
    ) {
        self._selectedMode = State(initialValue: initialMode)
        self.onLogin = onLogin
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 24)
                    .padding(.top, 10)

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
                .padding(.top, 26)

                VStack(spacing: 16) {
                    if selectedMode == .signup {
                        authField(title: "First Name", placeholder: "Enter first name", text: $firstName, kind: .name)
                        authField(title: "Last Name", placeholder: "Enter last name", text: $lastName, kind: .name)
                        authField(title: "Phone Number", placeholder: "(xxx) xxx-xxxx", text: $phoneNumber, kind: .phone)
                        authField(title: "Email", placeholder: "Enter email", text: $signupEmail, kind: .email)

                        passwordField(
                            title: "Create Password",
                            text: $password,
                            placeholder: "Create your password",
                            isVisible: $showSignupPassword
                        )

                        passwordField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            placeholder: "Re-enter your password",
                            isVisible: $showConfirmPassword
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
                            placeholder: "Enter password",
                            isVisible: $showLoginPassword
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
                .padding(.top, 24)

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
                .padding(.top, 26)
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
            showLoginPassword = false
            showSignupPassword = false
            showConfirmPassword = false
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

    private var headerBar: some View {
        HStack {
            if let onBack {
                Button {
                    onBack()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(AppPalette.card)
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: 1)
                            )

                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Color.clear.frame(width: 46, height: 46)
            }

            Spacer()
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

        switch selectedMode {
        case .login:
            if let validationError = validateLoginFields() {
                errorMessage = validationError
                return
            }

            isLoading = true
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
            if let validationError = validateSignupFields() {
                errorMessage = validationError
                return
            }

            isLoading = true
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
                        showLoginPassword = false
                        showSignupPassword = false
                        showConfirmPassword = false

                    case .failure(let error):
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    private func validateLoginFields() -> String? {
        if trimmedIdentifier.isEmpty {
            return "Please enter your email or phone number."
        }

        if password.isEmpty {
            return "Please enter your password."
        }

        if !trimmedIdentifier.contains("@") {
            let digits = FirebaseService.normalizedPhoneDigits(trimmedIdentifier)
            if !digits.isEmpty && digits.count != 10 {
                return "Please enter a valid 10-digit phone number or a valid email address."
            }
        } else if !isValidEmail(trimmedIdentifier) {
            return "Please enter a valid email address."
        }

        return nil
    }

    private func validateSignupFields() -> String? {
        if trimmedFirstName.isEmpty {
            return "Please enter your first name."
        }

        if trimmedLastName.isEmpty {
            return "Please enter your last name."
        }

        if cleanedPhoneDigits.count != 10 {
            return "Please enter a valid 10-digit phone number."
        }

        if trimmedSignupEmail.isEmpty {
            return "Please enter your email address."
        }

        if !isValidEmail(trimmedSignupEmail) {
            return "Please enter a valid email address."
        }

        if password.count < 6 {
            return "Password must be at least 6 characters."
        }

        if confirmPassword.isEmpty {
            return "Please confirm your password."
        }

        if password != confirmPassword {
            return "Passwords do not match."
        }

        return nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailPredicate = NSPredicate(
            format: "SELF MATCHES[c] %@",
            "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        )
        return emailPredicate.evaluate(with: email)
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

    private func passwordField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        isVisible: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            passwordInputField(text: text, placeholder: placeholder, isVisible: isVisible)
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

    private func passwordInputField(
        text: Binding<String>,
        placeholder: String,
        isVisible: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            Group {
                if isVisible.wrappedValue {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                } else {
                    SecureField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.oneTimeCode)
                }
            }

            Button {
                isVisible.wrappedValue.toggle()
            } label: {
                Image(systemName: isVisible.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
        }
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
                    .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity((isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.65 : 1)

                    Spacer()
                }
            }
        }
        .alert("Reset Link Sent", isPresented: $showConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("A password reset link has been sent to your email.")
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )

                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                }
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    @ViewBuilder
    private var forgotPasswordEmailField: some View {
        #if os(iOS)
        TextField("Enter email", text: $email)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .keyboardType(.emailAddress)
        #else
        TextField("Enter email", text: $email)
        #endif
    }

    private func sendResetLink() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return }

        isLoading = true
        errorMessage = ""

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
}
