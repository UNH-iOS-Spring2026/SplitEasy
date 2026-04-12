import SwiftUI

struct AddFriendPageView: View {
    @Binding var selectedTab: Tab
    @Binding var showAddFriendPage: Bool
    let onSaveFriend: (String, String) -> Void

    @State private var friendName: String = ""
    @State private var contactText: String = ""
    @State private var errorMessage: String = ""

    @FocusState private var focusedField: Field?

    enum Field {
        case name, contact
    }

    private let cardBorder = AppPalette.border
    private let cardShadow = Color.black.opacity(0.08)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppPalette.backgroundTop,
                    AppPalette.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection
                        .padding(.top, 8)

                    friendNameCard
                    contactCard

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 5)
                    }

                    saveFriendButton

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .onTapGesture {
            focusedField = nil // dismiss keyboard
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAddFriendPage = false
                    selectedTab = .friends
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppPalette.card)
                        .frame(width: 46, height: 46)
                        .shadow(color: cardShadow, radius: 8, x: 0, y: 4)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Add Friend")
                .font(.system(size: 24, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            Spacer()

            Button {
                saveFriend()
            } label: {
                Text("Save")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [
                                AppPalette.accentStart,
                                AppPalette.accentEnd
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
                    .opacity(isFormValid ? 1.0 : 0.5)
            }
            .disabled(!isFormValid)
        }
    }

    // MARK: - Name Card
    private var friendNameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friend Name")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            TextField("Enter friend name", text: $friendName)
                .focused($focusedField, equals: .name)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
        .padding(18)
        .background(cardBackground)
    }

    // MARK: - Contact Card
    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phone or Email")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            TextField("Enter phone or email", text: $contactText)
                .focused($focusedField, equals: .contact)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)

            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
        .padding(18)
        .background(cardBackground)
    }

    // MARK: - Save Button
    private var saveFriendButton: some View {
        Button {
            saveFriend()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                Text("Save Friend")
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        AppPalette.accentStart,
                        AppPalette.accentEnd
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
            .opacity(isFormValid ? 1.0 : 0.5)
        }
        .disabled(!isFormValid)
    }

    // MARK: - Helpers
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: cardShadow, radius: 8, x: 0, y: 5)
    }

    private var trimmedName: String {
        friendName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedContact: String {
        contactText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFormValid: Bool {
        !trimmedName.isEmpty && isValidContact(trimmedContact)
    }

    private func isValidContact(_ text: String) -> Bool {
        return isValidEmail(text) || isValidPhone(text)
    }

    private func isValidEmail(_ text: String) -> Bool {
        text.contains("@") && text.contains(".")
    }

    private func isValidPhone(_ text: String) -> Bool {
        let digits = text.filter { $0.isNumber }
        return digits.count >= 7
    }

    private func saveFriend() {
        guard !trimmedName.isEmpty else {
            errorMessage = "Name cannot be empty"
            return
        }

        guard isValidContact(trimmedContact) else {
            errorMessage = "Enter a valid phone or email"
            return
        }

        errorMessage = ""

        onSaveFriend(trimmedName, trimmedContact)
    }
}
