//
//  AddFriendPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//
// Simple page to save a new friend with name and optional contact detail.
//

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
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Add Friend",
                subtitle: "Create a new connection",
                height: 118,
                backAction: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAddFriendPage = false
                        selectedTab = .friends
                    }
                }
            ) {
                HeaderEmptySlot()
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                friendNameCard
                contactCard
                saveFriendButton
                Spacer(minLength: 120)
            }
            .padding(.top, 14)
            .padding(.horizontal, 20)
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
        let name = trimmedName
        guard !name.isEmpty else { return }

        let contact = contactText.trimmingCharacters(in: .whitespacesAndNewlines)
        onSaveFriend(name, contact)

        friendName = ""
        contactText = ""
        showAddFriendPage = false
        selectedTab = .friends
    }
}
