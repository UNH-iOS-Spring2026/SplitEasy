import SwiftUI

// MARK: - Activity Page
// Displays user transaction activity including:
// - Summary charts (category & monthly)
// - List of recent transactions
// - Interactive chart toggle

struct ActivityPageView: View {
    let transactions: [TransactionItem]
    @Binding var showThemeMenu: Bool
    @State private var selectedChart: ActivityChartType = .category

    private static let monthTitleFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private static let monthKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    private static let shortMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                headerSection

                chartCard
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                Text("Recent Transactions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        ForEach(transactions) { transaction in
                            ActivityTransactionRow(item: transaction)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .background(
                LinearGradient(
                    colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var headerSection: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(alignment: .top) {
                ThemeHeaderButton(showThemeMenu: $showThemeMenu)

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Activity")
                        .font(.system(size: 28, weight: .bold))
                        .italic()
                        .foregroundColor(AppPalette.primaryText)

                    Text("All your transactions")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedChart == .category ? "This Month by Category" : "Monthly Expenses")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text(selectedChart == .category ? currentMonthTitle : "Last 6 months")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                }

                Spacer()

                HStack(spacing: 8) {
                    Capsule()
                        .fill(selectedChart == .category ? AppPalette.accentMid : Color.gray.opacity(0.35))
                        .frame(width: 28, height: 12)

                    Capsule()
                        .fill(selectedChart == .month ? AppPalette.accentMid : Color.gray.opacity(0.35))
                        .frame(width: 28, height: 12)
                }
                .padding(.top, 4)
            }

            if selectedChart == .category {
                categoryChartSection
                    .padding(.top, 10)
            } else {
                monthChartSection
                    .padding(.top, 10)
            }

            chartToggleButtons
                .padding(.top, 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppPalette.softCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
        )
    }

  
    private var currentMonthTitle: String {
        ActivityPageView.monthTitleFormatter.string(from: Date())
    }

    private var categoryData: [CategoryItem] {
        let currentMonthKey = monthKey(for: Date())
        let monthTransactions = transactions.filter { $0.monthKey == currentMonthKey }

        let grouped = Dictionary(grouping: monthTransactions, by: { $0.category })
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }

        
        let sorted = grouped
            .map { key, value in
                CategoryItem(name: key, amount: value, color: color(for: key))
            }
            .sorted { $0.amount > $1.amount }

        
        return sorted
    }

    
    private func color(for category: String) -> Color {
        let namedColors: [String: Color] = [
            "Food":      Color(red: 0.49, green: 0.38, blue: 0.78),
            "Transport": Color(red: 0.38, green: 0.39, blue: 0.88),
            "Shopping":  Color(red: 0.89, green: 0.27, blue: 0.58),
            "Travel":    Color(red: 0.22, green: 0.70, blue: 0.60),
            "Other":     Color(red: 0.62, green: 0.68, blue: 0.77)
        ]
        if let known = namedColors[category] { return known }
        let palette: [Color] = [
            Color(red: 0.95, green: 0.50, blue: 0.25),
            Color(red: 0.25, green: 0.75, blue: 0.85),
            Color(red: 0.80, green: 0.60, blue: 0.20),
            Color(red: 0.40, green: 0.80, blue: 0.50),
            Color(red: 0.70, green: 0.30, blue: 0.90)
        ]
        let index = abs(category.hashValue) % palette.count
        return palette[index]
    }

    private var monthlyData: [MonthlyExpense] {
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: transactions, by: { $0.monthKey })
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }

        return (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -(5 - offset), to: Date()) else { return nil }
            let key = monthKey(for: date)
            return MonthlyExpense(
                month: ActivityPageView.shortMonthFormatter.string(from: date),
                amount: grouped[key] ?? 0
            )
        }
    }

    private var categoryChartSection: some View {
        Group {
            if categoryData.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(AppPalette.secondaryText.opacity(0.5))
                        Text("No transactions this month")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppPalette.secondaryText)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                HStack(spacing: 18) {
                    ModernDonutChartView(data: categoryData)
                        .frame(width: 146, height: 146)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(categoryData) { item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(AppPalette.primaryText)

                                    Text("$\(String(format: "%.2f", item.amount))")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppPalette.secondaryText)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var monthChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(monthlyData) { item in
                    VStack(spacing: 8) {
                        Text(item.amount > 0 ? shortAmount(item.amount) : "")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppPalette.secondaryText)
                            .frame(height: 16)

                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 28, height: barHeight(for: item.amount))

                        Text(item.month)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppPalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 190, alignment: .bottom)
        }
    }

    private func toggleBackground(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                isSelected
                ? LinearGradient(
                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                : LinearGradient(
                    colors: [Color.clear, Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: isSelected ? 0 : 1.5)
            )
    }

    private var chartToggleButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedChart = .category
                }
            } label: {
                Text("By Category")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedChart == .category ? .white : AppPalette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(toggleBackground(isSelected: selectedChart == .category))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedChart = .month
                }
            } label: {
                Text("By Month")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedChart == .month ? .white : AppPalette.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(toggleBackground(isSelected: selectedChart == .month))
            }
            .buttonStyle(.plain)
        }
    }

    private func monthKey(for date: Date) -> String {
        ActivityPageView.monthKeyFormatter.string(from: date)
    }

    private func shortAmount(_ amount: Double) -> String {
        amount >= 1000
            ? String(format: "$%.1fk", amount / 1000)
            : String(format: "$%.0f", amount)
    }

    private func barHeight(for amount: Double) -> CGFloat {
        guard amount > 0 else { return 4 }
        let maxAmount = monthlyData.map(\.amount).max() ?? 1
        let safeMax = maxAmount > 0 ? maxAmount : 1
        return max(16, CGFloat(amount / safeMax) * 116)
    }
}

