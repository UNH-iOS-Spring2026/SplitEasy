import SwiftUI
import FirebaseAuth

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
    @State private var monthlyLimit: Double = 0.0
    @State private var isLoggedIn = false
    @State private var isCheckingSession = true

    @State private var savedThemeMode: String = AppThemeMode.auto.rawValue
    @State private var showThemeMenu = false

    @State private var profileName: String = ""
    @State private var profileEmail: String = ""
    @State private var profilePhone: String = ""
    @State private var recentNotifications: [AppNotificationItem] = []

    @State private var selectedFriendDetail: BalanceItem?
    @State private var selectedExpenseTarget: BalanceItem?
    @State private var selectedSettleTarget: BalanceItem?

    @State private var friendsData: [BalanceItem] = []
    @State private var groupsData: [BalanceItem] = []
    @State private var activityTransactions: [TransactionItem] = []

    var body: some View {
        ZStack(alignment: .leading) {
            if isCheckingSession {
                loadingView
            } else if isLoggedIn {
                mainAppView
            } else {
                LoginPageView {
                    handleSuccessfulAuth()
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
        .onAppear {
            checkExistingSession()
        }
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ProgressView("Loading...")
                .foregroundColor(AppPalette.primaryText)
                .tint(AppPalette.accentMid)
        }
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
                        friends: filteredFriends.filter { !$0.isBlocked },
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
                            if item.isBlocked { return }
                            openExpensePage(for: item)
                        },
                        onSettleUp: { item in
                            if item.isBlocked { return }
                            selectedSettleTarget = item
                            showFriendDetailPage = false
                            showSettleUpPage = true
                            settleUpReturnToFriendDetail = true
                        },
                        onRefresh: {
                            loadFriendHistory(friendId: friend.id)
                            loadFriendsFromFirestore()
                        },
                        onToggleBlock: toggleBlockStatus,
                        onRemoveFriend: removeFriend
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
                        availableFriends: friendsData.filter { !$0.isBlocked },
                        onSaveGroup: saveNewGroup
                    )
                } else if showExpenseSelectionPage {
                    RecentSelectionPageView(
                        recentFriends: recentFriends.filter { !$0.isBlocked },
                        recentGroups: recentGroups,
                        onSelectItem: { item in
                            if item.kind == .friend && item.isBlocked { return }
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
                            showThemeMenu: $showThemeMenu,
                            onSaveMonthlyLimit: saveMonthlyLimit
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
                            onResetPassword: resetPassword,
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
                            FirebaseService.shared.updateThemeMode(newValue.rawValue) { _ in }
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
        .onChange(of: selectedTab) { _, _ in
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

    private func checkExistingSession() {
        if FirebaseService.shared.currentUserId != nil {
            handleSuccessfulAuth()
        } else {
            isLoggedIn = false
            isCheckingSession = false
        }
    }

    private func handleSuccessfulAuth() {
        FirebaseService.shared.fetchCurrentUserProfile { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profile):
                    profileName = profile.nickname.isEmpty ? profile.fullName : profile.nickname
                    profileEmail = profile.email.isEmpty ? (FirebaseService.shared.currentUserEmail ?? "") : profile.email
                    profilePhone = profile.phone
                    monthlyLimit = profile.monthlyLimit
                    savedThemeMode = profile.themeMode
                    isLoggedIn = true
                    isCheckingSession = false

                    loadFriendsFromFirestore()
                    loadGroupsFromFirestore()
                    loadActivityFromFirestore()
                    loadNotificationsFromFirestore()

                case .failure:
                    profileName = ""
                    profileEmail = FirebaseService.shared.currentUserEmail ?? ""
                    profilePhone = ""
                    monthlyLimit = 0
                    savedThemeMode = AppThemeMode.auto.rawValue
                    isLoggedIn = true
                    isCheckingSession = false

                    loadFriendsFromFirestore()
                    loadGroupsFromFirestore()
                    loadActivityFromFirestore()
                    loadNotificationsFromFirestore()
                }
            }
        }
    }

    private func loadFriendsFromFirestore() {
        FirebaseService.shared.fetchFriends { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    let previousFriends = friendsData

                    friendsData = records.map { record in
                        let existingFriend = previousFriends.first(where: { $0.id == record.documentId })

                        let preservedHistory = (existingFriend?.expenses ?? []).filter { $0.dateText != "Contact" }
                        let contactExpense: [ExpenseEntry] = record.friendContact.isEmpty ? [] : [
                            ExpenseEntry(
                                id: "contact-\(record.documentId)",
                                description: record.friendContact,
                                amount: 0,
                                dateText: "Contact"
                            )
                        ]

                        return BalanceItem(
                            id: record.documentId,
                            kind: .friend,
                            name: record.friendName,
                            amount: record.balanceAmount,
                            direction: record.balanceDirection == "youOwe" ? .youOwe : .owesYou,
                            participantCount: 2,
                            memberNames: [],
                            expenses: preservedHistory + contactExpense,
                            isBlocked: record.isBlocked
                        )
                    }

                    if let selectedFriendDetail {
                        self.selectedFriendDetail = friendsData.first(where: { $0.id == selectedFriendDetail.id })
                    }

                    if let selectedSettleTarget {
                        self.selectedSettleTarget = friendsData.first(where: { $0.id == selectedSettleTarget.id })
                    }

                case .failure:
                    friendsData = []
                }
            }
        }
    }

    private func loadGroupsFromFirestore() {
        FirebaseService.shared.fetchGroups { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    groupsData = records.map { record in
                        BalanceItem(
                            id: record.documentId,
                            kind: .group,
                            name: record.name,
                            amount: record.balanceAmount,
                            direction: record.balanceDirection == "youOwe" ? .youOwe : .owesYou,
                            participantCount: max(record.participantCount, 1),
                            memberNames: record.memberNames,
                            expenses: [],
                            isBlocked: false
                        )
                    }

                    if let selectedExpenseTarget, selectedExpenseTarget.kind == .group {
                        self.selectedExpenseTarget = groupsData.first(where: { $0.id == selectedExpenseTarget.id })
                    }

                case .failure:
                    groupsData = []
                }
            }
        }
    }

    private func loadActivityFromFirestore() {
        FirebaseService.shared.fetchActivity { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    activityTransactions = records.map {
                        TransactionItem(
                            id: $0.documentId,
                            title: $0.title,
                            subtitle: $0.subtitle,
                            amount: $0.amount,
                            date: $0.date,
                            monthKey: $0.monthKey,
                            category: $0.category,
                            entryType: $0.entryType
                        )
                    }

                case .failure:
                    activityTransactions = []
                }
            }
        }
    }

    private func loadNotificationsFromFirestore() {
        FirebaseService.shared.fetchNotifications { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    recentNotifications = records.map {
                        AppNotificationItem(
                            id: $0.documentId,
                            title: $0.title,
                            message: $0.message,
                            timeText: $0.timeText
                        )
                    }

                case .failure:
                    recentNotifications = []
                }
            }
        }
    }

    private func loadFriendHistory(friendId: String) {
        FirebaseService.shared.fetchExpenseHistory(
            targetType: "friend",
            targetDocumentId: friendId
        ) { result in
            DispatchQueue.main.async {
                guard let index = friendsData.firstIndex(where: { $0.id == friendId }) else { return }

                switch result {
                case .success(let records):
                    let preservedContactExpense = friendsData[index].expenses.filter { $0.dateText == "Contact" }

                    let historyExpenses = records.map {
                        ExpenseEntry(
                            id: $0.documentId,
                            description: $0.description,
                            amount: $0.amount,
                            dateText: $0.dateText,
                            receiptURL: $0.receiptURL
                        )
                    }

                    friendsData[index].expenses = historyExpenses + preservedContactExpense

                    if selectedFriendDetail?.id == friendId {
                        selectedFriendDetail = friendsData[index]
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private func loadGroupHistory(groupId: String) {
        FirebaseService.shared.fetchExpenseHistory(
            targetType: "group",
            targetDocumentId: groupId
        ) { result in
            DispatchQueue.main.async {
                guard let index = groupsData.firstIndex(where: { $0.id == groupId }) else { return }

                switch result {
                case .success(let records):
                    groupsData[index].expenses = records.map {
                        ExpenseEntry(
                            id: $0.documentId,
                            description: $0.description,
                            amount: $0.amount,
                            dateText: $0.dateText,
                            receiptURL: $0.receiptURL
                        )
                    }

                    if selectedExpenseTarget?.id == groupId {
                        selectedExpenseTarget = groupsData[index]
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private var currentMonthSpent: Double {
        let currentMonthKey = monthKey(for: Date())

        return activityTransactions
            .filter { item in
                guard item.monthKey == currentMonthKey else { return false }

                let normalizedType = item.entryType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                let normalizedTitle = item.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if normalizedType == "settlement" { return false }
                if normalizedTitle.hasPrefix("settle up with") { return false }

                return true
            }
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
        selectedFriendDetail = latestFriendVersion(for: item)
        loadFriendHistory(friendId: item.id)
        showFriendDetailPage = true
        showSettleUpSelectionPage = false
        showSettleUpPage = false
        selectedTab = .friends
        selectedSection = .friends
    }

    private func openExpensePage(for item: BalanceItem) {
        if item.kind == .friend && item.isBlocked { return }

        selectedExpenseTarget = item.kind == .friend ? latestFriendVersion(for: item) : item

        if item.kind == .group {
            loadGroupHistory(groupId: item.id)
        } else {
            loadFriendHistory(friendId: item.id)
        }

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
        FirebaseService.shared.addFriend(friendName: name, friendContact: contact) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadFriendsFromFirestore()
                    selectedSection = .friends
                    showAddFriendPage = false
                    selectedTab = .friends

                    FirebaseService.shared.saveNotification(
                        title: "Friend added",
                        message: "\(name) was added successfully."
                    ) { _ in
                        loadNotificationsFromFirestore()
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private func saveNewGroup(name: String, type: GroupType, members: [BalanceItem]) {
        FirebaseService.shared.createGroup(
            name: name,
            type: type.firestoreValue,
            memberNames: members.map(\.name)
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadGroupsFromFirestore()
                    selectedSection = .groups
                    showCreateGroupPage = false
                    selectedTab = .friends

                    FirebaseService.shared.saveNotification(
                        title: "Group created",
                        message: "\(name) was created successfully."
                    ) { _ in
                        loadNotificationsFromFirestore()
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private func settleUpFriend(itemID: String, amount: Double, method: String) {
        guard let index = friendsData.firstIndex(where: { $0.id == itemID }) else { return }
        guard !friendsData[index].isBlocked else { return }

        let friendName = friendsData[index].name

        FirebaseService.shared.saveSettlement(
            friendDocumentId: itemID,
            friendName: friendName,
            amount: amount,
            method: method
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadFriendsFromFirestore()
                    loadActivityFromFirestore()
                    loadFriendHistory(friendId: itemID)

                    FirebaseService.shared.saveNotification(
                        title: "Settlement saved",
                        message: "You settled \(friendName) via \(method)."
                    ) { _ in
                        loadNotificationsFromFirestore()
                    }

                    if settleUpReturnToFriendDetail {
                        showSettleUpPage = false
                        showFriendDetailPage = true
                        selectedTab = .friends
                    } else {
                        showSettleUpPage = false
                        showSettleUpSelectionPage = false
                        selectedTab = .home
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private func saveExpense(
        itemID: String,
        description: String,
        amount: Double,
        direction: BalanceDirection,
        groupDraft: GroupExpenseDraft?,
        receiptURL: String?
    ) {
        if let friend = friendsData.first(where: { $0.id == itemID }), friend.isBlocked {
            return
        }

        let now = Date()

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "MMM d"
        let dayText = dayFormatter.string(from: now)

        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let monthKey = monthFormatter.string(from: now)

        let category = inferCategory(from: description)

        if let friendIndex = friendsData.firstIndex(where: { $0.id == itemID }) {
            let friend = friendsData[friendIndex]
            guard !friend.isBlocked else { return }

            let subtitle = direction == .owesYou
                ? "You paid · \(friend.name)"
                : "\(friend.name) paid"

            let payload = FirestoreExpensePayload(
                targetType: "friend",
                targetDocumentId: itemID,
                description: description,
                amount: amount,
                direction: direction,
                category: category,
                dateText: dayText,
                monthKey: monthKey,
                activitySubtitle: subtitle,
                groupDraft: nil,
                receiptURL: receiptURL
            )

            FirebaseService.shared.saveExpense(payload: payload) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        loadFriendsFromFirestore()
                        loadActivityFromFirestore()
                        loadFriendHistory(friendId: itemID)

                        FirebaseService.shared.saveNotification(
                            title: "Expense added",
                            message: "\(description) was added for \(friend.name)."
                        ) { _ in
                            loadNotificationsFromFirestore()
                        }

                        if let updatedFriend = friendsData.first(where: { $0.id == itemID }) {
                            selectedFriendDetail = updatedFriend
                        } else {
                            selectedFriendDetail = latestFriendVersion(for: friend)
                        }

                        showFriendDetailPage = true
                        showExpenseSelectionPage = false
                        showSettleUpSelectionPage = false
                        showSettleUpPage = false
                        selectedTab = .friends
                        selectedSection = .friends

                    case .failure:
                        break
                    }
                }
            }

            return
        }

        if let groupIndex = groupsData.firstIndex(where: { $0.id == itemID }) {
            let group = groupsData[groupIndex]

            let subtitle: String
            if let groupDraft {
                let payerDetails = groupDraft.paidBy.map { person in
                    let paid = groupDraft.paidAmounts[person] ?? 0
                    return "\(person) $\(String(format: "%.2f", paid))"
                }.joined(separator: ", ")

                subtitle = "Paid by \(payerDetails) · split with \(groupDraft.splitWith.count)"
            } else {
                subtitle = direction == .owesYou
                    ? "You paid · \(group.participantCount) people"
                    : "\(group.participantCount) people paid"
            }

            let payload = FirestoreExpensePayload(
                targetType: "group",
                targetDocumentId: itemID,
                description: description,
                amount: amount,
                direction: direction,
                category: category,
                dateText: dayText,
                monthKey: monthKey,
                activitySubtitle: subtitle,
                groupDraft: groupDraft,
                receiptURL: receiptURL
            )

            FirebaseService.shared.saveExpense(payload: payload) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        loadGroupsFromFirestore()
                        loadActivityFromFirestore()
                        loadGroupHistory(groupId: itemID)

                        FirebaseService.shared.saveNotification(
                            title: "Group expense added",
                            message: "\(description) was added to \(group.name)."
                        ) { _ in
                            loadNotificationsFromFirestore()
                        }

                        selectedSection = .groups
                        selectedTab = .friends

                    case .failure:
                        break
                    }
                }
            }
        }
    }

    private func toggleBlockStatus(_ friend: BalanceItem) {
        FirebaseService.shared.setFriendBlocked(
            friendDocumentId: friend.id,
            isBlocked: !friend.isBlocked
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadFriendsFromFirestore()
                    loadFriendHistory(friendId: friend.id)

                    FirebaseService.shared.saveNotification(
                        title: friend.isBlocked ? "User unblocked" : "User blocked",
                        message: friend.isBlocked
                            ? "\(friend.name) was unblocked successfully."
                            : "\(friend.name) was blocked successfully."
                    ) { _ in
                        loadNotificationsFromFirestore()
                    }

                case .failure:
                    break
                }
            }
        }
    }

    private func removeFriend(_ friend: BalanceItem) {
        FirebaseService.shared.deleteFriend(friendDocumentId: friend.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    selectedFriendDetail = nil
                    selectedExpenseTarget = nil
                    selectedSettleTarget = nil
                    showFriendDetailPage = false
                    showSettleUpPage = false
                    showSettleUpSelectionPage = false
                    selectedTab = .friends
                    selectedSection = .friends

                    loadFriendsFromFirestore()
                    loadActivityFromFirestore()

                    FirebaseService.shared.saveNotification(
                        title: "Friend deleted",
                        message: "\(friend.name) was removed successfully."
                    ) { _ in
                        loadNotificationsFromFirestore()
                    }

                case .failure:
                    break
                }
            }
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

    private func saveMonthlyLimit(_ newLimit: Double) {
        monthlyLimit = max(newLimit, 0)

        FirebaseService.shared.updateCurrentUserProfile(
            fullName: "",
            nickname: profileName,
            email: profileEmail,
            phone: profilePhone,
            monthlyLimit: monthlyLimit,
            selectedAvatarIndex: 0
        ) { _ in }

        FirebaseService.shared.saveNotification(
            title: "Monthly limit updated",
            message: monthlyLimit > 0
                ? "Your monthly limit was set to $\(String(format: "%.2f", monthlyLimit))."
                : "Your monthly limit was cleared."
        ) { _ in
            loadNotificationsFromFirestore()
        }
    }

    private func saveProfile(_ nickname: String, _ email: String, _ phone: String) {
        let cleanedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        profileName = cleanedNickname
        profileEmail = cleanedEmail
        profilePhone = phone

        FirebaseService.shared.updateCurrentUserProfile(
            fullName: cleanedNickname,
            nickname: cleanedNickname,
            email: cleanedEmail,
            phone: phone,
            monthlyLimit: monthlyLimit,
            selectedAvatarIndex: 0
        ) { result in
            if case .success = result {
                FirebaseService.shared.saveNotification(
                    title: "Profile updated",
                    message: "Your profile was updated successfully."
                ) { _ in
                    loadNotificationsFromFirestore()
                }
            }
        }
    }

    private func submitFeedback(_ rating: Int, _ message: String) {
        FirebaseService.shared.saveFeedback(rating: rating, message: message) { result in
            if case .success = result {
                FirebaseService.shared.saveNotification(
                    title: "Feedback submitted",
                    message: "Thanks for sharing your feedback."
                ) { _ in
                    loadNotificationsFromFirestore()
                }
            }
        }
    }

    private func contactSupport(_ subject: String, _ message: String) {
        FirebaseService.shared.saveSupportMessage(subject: subject, message: message) { result in
            if case .success = result {
                FirebaseService.shared.saveNotification(
                    title: "Support message sent",
                    message: "We received your message and will get back to you."
                ) { _ in
                    loadNotificationsFromFirestore()
                }
            }
        }
    }

    private func resetPassword(
        _ currentPassword: String,
        _ newPassword: String,
        _ completion: @escaping (Result<Void, Error>) -> Void
    ) {
        FirebaseService.shared.updateCurrentUserPassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
            completion: completion
        )
    }

    private func signOut() {
        do {
            try FirebaseService.shared.auth.signOut()
            isLoggedIn = false
            isCheckingSession = false
            selectedTab = .home
            selectedSection = .friends
            showPlusMenu = false
            showExpenseSelectionPage = false
            showCreateGroupPage = false
            showAddFriendPage = false
            showFriendDetailPage = false
            showSettleUpSelectionPage = false
            showSettleUpPage = false
            settleUpReturnToFriendDetail = false
            selectedFriendDetail = nil
            selectedExpenseTarget = nil
            selectedSettleTarget = nil
            friendsData = []
            groupsData = []
            activityTransactions = []
            recentNotifications = []
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
        }
    }

    private func handleFriendsActionButtonTap() {
        if selectedSection == .friends {
            showAddFriendPage = true
        } else {
            showCreateGroupPage = true
        }
    }

    private func handleAddExpense() {
        showPlusMenu = false
        showExpenseSelectionPage = true
        selectedTab = .add
    }
}

#Preview {
    ContentView()
}
