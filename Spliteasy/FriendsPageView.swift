import SwiftUI

struct FriendsPageView: View {
    @Binding var selectedSection: FriendsSection
    let friendsData: [BalanceItem]
    let groupsData: [BalanceItem]
    let headerTitle: String
    @Binding var selectedFilter: BalanceFilter
    let totalYouOwe: Double
    let totalYouAreOwed: Double
    let onSelectItem: (BalanceItem) -> Void

    @State private var showFilterSheet = false
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            headerView(title: headerTitle)

            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 8)

            summaryCard
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(filteredCurrentItems) { item in
                        Button {
                            onSelectItem(item)
                        } label: {
                            BalanceRow(item: item)
                                .padding(.vertical, 6)
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    )
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 180)
                }
                .padding(.top, 10)
                .padding(.horizontal, 14)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: selectedSection)
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterPageView(selectedFilter: $selectedFilter)
        }
        .onChange(of: selectedSection) {
            searchText = ""
        }
    }

    private var currentItems: [BalanceItem] {
        selectedSection == .friends ? friendsData : groupsData
    }

    private var filteredCurrentItems: [BalanceItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            return currentItems
        }

        return currentItems.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var searchPlaceholder: String {
        selectedSection == .friends ? "Search friends" : "Search groups"
    }

    private var overallTitle: String {
        let net = totalYouAreOwed - totalYouOwe

        if net > 0 {
            return "You are owed $\(formattedAmount(net))"
        } else if net < 0 {
            return "You owe $\(formattedAmount(abs(net)))"
        } else {
            return "You are settled up"
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func headerView(title: String) -> some View {
        HStack {
            Spacer()

            Text(title)
                .font(.system(size: 24, weight: .bold))
                .italic()
                .foregroundColor(.black)
                .padding(.trailing, 7)
        }
        .padding(.horizontal, 20)
        .padding(.top, -30)
        .padding(.bottom, 6)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField(searchPlaceholder, text: $searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.purple.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.purple.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var summaryCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Overall")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gray)

                    Text(overallTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Button {
                    showFilterSheet = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(selectedFilter.tintColor)
                        .frame(width: 44, height: 44)
                        .background(Color.clear)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 14)

            HStack(spacing: 10) {
                balancePill(
                    text: "Owe $\(formattedAmount(totalYouOwe))",
                    bg: Color.red.opacity(0.08),
                    textColor: Color.red.opacity(0.85),
                    icon: "arrow.down.right"
                )

                balancePill(
                    text: "Owed $\(formattedAmount(totalYouAreOwed))",
                    bg: Color.green.opacity(0.10),
                    textColor: Color.green.opacity(0.85),
                    icon: "arrow.up.right"
                )
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)

            HStack(spacing: 0) {
                sectionButton(title: "Friends", type: .friends)
                sectionButton(title: "Groups", type: .groups)
            }
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.purple.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.purple.opacity(0.08), radius: 10, x: 0, y: 6)
        )
        .padding(.horizontal, 12)
    }

    private func sectionButton(title: String, type: FriendsSection) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedSection = type
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(selectedSection == type ? Color.purple : Color.gray)
                    .scaleEffect(selectedSection == type ? 1.03 : 1.0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)

                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 1)

                    HStack {
                        Rectangle()
                            .fill(selectedSection == type ? Color.purple : Color.clear)
                            .frame(height: 3)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func balancePill(text: String, bg: Color, textColor: Color, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))

            Text(text)
                .font(.system(size: 13, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(bg)
        )
    }
}
