//
//  CreateGroupPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//
// Used to create a group, choose members, and select group type.
//

import SwiftUI

struct CreateGroupPageView: View {
    @Binding var selectedTab: Tab
    @Binding var showCreateGroupPage: Bool
    let availableFriends: [BalanceItem]
    let onSaveGroup: (String, GroupType, [BalanceItem]) -> Void

    @State private var groupName: String = ""
    @State private var selectedGroupType: GroupType = .trip
    @State private var showFriendsList = false
    @State private var selectedFriendIDs: Set<String> = []
    @State private var memberSearchText: String = ""

    private let cardBorder = AppPalette.border
    private let cardShadow = Color.black.opacity(0.08)
    private let iconTint = AppPalette.accentMid

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Create Group",
                subtitle: "Split with multiple people",
                height: 118,
                backAction: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showCreateGroupPage = false
                        selectedTab = .friends
                    }
                }
            ) {
                HeaderEmptySlot()
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                groupNameCard
                addMemberCard

                if showFriendsList {
                    friendsSelectionCard
                }

                groupTypeSection
                saveGroupButton
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }

    private var groupNameCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Group Name")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            TextField("Enter group name", text: $groupName)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Rectangle()
                .fill(AppPalette.border)
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(cardBackground(cornerRadius: 22))
    }

    private var addMemberCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showFriendsList.toggle()
                if !showFriendsList {
                    memberSearchText = ""
                }
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(iconTint)
                    .frame(width: 34)

                Text("Add member")
                    .font(.system(size: 20, weight: .bold))
                    .italic()
                    .foregroundColor(AppPalette.primaryText)

                Spacer()

                Text("\(selectedFriendIDs.count)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(iconTint))

                Image(systemName: showFriendsList ? "chevron.up" : "chevron.down")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.secondaryText)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(cardBackground(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var friendsSelectionCard: some View {
        VStack(spacing: 0) {
            memberSearchBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            if filteredFriends.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("No friends found")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else {
                ForEach(filteredFriends) { friend in
                    Button {
                        toggleFriend(friend.id)
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(avatarColor(for: friend).opacity(0.22))
                                .frame(width: 46, height: 46)
                                .overlay(
                                    Text(String(friend.name.prefix(1)))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(avatarColor(for: friend))
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.name)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppPalette.primaryText)

                                Text("Friend")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppPalette.secondaryText)
                            }

                            Spacer()

                            Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(selectedFriendIDs.contains(friend.id) ? iconTint : AppPalette.secondaryText.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if friend.id != filteredFriends.last?.id {
                        Divider()
                            .opacity(0.18)
                            .padding(.leading, 74)
                    }
                }
            }
        }
        .background(cardBackground(cornerRadius: 24))
    }

    private var memberSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppPalette.secondaryText)

            TextField("Search friends", text: $memberSearchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppPalette.primaryText)

            if !memberSearchText.isEmpty {
                Button {
                    memberSearchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppPalette.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppPalette.searchField)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
        )
    }

    private var groupTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group Type")
                .font(.system(size: 20, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            HStack(spacing: 12) {
                ForEach(GroupType.allCases, id: \.self) { type in
                    Button {
                        selectedGroupType = type
                    } label: {
                        VStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(selectedGroupType == type ? .white : iconTint)

                            Text(type.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedGroupType == type ? .white : AppPalette.primaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 82)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(selectedGroupType == type ? AppPalette.accentMid : AppPalette.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(cardBorder, lineWidth: 1)
                                )
                                .shadow(color: cardShadow, radius: 8, x: 0, y: 5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var saveGroupButton: some View {
        Button {
            saveGroup()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 18, weight: .bold))

                Text("Save Group")
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
            .opacity(canSaveGroup ? 1.0 : 0.65)
        }
        .buttonStyle(.plain)
        .disabled(!canSaveGroup)
    }

    private var trimmedGroupName: String {
        groupName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredFriends: [BalanceItem] {
        let trimmed = memberSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return availableFriends }
        return availableFriends.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var selectedFriends: [BalanceItem] {
        availableFriends.filter { selectedFriendIDs.contains($0.id) }
    }

    private var canSaveGroup: Bool {
        !trimmedGroupName.isEmpty && !selectedFriends.isEmpty
    }

    private func toggleFriend(_ id: String) {
        if selectedFriendIDs.contains(id) {
            selectedFriendIDs.remove(id)
        } else {
            selectedFriendIDs.insert(id)
        }
    }

    private func saveGroup() {
        guard canSaveGroup else { return }

        onSaveGroup(trimmedGroupName, selectedGroupType, selectedFriends)

        groupName = ""
        selectedGroupType = .trip
        selectedFriendIDs = []
        memberSearchText = ""
        showFriendsList = false
        showCreateGroupPage = false
        selectedTab = .friends
    }

    private func avatarColor(for item: BalanceItem) -> Color {
        let colors: [Color] = [AppPalette.accentMid, AppPalette.accentStart, .green, .pink]
        return colors[abs(item.name.hashValue) % colors.count]
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(cardBorder, lineWidth: 1)
            )
            .shadow(color: cardShadow, radius: 8, x: 0, y: 5)
    }
}

enum GroupType: String, CaseIterable, Hashable {
    case trip
    case home
    case couple
    case other

    var title: String {
        switch self {
        case .trip:
            return "Trip"
        case .home:
            return "Home"
        case .couple:
            return "Couple"
        case .other:
            return "Other"
        }
    }

    var icon: String {
        switch self {
        case .trip:
            return "airplane"
        case .home:
            return "house.fill"
        case .couple:
            return "heart.fill"
        case .other:
            return "person.3.fill"
        }
    }

    var firestoreValue: String {
        rawValue
    }
}
