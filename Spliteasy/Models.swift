//
//  Models.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//
// Shared data models used across the app.
//
import SwiftUI

enum Tab: String, Sendable {
    case home
    case friends
    case activity
    case profile
    case add

    var title: String {
        switch self {
        case .home: return "Home"
        case .friends: return "Friends"
        case .activity: return "Activity"
        case .profile: return "Profile"
        case .add: return "Add"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .friends: return "person.2"
        case .activity: return "clock"
        case .profile: return "person.crop.circle"
        case .add: return "plus"
        }
    }
}

enum FriendsSection: String, Sendable {
    case friends
    case groups
}

enum BalanceFilter: String, Sendable {
    case none
    case youOwe
    case owesYou

    var title: String {
        switch self {
        case .none: return "None"
        case .youOwe: return "Friends you owe"
        case .owesYou: return "Friends who owe you"
        }
    }

    var tintColor: Color {
        switch self {
        case .none: return .gray
        case .youOwe: return .red
        case .owesYou: return .green
        }
    }
}

enum BalanceDirection: String, Codable, Sendable {
    case youOwe
    case owesYou
}

enum ItemKind: String, Codable, Sendable {
    case friend
    case group
}

struct ExpenseEntry: Identifiable, Hashable, Sendable {
    let id: String
    let description: String
    let amount: Double
    let dateText: String
    let receiptURL: String

    let targetType: String
    let targetDocumentId: String

    let paidBy: [String]
    let splitWith: [String]
    let paidAmounts: [String: Double]
    let yourNetAmount: Double

    let isGroupMirror: Bool
    let parentGroupExpenseId: String
    let groupName: String
    let groupMemberNames: [String]

    init(
        id: String = UUID().uuidString,
        description: String,
        amount: Double,
        dateText: String,
        receiptURL: String = "",
        targetType: String = "",
        targetDocumentId: String = "",
        paidBy: [String] = [],
        splitWith: [String] = [],
        paidAmounts: [String: Double] = [:],
        yourNetAmount: Double = 0,
        isGroupMirror: Bool = false,
        parentGroupExpenseId: String = "",
        groupName: String = "",
        groupMemberNames: [String] = []
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.dateText = dateText
        self.receiptURL = receiptURL
        self.targetType = targetType
        self.targetDocumentId = targetDocumentId
        self.paidBy = paidBy
        self.splitWith = splitWith
        self.paidAmounts = paidAmounts
        self.yourNetAmount = yourNetAmount
        self.isGroupMirror = isGroupMirror
        self.parentGroupExpenseId = parentGroupExpenseId
        self.groupName = groupName
        self.groupMemberNames = groupMemberNames
    }

    var isEditableGroupExpense: Bool {
        targetType == "group" || isGroupMirror
    }

    var editExpenseDocumentId: String {
        if isGroupMirror, !parentGroupExpenseId.isEmpty {
            return parentGroupExpenseId
        }
        return id
    }
}

struct GroupExpenseDraft: Hashable, Sendable {
    var paidBy: [String]
    var splitWith: [String]
    var yourNetAmount: Double
    var paidAmounts: [String: Double] = [:]
}

struct BalanceItem: Identifiable, Hashable, Sendable {
    let id: String
    let kind: ItemKind
    var name: String
    var amount: Double
    var direction: BalanceDirection
    var participantCount: Int
    var memberNames: [String]
    var expenses: [ExpenseEntry]
    var isBlocked: Bool

    init(
        id: String,
        kind: ItemKind,
        name: String,
        amount: Double,
        direction: BalanceDirection,
        participantCount: Int = 2,
        memberNames: [String] = [],
        expenses: [ExpenseEntry] = [],
        isBlocked: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.amount = amount
        self.direction = direction
        self.participantCount = participantCount
        self.memberNames = memberNames
        self.expenses = expenses
        self.isBlocked = isBlocked
    }

    var balanceText: String {
        let formattedAmount = String(format: "%.2f", amount)
        switch direction {
        case .youOwe:
            return "You owe $\(formattedAmount)"
        case .owesYou:
            return "owes you $\(formattedAmount)"
        }
    }
}

enum ActivityChartType: String, Sendable {
    case category
    case month
}

struct CategoryItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}

struct MonthlyExpense: Identifiable, Hashable, Sendable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct TransactionItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let amount: Double
    let date: String
    let monthKey: String
    let category: String
    let entryType: String

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        amount: Double,
        date: String,
        monthKey: String,
        category: String,
        entryType: String = "expense"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.amount = amount
        self.date = date
        self.monthKey = monthKey
        self.category = category
        self.entryType = entryType
    }
}

struct AppNotificationItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let message: String
    let timeText: String

    init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        timeText: String
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.timeText = timeText
    }
}
