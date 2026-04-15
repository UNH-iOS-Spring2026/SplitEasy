//
//  HomePageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//

import SwiftUI

struct HomePageView: View {
    let friendsData: [BalanceItem]
    let userName: String
    let headerTitle: String
    @Binding var selectedFilter: BalanceFilter
    let monthlyLimit: Double
    let monthlySpent: Double
    let onSelectItem: (BalanceItem) -> Void
    let onSettleUpTap: () -> Void
    @Binding var showThemeMenu: Bool
    let onSaveMonthlyLimit: (Double) -> Void
    let onRefresh: (() async -> Void)?

    @State private var showFilterSheet = false
    @State private var showMonthlyLimitSheet = false
    @State private var goToNotifications = false
    @State private var searchText = ""

    init(
        friendsData: [BalanceItem],
        userName: String,
        headerTitle: String,
        selectedFilter: Binding<BalanceFilter>,
        monthlyLimit: Double,
        monthlySpent: Double,
        onSelectItem: @escaping (BalanceItem) -> Void,
        onSettleUpTap: @escaping () -> Void,
        showThemeMenu: Binding<Bool>,
        onSaveMonthlyLimit: @escaping (Double) -> Void,
        onRefresh: (() async -> Void)? = nil
    ) {
        self.friendsData = friendsData
        self.userName = userName
        self.headerTitle = headerTitle
        self._selectedFilter = selectedFilter
        self.monthlyLimit = monthlyLimit
        self.monthlySpent = monthlySpent
        self.onSelectItem = onSelectItem
        self.onSettleUpTap = onSettleUpTap
        self._showThemeMenu = showThemeMenu
        self.onSaveMonthlyLimit = onSaveMonthlyLimit
        self.onRefresh = onRefresh
    }

    var body: some View {
        NavigationStack {
            FixedHeaderScrollContainer(
                headerHeight: 118,
                onRefresh: onRefresh
            ) {
                CurvedAppHeader(
                    title: welcomeTitle,
                    subtitle: "Track balances and monthly spending",
                    height: 118
                ) {
                    Button {
                        goToNotifications = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.14))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                            
                            Image(systemName: "bell.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.plain)
                }
            } content: {
                VStack(spacing: 0) {
                    searchBar
                        .padding(.top, 8)

                    monthlyLimitCard
                        .padding(.top, 12)

                    balancesSection
                        .padding(.top, 14)
                }
            }
            .navigationDestination(isPresented: $goToNotifications) {
                NotificationPageView()
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterPageView(selectedFilter: $selectedFilter)
            }
            .sheet(isPresented: $showMonthlyLimitSheet) {
                MonthlyLimitSheet(
                    currentLimit: monthlyLimit,
                    onSave: { newLimit in
                        onSaveMonthlyLimit(newLimit)
                        showMonthlyLimitSheet = false
                    }
                )
            }
        }
    }

    private var welcomeTitle: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Welcome" : "Welcome \(trimmed)"
    }

    private var filteredSearchFriends: [BalanceItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return friendsData }
        return friendsData.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }

    private var progressValue: Double {
        guard monthlyLimit > 0 else { return 0 }
        return min(monthlySpent / monthlyLimit, 1.0)
    }

    private var amountLeft: Double {
        max(monthlyLimit - monthlySpent, 0)
    }

    private var progressTint: Color {
        if progressValue >= 1.0 {
            return .red.opacity(0.85)
        } else if progressValue >= 0.75 {
            return .orange.opacity(0.85)
        } else {
            return AppPalette.accentMid
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
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
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppPalette.searchField)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
    }

    private var monthlyLimitCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Limit")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("$\(formattedAmount(monthlyLimit))")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text("Spent $\(formattedAmount(monthlySpent)) this month")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)
                }

                Spacer(minLength: 10)

                VStack(spacing: 10) {
                    Button {
                        showMonthlyLimitSheet = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundColor(AppPalette.accentMid)
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundColor(selectedFilter.tintColor)
                            .frame(width: 42, height: 42)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 14)

                    GeometryReader { geo in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [progressTint.opacity(0.96), progressTint],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: monthlyLimit > 0 ? max(14, geo.size.width * progressValue) : 0,
                                height: 14
                            )
                    }
                    .frame(height: 14)
                }

                HStack {
                    Text(monthlyLimit > 0 ? "\(Int(progressValue * 100))% used" : "Set your limit")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(monthlyLimit > 0 ? progressTint : AppPalette.accentMid)

                    Spacer()

                    if monthlyLimit <= 0 {
                        Text("No limit set")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppPalette.secondaryText)
                    } else if monthlySpent <= monthlyLimit {
                        Text("$\(formattedAmount(amountLeft)) left")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.green.opacity(0.90))
                    } else {
                        Text("Over by $\(formattedAmount(monthlySpent - monthlyLimit))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.red.opacity(0.88))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
    }

    private var balancesSection: some View {
        VStack(spacing: 12) {
            if filteredSearchFriends.isEmpty {
                emptyStateCard
            } else {
                ForEach(filteredSearchFriends) { item in
                    Button {
                        onSelectItem(item)
                    } label: {
                        HomeBalanceRow(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 180)
        }
        .padding(.horizontal, 14)
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
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
}

struct MonthlyLimitSheet: View {
    let currentLimit: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set Monthly Limit")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                amountField
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppPalette.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: 1)
                            )
                    )

                HStack(spacing: 12) {
                    Button {
                        amountText = "0"
                    } label: {
                        Text("Clear")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppPalette.accentMid)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppPalette.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(AppPalette.border, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onSave(Double(amountText) ?? 0)
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("Monthly Limit")
            .onAppear {
                amountText = currentLimit > 0 ? String(format: "%.2f", currentLimit) : ""
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var amountField: some View {
        #if os(iOS)
        TextField("Enter amount", text: $amountText)
            .keyboardType(.decimalPad)
        #else
        TextField("Enter amount", text: $amountText)
        #endif
    }
}

struct NotificationPageView: View {
    @State private var notifications: [AppNotificationItem] = []
    @State private var isLoading = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(AppPalette.accentMid)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if notifications.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(AppPalette.secondaryText)

                                Text("No notifications yet")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppPalette.primaryText)

                                Text("Your recent updates will appear here.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppPalette.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(AppPalette.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .stroke(AppPalette.border, lineWidth: 1)
                                    )
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
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(AppPalette.card)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                                .stroke(AppPalette.border, lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                                )
                            }
                        }
                    }
                    .padding(16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    loadNotifications()
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadNotifications()
        }
    }

    private func loadNotifications() {
        isLoading = true

        FirebaseService.shared.fetchNotifications { result in
            DispatchQueue.main.async {
                isLoading = false

                switch result {
                case .success(let records):
                    notifications = records.map {
                        AppNotificationItem(
                            id: $0.documentId,
                            title: $0.title,
                            message: $0.message,
                            timeText: $0.timeText
                        )
                    }

                case .failure:
                    notifications = []
                }
            }
        }
    }
}