// MARK: - Donut Chart

struct ModernDonutChartView: View {
    let data: [CategoryItem]

    private var total: Double {
        max(data.reduce(0) { $0 + $1.amount }, 0.01)
    }

    var body: some View {
        ZStack {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                ActivityDonutSlice(
                    startAngle: startAngle(for: index),
                    endAngle: endAngle(for: index)
                )
                .stroke(
                    item.color,
                    style: StrokeStyle(lineWidth: 22, lineCap: .butt, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))
            }

            Circle()
                .fill(AppPalette.softCard)
                .frame(width: 60, height: 60)

            VStack(spacing: 2) {
                Text("$\(String(format: "%.0f", data.reduce(0) { $0 + $1.amount }))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text("Month")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
            }
        }
    }

    private func startAngle(for index: Int) -> Angle {
        let previousTotal = data.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees((previousTotal / total) * 360)
    }

    private func endAngle(for index: Int) -> Angle {
        let currentTotal = data.prefix(index + 1).reduce(0) { $0 + $1.amount }
        return .degrees((currentTotal / total) * 360)
    }
}

// MARK: - Transaction Row

struct ActivityTransactionRow: View {
    let item: TransactionItem

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.rowIconBg)
                        .frame(width: 56, height: 56)

                    Image(systemName: iconName(for: item.category))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppPalette.accentMid)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                        .lineLimit(1)

                    Text(item.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "$%.2f", item.amount))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)

                    Text(item.date)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppPalette.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)

            Divider()
                .background(AppPalette.divider)
        }
    }

    private func iconName(for category: String) -> String {
        switch category {
        case "Food":      return "fork.knife"
        case "Transport": return "car.fill"
        case "Shopping":  return "bag.fill"
        case "Travel":    return "airplane"
        default:          return "receipt"
        }
    }
}

// MARK: - Donut Slice Shape

struct ActivityDonutSlice: Shape {
    var startAngle: Angle
    var endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius - 14,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}
