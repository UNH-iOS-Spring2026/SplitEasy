import SwiftUI
#if os(iOS)
import UIKit
#endif

struct AccountPageView: View {
    @Binding var showThemeMenu: Bool
    @Binding var profileName: String
    @Binding var profileEmail: String
    @Binding var profilePhone: String

    let notifications: [AppNotificationItem]
    let onSaveProfile: (String, String, String) -> Void
    let onSubmitFeedback: (Int, String) -> Void
    let onContactSupport: (String, String) -> Void
    let onResetPassword: (String, String, @escaping (Result<Void, Error>) -> Void) -> Void
    let onSignOut: () -> Void

    @State private var nicknameText: String = ""
    @State private var emailText: String = ""
    @State private var phoneText: String = ""

    #if os(iOS)
    @State private var selectedImage: UIImage?
    #endif

    @State private var showImagePicker = false
    @State private var profileImageURL: String = ""
    @State private var isUploadingProfileImage = false
    @State private var isSavingProfile = false
    @State private var profileMessage: String = ""
    @State private var profileMessageColor: Color = .green.opacity(0.85)

    @State private var showNotificationsSheet = false
    @State private var showFeedbackSheet = false
    @State private var showSupportSheet = false
    @State private var showResetPasswordSheet = false

    @State private var feedbackRating = 0
    @State private var feedbackMessage = ""
    @State private var supportSubject = ""
    @State private var supportMessage = ""

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var reenteredPassword = ""
    @State private var resetPasswordMessage = ""
    @State private var resetPasswordMessageColor: Color = .green.opacity(0.85)
    @State private var isUpdatingPassword = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                fixedHeaderView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .zIndex(10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        profileCard
                        accountFieldsCard
                        quickActionsCard
                        supportActionsCard
                        signOutButton

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            syncFromBindings()
            loadProfile()
        }
        #if os(iOS)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .onChange(of: selectedImage) { _, newImage in
            uploadProfileImage(newImage)
        }
        #endif
        .sheet(isPresented: $showNotificationsSheet) {
            notificationsSheet
        }
        .sheet(isPresented: $showFeedbackSheet) {
            feedbackSheet
        }
        .sheet(isPresented: $showSupportSheet) {
            supportSheet
        }
        .sheet(isPresented: $showResetPasswordSheet) {
            resetPasswordSheet
        }
        .onChange(of: phoneText) { _, newValue in
            let formatted = formattedPhone(newValue)
            if formatted != newValue {
                phoneText = formatted
            } else {
                clearProfileMessage()
            }
        }
        .onChange(of: nicknameText) { _, _ in
            clearProfileMessage()
        }
        .onChange(of: emailText) { _, _ in
            clearProfileMessage()
        }
    }

    private var fixedHeaderView: some View {
        HStack {
            ThemeHeaderButton(showThemeMenu: $showThemeMenu)
                .padding(.top, 8)

            Spacer()

            Text("Account")
                .font(.system(size: 28, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)
                .padding(.top, 8)
        }
    }

    private var profileCard: some View {
        VStack(spacing: 12) {
            Button {
                #if os(iOS)
                showImagePicker = true
                #endif
            } label: {
                ZStack {
                    if let url = URL(string: profileImageURL),
                       !profileImageURL.isEmpty,
                       profileImageURL.lowercased().hasPrefix("http") {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(AppPalette.accentMid.opacity(0.18))
                                    .frame(width: 96, height: 96)
                                    .overlay(ProgressView())

                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 96, height: 96)
                                    .clipShape(Circle())

                            case .failure:
                                defaultProfileCircle

                            @unknown default:
                                defaultProfileCircle
                            }
                        }
                    } else {
                        defaultProfileCircle
                    }

                    if isUploadingProfileImage {
                        Circle()
                            .fill(Color.black.opacity(0.25))
                            .frame(width: 96, height: 96)
                            .overlay(
                                ProgressView()
                                    .tint(.white)
                            )
                    }
                }
            }
            .buttonStyle(.plain)

            Text(displayNickname)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Text(profileImageHintText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
        }
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var profileImageHintText: String {
        #if os(iOS)
        return isUploadingProfileImage ? "Uploading image..." : "Tap image to update"
        #else
        return "Profile image upload is available on iOS"
        #endif
    }

    private var accountFieldsCard: some View {
        VStack(spacing: 16) {
            accountField(title: "Nick Name", text: $nicknameText, placeholder: "Enter nickname")
            accountField(title: "Email", text: $emailText, placeholder: "Enter email", keyboard: .email)
            accountField(title: "Phone", text: $phoneText, placeholder: "(xxx) xxx-xxxx", keyboard: .phone)

            if !profileMessage.isEmpty {
                Text(profileMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(profileMessageColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                saveProfile()
            } label: {
                HStack(spacing: 10) {
                    if isSavingProfile {
                        ProgressView()
                            .tint(.white)
                    }

                    Text("Save Profile")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppPalette.accentStart, AppPalette.accentEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSavingProfile || isUploadingProfileImage || !canSaveProfile)
            .opacity((isSavingProfile || isUploadingProfileImage || !canSaveProfile) ? 0.65 : 1)

            Button {
                resetPasswordMessage = ""
                currentPassword = ""
                newPassword = ""
                reenteredPassword = ""
                showResetPasswordSheet = true
            } label: {
                Text("Reset Password")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppPalette.accentMid.opacity(0.35), lineWidth: 1.2)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(cardBackground)
    }

    private func accountField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboard: AccountKeyboardKind = .standard
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            accountTextField(placeholder: placeholder, text: text, keyboard: keyboard)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(fieldBackground)
        }
    }

    @ViewBuilder
    private func accountTextField(
        placeholder: String,
        text: Binding<String>,
        keyboard: AccountKeyboardKind
    ) -> some View {
        #if os(iOS)
        TextField(placeholder, text: text)
            .keyboardType(keyboard.uiKeyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        #else
        TextField(placeholder, text: text)
        #endif
    }

    private var quickActionsCard: some View {
        VStack(spacing: 12) {
            profileActionRow(
                icon: "bell.badge",
                title: "Notifications",
                subtitle: "\(notifications.count) recent"
            ) {
                showNotificationsSheet = true
            }

            profileActionRow(
                icon: "star.bubble",
                title: "Feedback",
                subtitle: "Rate the app"
            ) {
                showFeedbackSheet = true
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var supportActionsCard: some View {
        VStack(spacing: 12) {
            profileActionRow(
                icon: "phone.circle",
                title: "Contact Us",
                subtitle: "Send your question"
            ) {
                showSupportSheet = true
            }
        }
        .padding(18)
        .background(cardBackground)
    }

    private var signOutButton: some View {
        Button {
            onSignOut()
        } label: {
            Text("Sign Out")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.red.opacity(0.88))
                )
        }
        .buttonStyle(.plain)
    }

    private func profileActionRow(
        icon: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.rowIconBg)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.accentMid)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(AppPalette.secondaryText)
            }
        }
        .buttonStyle(.plain)
    }

    private var notificationsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if notifications.isEmpty {
                        emptySheetState(
                            icon: "bell.slash",
                            title: "No notifications yet",
                            subtitle: "Your recent reminders and updates will appear here."
                        )
                    } else {
                        ForEach(notifications) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.title)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppPalette.primaryText)

                                Text(item.message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppPalette.secondaryText)

                                Text(item.timeText)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppPalette.accentMid)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppPalette.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(AppPalette.border, lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Notifications")
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .presentationDetents([.medium, .large])
    }

    private var feedbackSheet: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Rate the app")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { value in
                        Button {
                            feedbackRating = value
                        } label: {
                            Image(systemName: value <= feedbackRating ? "star.fill" : "star")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextEditor(text: $feedbackMessage)
                    .frame(height: 160)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: 1)
                            )
                    )

                Button {
                    let trimmed = feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSubmitFeedback(feedbackRating, trimmed)
                    feedbackRating = 0
                    feedbackMessage = ""
                    showFeedbackSheet = false
                } label: {
                    Text("Submit Feedback")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Feedback")
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .presentationDetents([.medium, .large])
    }

    private var supportSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Subject", text: $supportSubject)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(fieldBackground)

                TextEditor(text: $supportMessage)
                    .frame(height: 180)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: 1)
                            )
                    )

                Button {
                    onContactSupport(
                        supportSubject.trimmingCharacters(in: .whitespacesAndNewlines),
                        supportMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    supportSubject = ""
                    supportMessage = ""
                    showSupportSheet = false
                } label: {
                    Text("Send Message")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Contact Us")
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .presentationDetents([.medium, .large])
    }

    private var resetPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                resetSecureField(title: "Current Password", text: $currentPassword, placeholder: "Enter current password")
                resetSecureField(title: "New Password", text: $newPassword, placeholder: "Enter new password")
                resetSecureField(title: "Re-enter New Password", text: $reenteredPassword, placeholder: "Re-enter new password")

                if !resetPasswordMessage.isEmpty {
                    Text(resetPasswordMessage)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(resetPasswordMessageColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    updatePassword()
                } label: {
                    HStack(spacing: 10) {
                        if isUpdatingPassword {
                            ProgressView()
                                .tint(.white)
                        }

                        Text("Update Password")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.accentStart, AppPalette.accentEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isUpdatingPassword || !canUpdatePassword)
                .opacity((isUpdatingPassword || !canUpdatePassword) ? 0.65 : 1)

                Spacer()
            }
            .padding(20)
            .navigationTitle("Reset Password")
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
        .presentationDetents([.medium, .large])
    }

    private func resetSecureField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            resetSecureInput(text: text, placeholder: placeholder)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(fieldBackground)
        }
    }

    @ViewBuilder
    private func resetSecureInput(text: Binding<String>, placeholder: String) -> some View {
        #if os(iOS)
        SecureField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .textContentType(.oneTimeCode)
        #else
        SecureField(placeholder, text: text)
        #endif
    }

    private var displayNickname: String {
        let trimmed = nicknameText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Add nickname" : trimmed
    }

    private var defaultProfileCircle: some View {
        Circle()
            .fill(AppPalette.accentMid.opacity(0.18))
            .frame(width: 96, height: 96)
            .overlay(
                Image(systemName: "camera.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
            )
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(AppPalette.searchField)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)
    }

    private func emptySheetState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var canSaveProfile: Bool {
        !nicknameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !phoneText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canUpdatePassword: Bool {
        !currentPassword.isEmpty &&
        newPassword.count >= 6 &&
        reenteredPassword == newPassword
    }

    private func syncFromBindings() {
        nicknameText = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        emailText = profileEmail
        phoneText = formattedPhone(profilePhone)
    }

    private func loadProfile() {
        FirebaseService.shared.fetchCurrentUserProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    let cleanedNickname = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cleanedImageURL = profile.profileImageURL.trimmingCharacters(in: .whitespacesAndNewlines)

                    nicknameText = cleanedNickname
                    emailText = profile.email.isEmpty ? (FirebaseService.shared.currentUserEmail ?? "") : profile.email
                    phoneText = formattedPhone(profile.phone)

                    profileName = cleanedNickname
                    profileEmail = emailText
                    profilePhone = phoneText

                    if cleanedImageURL.lowercased().hasPrefix("http") {
                        profileImageURL = cleanedImageURL
                    } else {
                        profileImageURL = ""
                    }

                    profileMessage = ""

                case .failure(let error):
                    profileMessage = error.localizedDescription
                    profileMessageColor = .red.opacity(0.85)
                }
            }
        }
    }

    #if os(iOS)
    private func uploadProfileImage(_ image: UIImage?) {
        guard let image,
              let data = image.jpegData(compressionQuality: 0.6) else { return }

        clearProfileMessage()
        isUploadingProfileImage = true

        FirebaseService.shared.uploadCurrentUserProfileImage(data: data) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    profileImageURL = url

                    FirebaseService.shared.updateCurrentUserProfileImageURL(url) { updateResult in
                        DispatchQueue.main.async {
                            isUploadingProfileImage = false

                            switch updateResult {
                            case .success:
                                profileMessage = "Profile image updated."
                                profileMessageColor = .green.opacity(0.85)

                            case .failure(let error):
                                profileImageURL = ""
                                profileMessage = error.localizedDescription
                                profileMessageColor = .red.opacity(0.85)
                            }
                        }
                    }

                case .failure(let error):
                    isUploadingProfileImage = false
                    profileImageURL = ""
                    profileMessage = error.localizedDescription
                    profileMessageColor = .red.opacity(0.85)
                }
            }
        }
    }
    #endif

    private func saveProfile() {
        let trimmedNickname = nicknameText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPhone = phoneText.trimmingCharacters(in: .whitespacesAndNewlines)

        clearProfileMessage()
        isSavingProfile = true

        onSaveProfile(trimmedNickname, trimmedEmail, trimmedPhone)

        FirebaseService.shared.fetchCurrentUserProfile { result in
            DispatchQueue.main.async {
                isSavingProfile = false

                switch result {
                case .success(let profile):
                    nicknameText = profile.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                    emailText = profile.email.isEmpty ? trimmedEmail : profile.email
                    phoneText = formattedPhone(profile.phone)

                    profileName = nicknameText
                    profileEmail = emailText
                    profilePhone = phoneText

                    profileMessage = "Profile saved successfully."
                    profileMessageColor = .green.opacity(0.85)

                case .failure:
                    profileName = trimmedNickname
                    profileEmail = trimmedEmail
                    profilePhone = trimmedPhone
                    nicknameText = trimmedNickname

                    profileMessage = "Profile saved successfully."
                    profileMessageColor = .green.opacity(0.85)
                }
            }
        }
    }

    private func updatePassword() {
        resetPasswordMessage = ""

        guard newPassword == reenteredPassword else {
            resetPasswordMessage = "New password and re-entered password do not match."
            resetPasswordMessageColor = .red.opacity(0.85)
            return
        }

        guard newPassword.count >= 6 else {
            resetPasswordMessage = "New password must be at least 6 characters."
            resetPasswordMessageColor = .red.opacity(0.85)
            return
        }

        isUpdatingPassword = true

        onResetPassword(currentPassword, newPassword) { result in
            DispatchQueue.main.async {
                isUpdatingPassword = false

                switch result {
                case .success:
                    resetPasswordMessage = "Password updated successfully."
                    resetPasswordMessageColor = .green.opacity(0.85)
                    currentPassword = ""
                    newPassword = ""
                    reenteredPassword = ""

                case .failure(let error):
                    resetPasswordMessage = error.localizedDescription
                    resetPasswordMessageColor = .red.opacity(0.85)
                }
            }
        }
    }

    private func clearProfileMessage() {
        if !isSavingProfile && !isUploadingProfileImage {
            profileMessage = ""
        }
    }

    private func formattedPhone(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        let limited = String(digits.prefix(10))

        if limited.isEmpty { return "" }
        if limited.count < 4 { return limited }

        if limited.count < 7 {
            let first = limited.prefix(3)
            let second = limited.dropFirst(3)
            return "(\(first)) \(second)"
        }

        let area = limited.prefix(3)
        let middle = limited.dropFirst(3).prefix(3)
        let last = limited.dropFirst(6)
        return "(\(area)) \(middle)-\(last)"
    }
}

enum AccountKeyboardKind {
    case standard
    case email
    case phone

    #if os(iOS)
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .standard:
            return .default
        case .email:
            return .emailAddress
        case .phone:
            return .phonePad
        }
    }
    #endif
}
