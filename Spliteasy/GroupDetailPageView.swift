//
//  GroupDetailPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 4/1/26.
//

import SwiftUI

struct GroupDetailPageView: View {
    let group: BalanceItem
    let memberBalances: [BalanceItem]
    @Binding var selectedTab: Tab
    @Binding var showGroupDetailPage: Bool
    let onAddExpense: (BalanceItem) -> Void
    let onSelectMemberForSettlement: (BalanceItem) -> Void
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
                        balanceCard
                        membersSection

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
                        showGroupDetailPage = false
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

                Text("Group Details")
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

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Group Balance")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(groupBalanceText)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(group.direction == .owesYou ? .green.opacity(0.88) : .red.opacity(0.88))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group Members")
                .font(.system(size: 22, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)

            if memberBalances.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text("No member balances found")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text("Member balances will appear here when group members match your friends list.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(cardBackground(cornerRadius: 24))
            } else {
                VStack(spacing: 12) {
                    ForEach(memberBalances) { member in
                        Button {
                            onSelectMemberForSettlement(member)
                        } label: {
                            memberRow(member)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func memberRow(_ member: BalanceItem) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(avatarColorForMember(member.name).opacity(0.18))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(member.name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(avatarColorForMember(member.name))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text(member.balanceText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(member.direction == .owesYou ? .green.opacity(0.88) : .red.opacity(0.88))
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

    private var groupBalanceText: String {
        let value = String(format: "%.2f", group.amount)
        return group.direction == .owesYou ? "Group owes you $\(value)" : "You owe $\(value)"
    }

    private var avatarColor: Color {
        let colors: [Color] = [AppPalette.accentMid, AppPalette.accentStart, .green, .pink]
        return colors[abs(group.name.hashValue) % colors.count]
    }

    private func avatarColorForMember(_ member: String) -> Color {
        let colors: [Color] = [AppPalette.accentMid, AppPalette.accentStart, .green, .pink]
        return colors[abs(member.hashValue) % colors.count]
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
