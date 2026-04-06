//
//  GroupDetailPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 4/1/26.
//

import SwiftUI

struct GroupDetailPageView: View {
    let group: BalanceItem
    @Binding var selectedTab: Tab
    @Binding var showGroupDetailPage: Bool
    let onAddExpense: (BalanceItem) -> Void
    let onRefresh: (() -> Void)?

    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        groupSummaryCard
                        recentTransactionsSection

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 110)
                }
                .refreshable {
                    await refreshData()
                }
            }

            VStack {
                Spacer()

                addExpenseButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showGroupDetailPage = false
                    selectedTab = .friends
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.card)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Group Details")
                .font(.system(size: 24, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            Spacer()

            Button {
                Task {
                    await refreshData()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppPalette.card)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                    if isRefreshing {
                        ProgressView()
                            .tint(AppPalette.accentMid)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppPalette.accentMid)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)
        }
    }

    private var groupSummaryCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(avatarColor.opacity(0.18))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String(group.name.prefix(1)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(avatarColor)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("Group")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)

                Text(group.name)
                    .font(.system(size: 28, weight: .bold))
                    .italic()
                    .foregroundColor(AppPalette.primaryText)

                Text("\(group.participantCount) members")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppPalette.secondaryText)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground)
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Transactions")
                .font(.system(size: 22, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            if group.expenses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("No transactions yet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text("Add an expense for this group to see it here.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(cardBackground(cornerRadius: 24))
            } else {
                VStack(spacing: 12) {
                    ForEach(group.expenses) { expense in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(AppPalette.rowIconBg)
                                .frame(width: 48, height: 48)
                                .overlay(
                                    Image(systemName: "receipt")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(AppPalette.accentMid)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text(expense.description)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(AppPalette.primaryText)
                                    .lineLimit(1)

                                Text(expense.dateText)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppPalette.secondaryText)
                            }

                            Spacer()

                            Text("$\(String(format: "%.2f", expense.amount))")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppPalette.primaryText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(cardBackground(cornerRadius: 22))
                    }
                }
            }
        }
    }

    private var addExpenseButton: some View {
        Button {
            onAddExpense(group)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))

                Text("Add Expense")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: AppPalette.accentMid.opacity(0.20), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var avatarColor: Color {
        let colors: [Color] = [AppPalette.accentMid, AppPalette.accentStart, .green, .pink]
        return colors[abs(group.name.hashValue) % colors.count]
    }

    private var cardBackground: some View {
        cardBackground(cornerRadius: 24)
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 5)
    }

    private func refreshData() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        onRefresh?()

        try? await Task.sleep(nanoseconds: 600_000_000)
        isRefreshing = false
    }
}
