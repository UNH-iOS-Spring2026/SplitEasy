import SwiftUI

struct AddFriendPageView: View {
    @Binding var selectedTab: Tab
    @Binding var showAddFriendPage: Bool
    let onSaveFriend: (String, String) -> Void

    @State private var friendName: String = ""
    @State private var contactText: String = ""

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
                    saveFriendButton

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAddFriendPage = false
                    selectedTab = .friends
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.card)
                        .frame(width: 46, height: 46)
                        .shadow(color: cardShadow, radius: 8, x: 0, y: 4)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                }
            }
            .buttonStyle(.plain)
            .padding(.top, -60)

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
                    .opacity(trimmedName.isEmpty ? 0.65 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(trimmedName.isEmpty)
            .padding(.top, -60)
        }
    }

    private var friendNameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friend Name")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            TextField("Enter friend name", text: $friendName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .shadow(color: cardShadow, radius: 8, x: 0, y: 5)
        )
    }

    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Phone or Email")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            TextField("Enter phone number or email", text: $contactText)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)

            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(cardBorder, lineWidth: 1)
                )
                .shadow(color: cardShadow, radius: 8, x: 0, y: 5)
        )
    }

    private var saveFriendButton: some View {
        Button {
            saveFriend()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 18, weight: .bold))

                Text("Save Friend")
                    .font(.system(size: 18, weight: .bold))
            }
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
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
            .opacity(trimmedName.isEmpty ? 0.65 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(trimmedName.isEmpty)
    }

    private var trimmedName: String {
        friendName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveFriend() {
        guard !trimmedName.isEmpty else { return }

        onSaveFriend(
            trimmedName,
            contactText.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
