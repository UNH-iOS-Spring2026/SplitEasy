//
// Detail page for one friend. From here the user can refresh,
// settle up, block/unblock, or delete the friend.
//
//
//  FriendDetailPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//

import SwiftUI

struct FriendDetailPageView: View {
    let friend: BalanceItem
    @Binding var selectedTab: Tab
    @Binding var showFriendDetailPage: Bool
    let onAddExpense: (BalanceItem) -> Void
    let onSettleUp: (BalanceItem) -> Void
    let onRefresh: (() -> Void)?
    let onToggleBlock: (BalanceItem) -> Void
    let onRemoveFriend: (BalanceItem) -> Void
    let onUpdateExpense: (ExpenseEntry, String, Double, GroupExpenseDraft?) -> Void
    let onDeleteExpense: (ExpenseEntry) -> Void

    @State private var isRefreshing = false
    @State private var showBlockConfirm = false
    @State private var showRemoveConfirm = false
    @State private var selectedExpense: ExpenseEntry?

    private let themePurple = AppPalette.accentMid

    init(
        friend: BalanceItem,
        selectedTab: Binding<Tab>,
        showFriendDetailPage: Binding<Bool>,
        onAddExpense: @escaping (BalanceItem) -> Void,
        onSettleUp: @escaping (BalanceItem) -> Void,
        onRefresh: (() -> Void)? = nil,
        onToggleBlock: @escaping (BalanceItem) -> Void,
        onRemoveFriend: @escaping (BalanceItem) -> Void,
        onUpdateExpense: @escaping (ExpenseEntry, String, Double, GroupExpenseDraft?) -> Void,
        onDeleteExpense: @escaping (ExpenseEntry) -> Void
    ) {
        self.friend = friend
        self._selectedTab = selectedTab
        self._showFriendDetailPage = showFriendDetailPage
        self.onAddExpense = onAddExpense
        self.onSettleUp = onSettleUp
        self.onRefresh = onRefresh
        self.onToggleBlock = onToggleBlock
        self.onRemoveFriend = onRemoveFriend
        self.onUpdateExpense = onUpdateExpense
        self.onDeleteExpense = onDeleteExpense
    }

    var body: some View {
        FixedHeaderScrollContainer(
            headerHeight: 118,
            onRefresh: {
                await refreshData()
            }
        ) {
            CurvedBackHeader(
                title: "Friend Details",
                subtitle: friend.name,
                height: 118,
                backAction: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFriendDetailPage = false
                        selectedTab = .friends
                    }
                }
            ) {
                Button {
                    Task {
                        await refreshData()
                    }
                } label: {
                    HeaderCircleButton(systemName: "arrow.clockwise", isLoading: isRefreshing)
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                friendNameCard
                actionCards
                recentTransactionsSection
                managementSection
                Spacer(minLength: 140)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .safeAreaInset(edge: .bottom) {
            addExpenseButton
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 18)
                .background(Color.clear)
        }
        .sheet(item: $selectedExpense) { expense in
            EditExpensePageView(
                parentName: friend.name,
                expense: expense,
                onSave: { newDescription, newAmount, groupDraft in
                    onUpdateExpense(expense, newDescription, newAmount, groupDraft)
                },
                onDelete: {
                    onDeleteExpense(expense)
                }
            )
        }
        .confirmationDialog(
            friend.isBlocked ? "Unblock User" : "Block User",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button(friend.isBlocked ? "Unblock User" : "Block User") {
                onToggleBlock(friend)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text(
                friend.isBlocked
                ? "This user will be able to add expenses again after unblocking."
                : "After blocking, no new expenses can be added for this friend until you unblock them."
            )
        }
        .confirmationDialog(
            "Remove Friend",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Friend", role: .destructive) {
                onRemoveFriend(friend)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove this friend from your app and database. You can add them again later if needed.")
        }
    }

    private var recentTransactions: [ExpenseEntry] {
        friend.expenses.filter { $0.dateText != "Contact" }
    }

    private var friendNameCard: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(themePurple.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Text(String(friend.name.prefix(1)))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(themePurple)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(friend.isBlocked ? "Blocked Friend" : "Friend")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)

                Text(friend.name)
                    .font(.system(size: 28, weight: .bold))
                    .italic()
                    .foregroundColor(AppPalette.primaryText)

                if friend.isBlocked {
                    Text("User is blocked")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.orange.opacity(0.9))
                } else {
                    Text(friend.balanceText)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(friend.direction == .owesYou ? .green.opacity(0.85) : .red.opacity(0.85))
                }
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground)
    }

    private var actionCards: some View {
        HStack(spacing: 14) {
            Button {
                onSettleUp(friend)
            } label: {
                actionCardContent(
                    icon: "arrow.left.arrow.right",
                    title: "Settle up",
                    subtitle: friend.isBlocked ? "Unavailable while blocked" : nil
                )
            }
            .buttonStyle(.plain)
            .disabled(friend.isBlocked)
            .opacity(friend.isBlocked ? 0.55 : 1)

            Button {
                Task {
                    await refreshData()
                }
            } label: {
                actionCardContent(
                    icon: "arrow.clockwise",
                    title: "Refresh",
                    subtitle: nil
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func actionCardContent(icon: String, title: String, subtitle: String?) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(themePurple)

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 122)
        .background(cardBackground)
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Transactions")
                .font(.system(size: 22, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            if recentTransactions.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("No transactions yet")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text("Expenses with this friend will appear here.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(cardBackground(cornerRadius: 24))
            } else {
                VStack(spacing: 12) {
                    ForEach(recentTransactions) { expense in
                        Button {
                            selectedExpense = expense
                        } label: {
                            transactionRow(expense)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func transactionRow(_ expense: ExpenseEntry) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(themePurple.opacity(0.10))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: expense.receiptURL.isEmpty ? "receipt" : "photo")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themePurple)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.description)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text(expense.dateText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("$\(String(format: "%.2f", expense.amount))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppPalette.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackground(cornerRadius: 22))
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manage Friend")
                .font(.system(size: 22, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            Button {
                showBlockConfirm = true
            } label: {
                managementRow(
                    icon: "hand.raised.fill",
                    iconColor: .orange.opacity(0.9),
                    iconBackground: Color.orange.opacity(0.12),
                    title: friend.isBlocked ? "Unblock User" : "Block User",
                    subtitle: friend.isBlocked ? "Allow future expenses again" : "Stop future expenses until unblocked"
                )
            }
            .buttonStyle(.plain)

            Button {
                showRemoveConfirm = true
            } label: {
                managementRow(
                    icon: "person.crop.circle.badge.xmark",
                    iconColor: .red.opacity(0.92),
                    iconBackground: Color.red.opacity(0.12),
                    title: "Remove Friend",
                    subtitle: "Delete this friend from app and database"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func managementRow(icon: String, iconColor: Color, iconBackground: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(iconBackground)
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(iconColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppPalette.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(cardBackground(cornerRadius: 22))
    }

    private var addExpenseButton: some View {
        Button {
            onAddExpense(friend)
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
        .disabled(friend.isBlocked)
        .opacity(friend.isBlocked ? 0.55 : 1)
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
        try? await Task.sleep(nanoseconds: 650_000_000)
        isRefreshing = false
    }
}
