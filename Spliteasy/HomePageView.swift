import SwiftUI

struct HomePageView: View {
    let friendsData: [BalanceItem]
    let headerTitle: String
    @Binding var selectedFilter: BalanceFilter
    let monthlyLimit: Double
    let monthlySpent: Double
    let onSelectItem: (BalanceItem) -> Void
    let onSettleUpTap: () -> Void
    @Binding var showThemeMenu: Bool
    let onSaveMonthlyLimit: (Double) -> Void

    @State private var showFilterSheet = false
    @State private var showMonthlyLimitSheet = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView(title: headerTitle)

            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            monthlyLimitCard
                .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(filteredSearchFriends) { item in
                        Button {
                            onSelectItem(item)
                        } label: {
                            HomeBalanceRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 180)
                }
                .padding(.top, 12)
                .padding(.horizontal, 14)
            }
        }
        .background(
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
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

    private func headerView(title: String) -> some View {
        HStack {
            ThemeHeaderButton(showThemeMenu: $showThemeMenu)

            Spacer()

            Button {
                onSettleUpTap()
            } label: {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [AppPalette.accentStart, AppPalette.accentEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 5)
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
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppPalette.searchField)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
        )
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
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppPalette.accentMid)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(selectedFilter.tintColor)
                            .frame(width: 44, height: 44)
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
                        .frame(height: 16)

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
                                width: monthlyLimit > 0 ? max(16, geo.size.width * progressValue) : 0,
                                height: 16
                            )
                    }
                    .frame(height: 16)
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
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
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
                        Text("Clear Limit")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppPalette.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(AppPalette.card)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
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
                                LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .onAppear {
                amountText = currentLimit > 0 ? String(format: "%.2f", currentLimit) : ""
            }
        }
    }

    @ViewBuilder
    private var amountField: some View {
        #if os(iOS)
        TextField("Enter monthly limit", text: $amountText)
            .keyboardType(.decimalPad)
        #else
        TextField("Enter monthly limit", text: $amountText)
        #endif
    }
}


