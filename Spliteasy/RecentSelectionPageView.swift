//
// Selection screen that shows recent friends and recent groups
// before opening the add expense page.
//
//
//  RecentSelectionPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/19/26.
//

import SwiftUI

struct RecentSelectionPageView: View {
    let recentFriends: [BalanceItem]
    let recentGroups: [BalanceItem]
    let onSelectItem: (BalanceItem) -> Void
    @Binding var selectedTab: Tab
    @Binding var showExpenseSelectionPage: Bool

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Add Expense",
                subtitle: "Choose friend or group",
                height: 118,
                backAction: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showExpenseSelectionPage = false
                        selectedTab = .home
                    }
                }
            ) {
                HeaderEmptySlot()
            }
        } content: {
            VStack(alignment: .leading, spacing: 24) {
                recentSection(title: "Recent Friends", items: recentFriends)
                recentSection(title: "Recent Groups", items: recentGroups)
                Spacer(minLength: 160)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
        }
    }

    private func recentSection(title: String, items: [BalanceItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 4)

            if items.isEmpty {
                emptySectionCard(title: title)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        Button {
                            onSelectItem(item)
                        } label: {
                            recentRow(item: item)
                        }
                        .buttonStyle(.plain)

                        if item.id != items.last?.id {
                            Divider()
                                .opacity(0.18)
                                .padding(.leading, 64)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(AppPalette.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                )
            }
        }
    }

    private func recentRow(item: BalanceItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(avatarColor(for: item).opacity(0.22))
                .frame(width: 46, height: 46)
                .overlay(
                    Text(String(item.name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(avatarColor(for: item))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)
                    .lineLimit(1)

                Text(item.kind == .friend ? "Friend" : "Group")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppPalette.secondaryText.opacity(0.7))
        }
        .padding(.vertical, 12)
    }

    private func emptySectionCard(title: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text("No items in \(title)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Text("They will appear here after you create them.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppPalette.secondaryText)
                .multilineTextAlignment(.center)
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
