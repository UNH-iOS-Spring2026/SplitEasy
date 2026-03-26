import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var selectedSection: FriendsSection = .friends
    @State private var showPlusMenu = false
    @State private var selectedFilter: BalanceFilter = .none
    @State private var showExpenseSelectionPage = false
    @State private var showCreateGroupPage = false
    @State private var showAddFriendPage = false
    @State private var showFriendDetailPage = false
    @State private var showSettleUpSelectionPage = false
    @State private var showSettleUpPage = false
    @State private var settleUpReturnToFriendDetail = false
    @State private var monthlyLimit: Double = 2000.00
    @State private var isLoggedIn = true

    @AppStorage("appThemeMode") private var savedThemeMode: String = AppThemeMode.auto.rawValue
    @State private var showThemeMenu = false

    @State private var profileName: String = "Sidhartha Javvadi"
    @State private var profileEmail: String = "javvadisidhartha9100@gmail.com"
    @State private var profilePhone: String = ""
    @State private var recentNotifications: [AppNotificationItem] = [
        .init(title: "Reminder sent", message: "Your reminder was sent successfully.", timeText: "Today"),
        .init(title: "Expense added", message: "Your latest expense was saved to the activity page.", timeText: "Yesterday"),
        .init(title: "Monthly limit", message: "You have used a good portion of your monthly budget.", timeText: "2d ago")
    ]

    @State private var selectedFriendDetail: BalanceItem?
    @State private var selectedExpenseTarget: BalanceItem?
    @State private var selectedSettleTarget: BalanceItem?

    @State private var friendsData: [BalanceItem] = [
        .init(kind: .friend, name: "Friend -1", amount: 25, direction: .youOwe, participantCount: 2),
        .init(kind: .friend, name: "Friend -2", amount: 12, direction: .owesYou, participantCount: 2),
        .init(kind: .friend, name: "Friend -3", amount: 45, direction: .youOwe, participantCount: 2),
        .init(kind: .friend, name: "Friend -4", amount: 30, direction: .owesYou, participantCount: 2),
        .init(kind: .friend, name: "Friend -5", amount: 50, direction: .youOwe, participantCount: 2)
    ]

    @State private var groupsData: [BalanceItem] = [
        .init(kind: .group, name: "Group -1", amount: 12, direction: .owesYou, participantCount: 3, memberNames: ["Friend -1", "Friend -2"]),
        .init(kind: .group, name: "Group -2", amount: 45, direction: .youOwe, participantCount: 4, memberNames: ["Friend -2", "Friend -3", "Friend -4"]),
        .init(kind: .group, name: "Group -3", amount: 30, direction: .owesYou, participantCount: 5, memberNames: ["Friend -1", "Friend -3", "Friend -4", "Friend -5"]),
        .init(kind: .group, name: "Group -4", amount: 50, direction: .youOwe, participantCount: 3, memberNames: ["Friend -2", "Friend -5"]),
        .init(kind: .group, name: "Group -5", amount: 25, direction: .youOwe, participantCount: 4, memberNames: ["Friend -1", "Friend -4", "Friend -5"])
    ]

    @State private var activityTransactions: [TransactionItem] = [
        .init(title: "Trip to NYC", subtitle: "You paid · 3 people", amount: 4000.00, date: "Mar 16", monthKey: "2026-03", category: "Travel"),
        .init(title: "Walmart", subtitle: "You paid · 3 people", amount: 120.00, date: "Mar 12", monthKey: "2026-03", category: "Shopping"),
        .init(title: "Groceries", subtitle: "Taylor paid · 3 people", amount: 67.30, date: "Mar 11", monthKey: "2026-03", category: "Food"),
        .init(title: "Dinner at Olive Garden", subtitle: "You paid · 4 people", amount: 86.50, date: "Mar 9", monthKey: "2026-03", category: "Food"),
        .init(title: "Uber to Airport", subtitle: "Alex paid · 4 people", amount: 45.00, date: "Mar 8", monthKey: "2026-03", category: "Transport"),
        .init(title: "March Rent", subtitle: "You paid · 3 people", amount: 2400.00, date: "Feb 28", monthKey: "2026-02", category: "Other")
    ]

    var body: some View {
        ZStack(alignment: .leading) {
            if isLoggedIn {
                mainAppView
            } else {
                LoginPageView {
                    isLoggedIn = true
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
    }

    private var mainAppView: some View {
        ZStack(alignment: .leading) {
            ZStack {
                Color.gray.opacity(0.12)
                    .ignoresSafeArea()

                if showPlusMenu &&
                    !showExpenseSelectionPage &&
                    !showCreateGroupPage &&
                    !showAddFriendPage &&
                    !showFriendDetailPage &&
                    !showSettleUpSelectionPage &&
                    !showSettleUpPage &&
                    selectedTab != .friends &&
                    selectedTab != .activity &&
                    selectedTab != .add {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showPlusMenu = false
                            }
                        }
                }

                if showSettleUpPage, let friend = selectedSettleTarget {
                    SettleUpPageView(
                        friend: latestFriendVersion(for: friend),
                        onBack: handleSettleUpBack,
                        onSave: settleUpFriend
                    )
                } else if showSettleUpSelectionPage {
                    SettleUpSelectionPageView(
                        friends: filteredFriends,
                        selectedTab: $selectedTab,
                        showSettleUpSelectionPage: $showSettleUpSelectionPage,
                        onSelectFriend: { friend in
                            selectedSettleTarget = friend
                            showSettleUpSelectionPage = false
                            showSettleUpPage = true
                            settleUpReturnToFriendDetail = false
                        }
                    )
                } else if showFriendDetailPage, let friend = selectedFriendDetail {
                    FriendDetailPageView(
                        friend: latestFriendVersion(for: friend),
                        selectedTab: $selectedTab,
                        showFriendDetailPage: $showFriendDetailPage,
                        onAddExpense: { item in
                            openExpensePage(for: item)
                        },
                        onSettleUp: { item in
                            selectedSettleTarget = item
                            showFriendDetailPage = false
                            showSettleUpPage = true
                            settleUpReturnToFriendDetail = true
                        }
                    )
                } else if showAddFriendPage {
                    AddFriendPageView(
                        selectedTab: $selectedTab,
                        showAddFriendPage: $showAddFriendPage,
                        onSaveFriend: saveNewFriend
                    )
                } else if showCreateGroupPage {
                    CreateGroupPageView(
                        selectedTab: $selectedTab,
                        showCreateGroupPage: $showCreateGroupPage,
                        availableFriends: friendsData,
                        onSaveGroup: saveNewGroup
                    )
                } else if showExpenseSelectionPage {
                    RecentSelectionPageView(
                        recentFriends: recentFriends,
                        recentGroups: recentGroups,
                        onSelectItem: { item in
                            openExpensePage(for: item)
                        },
                        selectedTab: $selectedTab,
                        showExpenseSelectionPage: $showExpenseSelectionPage
                    )
                } else {
                    switch selectedTab {
                    case .home:
                        HomePageView(
                            friendsData: filteredFriends,
                            headerTitle: "Settle Up",
                            selectedFilter: $selectedFilter,
                            monthlyLimit: monthlyLimit,
                            monthlySpent: currentMonthSpent,
                            onSelectItem: { item in
                                openFriendDetailPage(for: item)
                            },
                            onSettleUpTap: {
                                showSettleUpSelectionPage = true
                                selectedTab = .home
                            },
                            showThemeMenu: $showThemeMenu
                        )

                    case .friends:
                        FriendsPageView(
                            selectedSection: $selectedSection,
                            friendsData: filteredFriends,
                            groupsData: filteredGroups,
                            headerTitle: "Settle Up",
                            selectedFilter: $selectedFilter,
                            totalYouOwe: friendsPageTotalYouOwe,
                            totalYouAreOwed: friendsPageTotalYouAreOwed,
                            onSelectItem: { item in
                                if item.kind == .friend {
                                    openFriendDetailPage(for: item)
                                } else {
                                    openExpensePage(for: item)
                                }
                            },
                            onSettleUpTap: {
                                showFriendDetailPage = false
                                showExpenseSelectionPage = false
                                showCreateGroupPage = false
                                showAddFriendPage = false
                                showSettleUpPage = false
                                showSettleUpSelectionPage = true
                                settleUpReturnToFriendDetail = false
                                selectedTab = .friends
                            },
                            showThemeMenu: $showThemeMenu
                        )

                    case .activity:
                        ActivityPageView(
                            transactions: activityTransactions,
                            showThemeMenu: $showThemeMenu
                        )

                    case .profile:
                        AccountPageView(
                            showThemeMenu: $showThemeMenu,
                            profileName: $profileName,
                            profileEmail: $profileEmail,
                            profilePhone: $profilePhone,
                            notifications: recentNotifications,
                            onSaveProfile: saveProfile,
                            onSubmitFeedback: submitFeedback,
                            onContactSupport: contactSupport,
                            onSignOut: signOut
                        )

                    case .add:
                        AddExpensePageView(
                            selectedItem: selectedExpenseTarget,
                            onSaveExpense: saveExpense,
                            selectedTab: $selectedTab
                        )
                    }
                }
            }

            if showThemeMenu {
                ThemeSideMenuView(
                    showThemeMenu: $showThemeMenu,
                    selectedTheme: Binding<AppThemeMode>(
                        get: {
                            AppThemeMode(rawValue: savedThemeMode) ?? .auto
                        },
                        set: { newValue in
                            savedThemeMode = newValue.rawValue
                        }
                    )
                )
                .zIndex(100)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !showCreateGroupPage &&
                !showAddFriendPage &&
                !showFriendDetailPage &&
                !showSettleUpSelectionPage &&
                !showSettleUpPage {
                CustomBottomBar(
                    selectedTab: $selectedTab,
                    selectedSection: selectedSection,
                    showActionButton: selectedTab == .friends && !showExpenseSelectionPage && !showCreateGroupPage && !showAddFriendPage,
                    showPlusMenu: $showPlusMenu,
                    hidePlusButton: selectedTab == .activity || selectedTab == .profile || selectedTab == .add || showExpenseSelectionPage || showCreateGroupPage || showAddFriendPage || showFriendDetailPage || showSettleUpSelectionPage || showSettleUpPage,
                    actionButtonPressed: handleFriendsActionButtonTap,
                    addExpensePressed: handleAddExpense
                )
                .padding(.horizontal, 5)
                .padding(.bottom, -145)
            }
        }
        .onChange(of: selectedTab) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPlusMenu = false
            }

            if selectedTab != .friends {
                showCreateGroupPage = false
                showAddFriendPage = false
                showFriendDetailPage = false
            }

            if selectedTab != .add {
                showExpenseSelectionPage = false
            }

            if selectedTab != .home {
                showSettleUpSelectionPage = false
                showSettleUpPage = false
            }
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch AppThemeMode(rawValue: savedThemeMode) ?? .auto {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            let hour = Calendar.current.component(.hour, from: Date())
            return (hour >= 6 && hour < 18) ? .light : .dark
        }
    }

    private var currentMonthSpent: Double {
        let currentMonthKey = monthKey(for: Date())
        return activityTransactions
            .filter { $0.monthKey == currentMonthKey }
            .reduce(0) { $0 + $1.amount }
    }

    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private var currentFriendsPageItems: [BalanceItem] {
        selectedSection == .friends ? friendsData : groupsData
    }

    private var friendsPageTotalYouOwe: Double {
        currentFriendsPageItems
            .filter { $0.direction == .youOwe }
            .reduce(0) { $0 + $1.amount }
    }

    private var friendsPageTotalYouAreOwed: Double {
        currentFriendsPageItems
            .filter { $0.direction == .owesYou }
            .reduce(0) { $0 + $1.amount }
    }

    private var filteredFriends: [BalanceItem] {
        applyFilter(to: friendsData)
    }

    private var filteredGroups: [BalanceItem] {
        applyFilter(to: groupsData)
    }

    private var recentFriends: [BalanceItem] {
        Array(friendsData.prefix(4))
    }

    private var recentGroups: [BalanceItem] {
        Array(groupsData.prefix(4))
    }

    private func applyFilter(to items: [BalanceItem]) -> [BalanceItem] {
        switch selectedFilter {
        case .none:
            return items
        case .youOwe:
            return items.filter { $0.direction == .youOwe }
        case .owesYou:
            return items.filter { $0.direction == .owesYou }
        }
    }

    private func latestFriendVersion(for friend: BalanceItem) -> BalanceItem {
        friendsData.first(where: { $0.id == friend.id }) ?? friend
    }

    private func openFriendDetailPage(for item: BalanceItem) {
        selectedFriendDetail = item
        showFriendDetailPage = true
        showSettleUpSelectionPage = false
        showSettleUpPage = false
        selectedTab = .friends
        selectedSection = .friends
    }

    private func openExpensePage(for item: BalanceItem) {
        selectedExpenseTarget = item
        showExpenseSelectionPage = false
        showFriendDetailPage = false
        showSettleUpSelectionPage = false
        showSettleUpPage = false
        showCreateGroupPage = false
        showAddFriendPage = false
        selectedTab = .add
        selectedSection = item.kind == .group ? .groups : .friends
    }

    private func handleSettleUpBack() {
        if settleUpReturnToFriendDetail, let friend = selectedSettleTarget {
            selectedFriendDetail = latestFriendVersion(for: friend)
            showSettleUpPage = false
            showFriendDetailPage = true
            selectedTab = .friends
        } else {
            showSettleUpPage = false
            showSettleUpSelectionPage = true
            selectedTab = .home
        }
    }

    private func saveNewFriend(name: String, contact: String) {
        let newFriend = BalanceItem(
            kind: .friend,
            name: name,
            amount: 0,
            direction: .owesYou,
            participantCount: 2,
            expenses: contact.isEmpty ? [] : [
                ExpenseEntry(description: contact, amount: 0, dateText: "Contact")
            ]
        )
        friendsData.insert(newFriend, at: 0)
        selectedSection = .friends
        showAddFriendPage = false
        selectedTab = .friends

        recentNotifications.insert(
            .init(title: "Friend added", message: "\(name) was added successfully.", timeText: "Now"),
            at: 0
        )
    }

    private func saveNewGroup(name: String, type: GroupType, members: [BalanceItem]) {
        let newGroup = BalanceItem(
            kind: .group,
            name: name,
            amount: 0,
            direction: .owesYou,
            participantCount: members.count + 1,
            memberNames: members.map { $0.name },
            expenses: []
        )
        groupsData.insert(newGroup, at: 0)
        selectedSection = .groups
        showCreateGroupPage = false
        selectedTab = .friends

        recentNotifications.insert(
            .init(title: "Group created", message: "\(name) was created successfully.", timeText: "Now"),
            at: 0
        )
    }

    private func signedBalance(for item: BalanceItem) -> Double {
        item.direction == .owesYou ? item.amount : -item.amount
    }

    private func applyNetAmount(_ net: Double, to item: inout BalanceItem) {
        let updated = signedBalance(for: item) + net
        item.amount = abs(updated)
        item.direction = updated >= 0 ? .owesYou : .youOwe
    }

    private func settleUpFriend(itemID: UUID, amount: Double, method: String) {
        guard let index = friendsData.firstIndex(where: { $0.id == itemID }) else { return }

        let currentSigned = signedBalance(for: friendsData[index])
        let updatedSigned = currentSigned > 0 ? currentSigned - amount : currentSigned + amount

        friendsData[index].amount = abs(updatedSigned)
        friendsData[index].direction = updatedSigned >= 0 ? .owesYou : .youOwe
        friendsData[index].expenses.insert(
            ExpenseEntry(
                description: "Settle up via \(method)",
                amount: amount,
                dateText: currentDayText()
            ),
            at: 0
        )

        selectedSettleTarget = friendsData[index]
        selectedFriendDetail = friendsData[index]

        activityTransactions.insert(
            TransactionItem(
                title: "Settle up with \(friendsData[index].name)",
                subtitle: method,
                amount: amount,
                date: currentDayText(),
                monthKey: monthKey(for: Date()),
                category: "Other"
            ),
            at: 0
        )

        recentNotifications.insert(
            .init(title: "Settlement saved", message: "You settled \(friendsData[index].name) via \(method).", timeText: "Now"),
            at: 0
        )

        if settleUpReturnToFriendDetail {
            showSettleUpPage = false
            showFriendDetailPage = true
            selectedTab = .friends
        } else {
            showSettleUpPage = false
            showSettleUpSelectionPage = false
            selectedTab = .home
        }
    }

    private func currentDayText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: Date())
    }

    private func saveExpense(
        itemID: UUID,
        description: String,
        amount: Double,
        direction: BalanceDirection,
        groupDraft: GroupExpenseDraft?
    ) {
        let now = Date()
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MMM d"

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"

        if let friendIndex = friendsData.firstIndex(where: { $0.id == itemID }) {
            let friend = friendsData[friendIndex]
            let newExpense = ExpenseEntry(
                description: description,
                amount: amount,
                dateText: dayFormatter.string(from: now)
            )

            let net = direction == .owesYou ? amount : -amount
            applyNetAmount(net, to: &friendsData[friendIndex])
            friendsData[friendIndex].expenses.insert(newExpense, at: 0)
            selectedExpenseTarget = friendsData[friendIndex]
            selectedFriendDetail = friendsData[friendIndex]

            let transaction = TransactionItem(
                title: description,
                subtitle: direction == .owesYou ? "You paid · \(friend.name)" : "\(friend.name) paid",
                amount: amount,
                date: dayFormatter.string(from: now),
                monthKey: monthFormatter.string(from: now),
                category: inferCategory(from: description)
            )
            activityTransactions.insert(transaction, at: 0)

            recentNotifications.insert(
                .init(title: "Expense added", message: "\(description) was added for \(friend.name).", timeText: "Now"),
                at: 0
            )

            showFriendDetailPage = true
            selectedTab = .friends
            selectedSection = .friends
            return
        }

        if let groupIndex = groupsData.firstIndex(where: { $0.id == itemID }) {
            let newExpense = ExpenseEntry(
                description: description,
                amount: amount,
                dateText: dayFormatter.string(from: now)
            )

            let net = groupDraft?.yourNetAmount ?? (direction == .owesYou ? amount : -amount)
            applyNetAmount(net, to: &groupsData[groupIndex])
            groupsData[groupIndex].expenses.insert(newExpense, at: 0)
            selectedExpenseTarget = groupsData[groupIndex]

            let subtitleText: String
            if let groupDraft {
                let payerDetails = groupDraft.paidBy.map { person in
                    let paid = groupDraft.paidAmounts[person] ?? 0
                    return "\(person) $\(String(format: "%.2f", paid))"
                }.joined(separator: ", ")

                subtitleText = "Paid by \(payerDetails) · split with \(groupDraft.splitWith.count)"
            } else {
                subtitleText = direction == .owesYou
                    ? "You paid · \(groupsData[groupIndex].participantCount) people"
                    : "\(groupsData[groupIndex].participantCount) people paid"
            }

            let transaction = TransactionItem(
                title: description,
                subtitle: subtitleText,
                amount: amount,
                date: dayFormatter.string(from: now),
                monthKey: monthFormatter.string(from: now),
                category: inferCategory(from: description)
            )
            activityTransactions.insert(transaction, at: 0)

            recentNotifications.insert(
                .init(title: "Group expense added", message: "\(description) was added to \(groupsData[groupIndex].name).", timeText: "Now"),
                at: 0
            )

            selectedSection = .groups
            selectedTab = .friends
        }
    }

    private func inferCategory(from description: String) -> String {
        let text = description.lowercased()

        if text.contains("food") || text.contains("dinner") || text.contains("lunch") || text.contains("breakfast") || text.contains("restaurant") || text.contains("grocer") || text.contains("cafe") || text.contains("coffee") {
            return "Food"
        }

        if text.contains("uber") || text.contains("lyft") || text.contains("taxi") || text.contains("bus") || text.contains("train") || text.contains("flight") || text.contains("airport") || text.contains("gas") {
            return "Transport"
        }

        if text.contains("shop") || text.contains("mall") || text.contains("walmart") || text.contains("target") || text.contains("amazon") || text.contains("clothes") {
            return "Shopping"
        }

        if text.contains("trip") || text.contains("hotel") || text.contains("travel") || text.contains("vacation") {
            return "Travel"
        }

        return "Other"
    }

    private func handleFriendsActionButtonTap() {
        if selectedSection == .friends {
            showAddFriendPage = true
        } else {
            showCreateGroupPage = true
        }
    }

    private func handleAddExpense() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showPlusMenu = false
            showCreateGroupPage = false
            showAddFriendPage = false
            showFriendDetailPage = false
            showSettleUpSelectionPage = false
            showSettleUpPage = false
            showExpenseSelectionPage = true
        }
    }

    private func saveProfile(name: String, email: String, phone: String, password: String) {
        profileName = name.isEmpty ? profileName : name
        profileEmail = email.isEmpty ? profileEmail : email
        profilePhone = phone

        recentNotifications.insert(
            .init(
                title: "Profile updated",
                message: password.isEmpty ? "Your profile details were updated." : "Your profile and password were updated.",
                timeText: "Now"
            ),
            at: 0
        )
    }

    private func submitFeedback(rating: Int, message: String) {
        recentNotifications.insert(
            .init(
                title: "Feedback received",
                message: rating > 0 ? "Thanks for rating the app \(rating)/5." : "Thanks for your feedback.",
                timeText: "Now"
            ),
            at: 0
        )
    }

    private func contactSupport(subject: String, message: String) {
        recentNotifications.insert(
            .init(
                title: "Support message sent",
                message: subject.isEmpty ? "Your message was sent to customer service." : "\"\(subject)\" was sent to customer service.",
                timeText: "Now"
            ),
            at: 0
        )
    }

    private func signOut() {
        showThemeMenu = false
        showPlusMenu = false
        showExpenseSelectionPage = false
        showCreateGroupPage = false
        showAddFriendPage = false
        showFriendDetailPage = false
        showSettleUpSelectionPage = false
        showSettleUpPage = false
        selectedTab = .home
        isLoggedIn = false
    }
}

#Preview {
    ContentView()
}
