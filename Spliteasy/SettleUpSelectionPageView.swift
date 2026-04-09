//
// Lets the user choose which friend they want to settle up with.
//
//
//  SettleUpSelectionPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//

import SwiftUI

struct SettleUpSelectionPageView: View {
    let friends: [BalanceItem]
    @Binding var selectedTab: Tab
    @Binding var showSettleUpSelectionPage: Bool
    let onSelectFriend: (BalanceItem) -> Void

    @State private var searchText = ""

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Select Friend",
                subtitle: "Choose who you want to settle with",
                height: 118,
                backAction: {
                    showSettleUpSelectionPage = false
                    selectedTab = .home
                }
            ) {
                HeaderEmptySlot()
            }
        } content: {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                VStack(spacing: 12) {
                    if filteredFriends.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(filteredFriends) { friend in
                            Button {
                                onSelectFriend(friend)
                            } label: {
                                friendRow(friend)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
            }
        }
        
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppPalette.secondaryText)

            TextField("Search friends", text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppPalette.primaryText)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
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
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var filteredFriends: [BalanceItem] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return friends }
        return friends.filter { $0.name.localizedCaseInsensitiveContains(text) }
    }

    private func friendRow(_ friend: BalanceItem) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(avatarColor(for: friend).opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(friend.name.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(avatarColor(for: friend))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text(friend.balanceText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(friend.direction == .owesYou ? .green.opacity(0.85) : .red.opacity(0.85))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppPalette.secondaryText.opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)
        )
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.exclam")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text("No friends found")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Text("Try a different search.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppPalette.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)
        )
    }

    private func avatarColor(for item: BalanceItem) -> Color {
        let colors: [Color] = [AppPalette.accentMid, AppPalette.accentStart, .green, .pink]
        return colors[abs(item.name.hashValue) % colors.count]
    }
}
