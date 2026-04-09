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
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [AppPalette.accentStart, AppPalette.accentEnd],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 10, x: 0, y: 5)

            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showFriendDetailPage = false
                        selectedTab = .friends
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )

                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Friend Details")
                    .font(.system(size: 24, weight: .bold))
                    .italic()
                    .foregroundColor(.white)

                Spacer()

                Button {
                    Task {
                        await refreshData()
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 46, height: 46)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
                            )

                        if isRefreshing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(isRefreshing)
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 96)
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
                            Text("Remove Friend")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(AppPalette.primaryText)

                            Text("Delete this friend from app and database")
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
