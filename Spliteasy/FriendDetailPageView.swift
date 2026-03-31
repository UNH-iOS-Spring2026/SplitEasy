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

    @State private var isImagePreviewPresented = false
    @State private var previewReceiptURL: String = ""
    @State private var isRefreshing = false
    @State private var showBlockConfirm = false
    @State private var showRemoveConfirm = false

    private let themePurple = AppPalette.accentMid

    init(
        friend: BalanceItem,
        selectedTab: Binding<Tab>,
        showFriendDetailPage: Binding<Bool>,
        onAddExpense: @escaping (BalanceItem) -> Void,
        onSettleUp: @escaping (BalanceItem) -> Void,
        onRefresh: (() -> Void)? = nil,
        onToggleBlock: @escaping (BalanceItem) -> Void,
        onRemoveFriend: @escaping (BalanceItem) -> Void
    ) {
        self.friend = friend
        self._selectedTab = selectedTab
        self._showFriendDetailPage = showFriendDetailPage
        self.onAddExpense = onAddExpense
        self.onSettleUp = onSettleUp
        self.onRefresh = onRefresh
        self.onToggleBlock = onToggleBlock
        self.onRemoveFriend = onRemoveFriend
    }

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
                        friendNameCard
                        actionCards
                        recentExpensesSection
                        managementSection

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
        .sheet(isPresented: $isImagePreviewPresented) {
            receiptPreviewSheet
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

    private var headerView: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showFriendDetailPage = false
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
            .padding(.top, -65)

            Spacer()

            Text("Friend Details")
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
            .padding(.top, -65)
        }
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
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 108)
        .background(cardBackground(cornerRadius: 22))
    }

    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Expenses")
                    .font(.system(size: 22, weight: .bold))
                    .italic()
                    .foregroundColor(AppPalette.primaryText)

                Spacer()

                if !visibleExpenses.isEmpty {
                    Text("\(visibleExpenses.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppPalette.accentMid)
                        )
                }
            }

            if visibleExpenses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText.opacity(0.7))

                    Text("No expenses yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("Add an expense and it will appear here even after relaunch.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(cardBackground(cornerRadius: 22))
            } else {
                VStack(spacing: 14) {
                    ForEach(visibleExpenses) { expense in
                        expenseCard(expense)
                    }
                }
            }
        }
    }

    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manage Friend")
                .font(.system(size: 22, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            VStack(spacing: 12) {
                Button {
                    showBlockConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.orange.opacity(0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: friend.isBlocked ? "lock.open.fill" : "hand.raised.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange.opacity(0.9))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.isBlocked ? "Unblock User" : "Block User")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppPalette.primaryText)

                            Text(
                                friend.isBlocked
                                ? "Allow expenses again"
                                : "Stop future expenses until unblocked"
                            )
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
                .buttonStyle(.plain)

                Button {
                    showRemoveConfirm = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                                .frame(width: 50, height: 50)

                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.red.opacity(0.9))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete Friend")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppPalette.primaryText)

                            Text("Remove from app and database")
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
                .buttonStyle(.plain)
            }
        }
    }

    private func expenseCard(_ expense: ExpenseEntry) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Circle()
                    .fill(themePurple.opacity(0.12))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: expense.receiptURL.isEmpty ? "receipt" : "photo.on.rectangle")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(themePurple)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.description)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

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
            .padding(.top, 14)
            .padding(.bottom, expense.receiptURL.isEmpty ? 14 : 10)

            if !expense.receiptURL.isEmpty,
               let url = URL(string: expense.receiptURL) {
                Button {
                    previewReceiptURL = expense.receiptURL
                    isImagePreviewPresented = true
                } label: {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppPalette.searchField)
                                ProgressView()
                            }
                            .frame(height: 170)

                        case .success(let image):
                            ZStack(alignment: .topTrailing) {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 170)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    .cornerRadius(16)

                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.45))
                                    )
                                    .padding(10)
                            }

                        case .failure:
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(AppPalette.secondaryText)

                                Text("Unable to load receipt")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppPalette.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(AppPalette.searchField)
                            )

                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
                .buttonStyle(.plain)
            }
        }
        .background(cardBackground(cornerRadius: 22))
    }

    private var receiptPreviewSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if let url = URL(string: previewReceiptURL), !previewReceiptURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(AppPalette.accentMid)

                        case .success(let image):
                            ZoomableReceiptImage(image: image)

                        case .failure:
                            VStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.orange)

                                Text("Unable to load receipt")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppPalette.primaryText)
                            }

                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Receipt")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        .presentationDetents([.large])
    }

    private var visibleExpenses: [ExpenseEntry] {
        friend.expenses.filter { $0.dateText != "Contact" }
    }

    private var addExpenseButton: some View {
        Button {
            onAddExpense(friend)
        } label: {
            VStack(spacing: 4) {
                Text(friend.isBlocked ? "User Blocked" : "Add Expense")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                if friend.isBlocked {
                    Text("Unblock user to continue")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: friend.isBlocked
                    ? [Color.gray.opacity(0.8), Color.gray.opacity(0.7)]
                    : [AppPalette.accentStart, AppPalette.accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(friend.isBlocked)
        .opacity(friend.isBlocked ? 0.8 : 1)
    }

    private func cardBackground(cornerRadius: CGFloat = 24) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    private var cardBackground: some View {
        cardBackground(cornerRadius: 24)
    }

    @MainActor
    private func refreshData() async {
        guard let onRefresh else { return }
        isRefreshing = true
        onRefresh()
        try? await Task.sleep(nanoseconds: 700_000_000)
        isRefreshing = false
    }
}

struct ZoomableReceiptImage<Content: View>: View {
    let image: Content
    @State private var scale: CGFloat = 1

    var body: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            image
                .scaledToFit()
                .scaleEffect(scale)
                .animation(.easeInOut(duration: 0.2), value: scale)
                .onTapGesture(count: 2) {
                    withAnimation {
                        scale = scale == 1 ? 2 : 1
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button("Zoom In") {
                    scale = min(scale + 0.5, 4)
                }

                Button("Zoom Out") {
                    scale = max(scale - 0.5, 1)
                }
            }
        }
    }
}
