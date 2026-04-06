//
//  FriendsPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//
// Friends/groups overview page with search, filter, and summary information.
//

import SwiftUI

struct FriendsPageView: View {
    @Binding var selectedSection: FriendsSection
    let friendsData: [BalanceItem]
    let groupsData: [BalanceItem]
    let headerTitle: String
    @Binding var selectedFilter: BalanceFilter
    let totalYouOwe: Double
    let totalYouAreOwed: Double
    let onSelectItem: (BalanceItem) -> Void
    let onSettleUpTap: () -> Void
    @Binding var showThemeMenu: Bool

    @State private var showFilterSheet = false
    @State private var searchText = ""

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 126) {
            CurvedAppHeader(
                title: "Friends",
                subtitle: "Track friends and groups",
                height: 126
            ) {
                Button {
                    onSettleUpTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 42, height: 42)

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
            }
        } content: {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, 16)

                summaryCard
                    .padding(.top, 12)

                VStack(spacing: 12) {
                    ForEach(filteredCurrentItems) { item in
                        Button {
                            onSelectItem(item)
                        } label: {
                            BalanceRow(item: item)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 180)
                }
                .padding(.top, 12)
                .padding(.horizontal, 14)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSection)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterPageView(selectedFilter: $selectedFilter)
        }
        .onChange(of: selectedSection) { _, _ in
            searchText = ""
        }
    }

    private var currentItems: [BalanceItem] {
        selectedSection == .friends ? friendsData : groupsData
    }

    private var filteredCurrentItems: [BalanceItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return currentItems }
        return currentItems.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var searchPlaceholder: String {
        selectedSection == .friends ? "Search friends" : "Search groups"
    }

    private var overallTitle: String {
        let net = totalYouAreOwed - totalYouOwe

        if net > 0 {
            return "You are owed $\(formattedAmount(net))"
        } else if net < 0 {
            return "You owe $\(formattedAmount(abs(net)))"
        } else {
            return "You are settled up"
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppPalette.secondaryText)

            TextField(searchPlaceholder, text: $searchText)
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.searchField)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text(overallTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(selectedFilter.tintColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 14)

            HStack(spacing: 10) {
                balancePill(
                    text: "Owe $\(formattedAmount(totalYouOwe))",
                    bg: Color.red.opacity(0.10),
                    textColor: .red.opacity(0.88),
                    icon: "arrow.down.right"
                )

                balancePill(
                    text: "Owed $\(formattedAmount(totalYouAreOwed))",
                    bg: Color.green.opacity(0.12),
                    textColor: .green.opacity(0.88),
                    icon: "arrow.up.right"
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                sectionButton(title: "Friends", type: .friends)
                sectionButton(title: "Groups", type: .groups)
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
    }

    private func sectionButton(title: String, type: FriendsSection) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedSection = type
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selectedSection == type ? AppPalette.accentMid : AppPalette.secondaryText)
                    .scaleEffect(selectedSection == type ? 1.03 : 1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                ZStack {
                    Capsule()
                        .fill(Color.clear)
                        .frame(height: 4)

                    if selectedSection == type {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 4)
                            .matchedGeometryEffect(id: "friends_section_indicator", in: friendsSectionNamespace)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @Namespace private var friendsSectionNamespace

    private func balancePill(
        text: String,
        bg: Color,
        textColor: Color,
        icon: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))

            Text(text)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(bg)
        )
    }
}
