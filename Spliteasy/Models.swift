import SwiftUI

enum Tab {
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

enum FriendsSection {
    case friends
    case groups
}

enum BalanceFilter {
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

enum BalanceDirection {
    case youOwe
    case owesYou
}

enum ItemKind {
    case friend
    case group
}

struct ExpenseEntry: Identifiable, Hashable {
    let id: String
    let description: String
    let amount: Double
    let dateText: String
    let receiptURL: String

    init(
        id: String = UUID().uuidString,
        description: String,
        amount: Double,
        dateText: String,
        receiptURL: String = ""
    ) {
        self.id = id
        self.description = description
        self.amount = amount
        self.dateText = dateText
        self.receiptURL = receiptURL
    }
}

struct GroupExpenseDraft: Hashable {
    var paidBy: [String]
    var splitWith: [String]
    var yourNetAmount: Double
    var paidAmounts: [String: Double] = [:]
}

struct BalanceItem: Identifiable, Hashable {
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

enum ActivityChartType {
    case category
    case month
}

struct CategoryItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: Double
    let color: Color
}

struct MonthlyExpense: Identifiable, Hashable {
    let id = UUID()
    let month: String
    let amount: Double
}

struct TransactionItem: Identifiable, Hashable {
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

struct AppNotificationItem: Identifiable, Hashable {
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
