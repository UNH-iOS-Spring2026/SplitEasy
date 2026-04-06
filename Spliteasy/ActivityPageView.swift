//
//  ActivityPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//

import SwiftUI

struct ActivityPageView: View {
    let transactions: [TransactionItem]
    @Binding var showThemeMenu: Bool
    var onRefresh: (() async -> Void)? = nil

    @State private var selectedChart: ActivityChartType = .category

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 126) {
            CurvedAppHeader(
                title: "Activity",
                subtitle: "All your transactions",
                height: 126
            ) {
                Color.clear.frame(width: 42, height: 42)
            }
        } content: {
            VStack(spacing: 0) {
                chartCard
                    .padding(.top, 14)
                    .padding(.horizontal, 20)

                Text("Recent Transactions")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(transactions) { transaction in
                        ActivityTransactionRow(item: transaction)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
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
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private var categoryData: [CategoryItem] {
        let currentMonthKey = monthKey(for: Date())
        let monthTransactions = transactions.filter { $0.monthKey == currentMonthKey }

        let grouped = Dictionary(grouping: monthTransactions, by: { $0.category })
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }

        let colors: [String: Color] = [
            "Food": Color(red: 0.49, green: 0.38, blue: 0.78),
            "Transport": Color(red: 0.38, green: 0.39, blue: 0.88),
            "Shopping": Color(red: 0.89, green: 0.27, blue: 0.58),
            "Travel": Color(red: 0.22, green: 0.70, blue: 0.60),
            "Other": Color(red: 0.62, green: 0.68, blue: 0.77)
        ]

        let sorted = grouped
            .map { key, value in
                CategoryItem(name: key, amount: value, color: colors[key] ?? Color.gray)
            }
            .sorted { $0.amount > $1.amount }

        return sorted.isEmpty
            ? [CategoryItem(name: "Other", amount: 0.01, color: Color(red: 0.62, green: 0.68, blue: 0.77))]
            : sorted
    }

    private var monthlyData: [MonthlyExpense] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        let grouped = Dictionary(grouping: transactions, by: { $0.monthKey })
            .mapValues { items in
                items.reduce(0) { $0 + $1.amount }
            }

        return (0..<6).compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -(5 - offset), to: Date()) else { return nil }
            let key = monthKey(for: date)
            return MonthlyExpense(
                month: formatter.string(from: date),
                amount: grouped[key] ?? 0
            )
        }
    }

    private var categoryChartSection: some View {
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
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                selectedChart == .category
                                ? LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: selectedChart == .category ? 0 : 1.5)
                            )
                    )
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
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                selectedChart == .month
                                ? LinearGradient(
                                    colors: [AppPalette.accentStart, AppPalette.accentEnd],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .leading, endPoint: .trailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(AppPalette.border, lineWidth: selectedChart == .month ? 0 : 1.5)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func monthKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: date)
    }

    private func shortAmount(_ amount: Double) -> String {
        if amount >= 1000 {
            return String(format: "$%.1fk", amount / 1000)
        }
        return String(format: "$%.0f", amount)
    }

    private func barHeight(for amount: Double) -> CGFloat {
        let maxAmount = max(monthlyData.map(\.amount).max() ?? 1, 1)
        let minHeight: CGFloat = amount > 0 ? 16 : 4
        let maxHeight: CGFloat = 116
        let normalized = amount / maxAmount
        return amount > 0 ? max(minHeight, CGFloat(normalized) * maxHeight) : minHeight
    }
}

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
        .rotationEffect(.degrees(-90))
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

struct ActivityDonutSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        return path
    }
}

struct ActivityTransactionRow: View {
    let item: TransactionItem

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppPalette.rowIconBg)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppPalette.accentMid)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Text("\(item.subtitle) • \(item.date)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppPalette.secondaryText)
            }

            Spacer()

            Text("$\(String(format: "%.2f", item.amount))")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppPalette.primaryText)
        }
        .padding(.vertical, 12)
    }

    private var iconName: String {
        switch item.category.lowercased() {
        case "food":
            return "fork.knife"
        case "transport":
            return "car.fill"
        case "shopping":
            return "bag.fill"
        case "travel":
            return "airplane"
        default:
            return "receipt"
        }
    }
}
