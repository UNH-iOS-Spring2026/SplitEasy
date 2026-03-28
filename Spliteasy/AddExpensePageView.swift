import SwiftUI

struct AddExpensePageView: View {
    let selectedItem: BalanceItem?
    let onSaveExpense: (String, String, Double, BalanceDirection, GroupExpenseDraft?, String?) -> Void
    @Binding var selectedTab: Tab

    @State private var withName: String = ""
    @State private var descriptionText: String = ""
    @State private var amountText: String = ""

    @State private var splitEquallySelected = true
    @State private var showCustomSplitSheet = false
    @State private var selectedCustomOption: CustomSplitOption = .youPaidSplitEqually

    @State private var selectedPaidByPeople: Set<String> = ["YOU"]
    @State private var selectedSplitPeople: Set<String> = []
    @State private var showPaidByPicker = false
    @State private var showSplitPicker = false

    @State private var paidAmountsText: [String: String] = [:]

    @State private var receiptImage: UIImage?
    @State private var showReceiptPicker = false
    @State private var receiptURL: String = ""
    @State private var isUploadingReceipt = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppPalette.backgroundTop,
                    AppPalette.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        nameCard
                        cameraCard

                        inputCard(
                            icon: "bag",
                            placeholder: "Enter description",
                            text: $descriptionText
                        )

                        amountCard
                        splitButtonsSection

                        if isGroup && !splitEquallySelected {
                            payerAmountsCard
                        }

                        if enteredAmount > 0 {
                            summaryCard
                        }

                        Spacer(minLength: 120)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .sheet(isPresented: $showCustomSplitSheet) {
            CustomSplitPageView(
                selectedOption: $selectedCustomOption,
                enteredAmount: enteredAmount,
                participantCount: participantCount
            )
        }
        .sheet(isPresented: $showPaidByPicker) {
            GroupMemberPickerSheet(
                title: "Paid by",
                people: groupPeople,
                selectedPeople: $selectedPaidByPeople
            )
        }
        .sheet(isPresented: $showSplitPicker) {
            GroupMemberPickerSheet(
                title: "Split with",
                people: groupPeople,
                selectedPeople: $selectedSplitPeople
            )
        }
        .sheet(isPresented: $showReceiptPicker) {
            ImagePicker(image: $receiptImage)
        }
        .onAppear {
            withName = selectedItem?.name ?? ""
            if isGroup {
                selectedSplitPeople = Set(groupPeople)
                selectedPaidByPeople = ["YOU"]
                resetPaidAmountsForCurrentSelection()
            }
        }
        .onChange(of: amountText) { _, _ in
            if isGroup && !splitEquallySelected {
                resetPaidAmountsForCurrentSelection()
            }
        }
        .onChange(of: selectedPaidByPeople) { _, _ in
            if isGroup && !splitEquallySelected {
                resetPaidAmountsForCurrentSelection()
            }
        }
        .onChange(of: selectedItem?.id) { _, _ in
            receiptImage = nil
            receiptURL = ""
            isUploadingReceipt = false
        }
    }

    private var isGroup: Bool {
        selectedItem?.kind == .group
    }

    private var groupPeople: [String] {
        guard let selectedItem, selectedItem.kind == .group else { return [] }
        return ["YOU"] + selectedItem.memberNames
    }

    private var effectiveSplitPeople: [String] {
        let values = Array(selectedSplitPeople)
        return values.isEmpty ? groupPeople : values.sorted()
    }

    private var effectivePaidByPeople: [String] {
        let values = Array(selectedPaidByPeople)
        return values.isEmpty ? ["YOU"] : values.sorted()
    }

    private var headerView: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    selectedTab = selectedItem?.kind == .group ? .friends : .home
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
            .padding(.top, -45)

            Spacer()

            Button {
                saveExpense()
            } label: {
                HStack(spacing: 8) {
                    if isUploadingReceipt {
                        ProgressView()
                            .tint(.white)
                    }

                    Text("Save")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            AppPalette.accentStart,
                            AppPalette.accentEnd
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
                .opacity(canSaveExpense ? 1 : 0.65)
            }
            .buttonStyle(.plain)
            .disabled(!canSaveExpense || isUploadingReceipt)
            .padding(.top, -45)
        }
    }

    private var nameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("With")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(withName)
                .font(.system(size: 28, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }

    private var cameraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Button {
                showReceiptPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: receiptImage == nil ? "camera.fill" : "checkmark.circle.fill")
                        .font(.system(size: 16, weight: .bold))

                    Text(receiptImage == nil ? "Take a picture / choose image" : "Receipt selected")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [
                            AppPalette.accentStart,
                            AppPalette.accentEnd
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            if let receiptImage {
                Image(uiImage: receiptImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        )
    }

    private func inputCard(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppPalette.accentMid.opacity(0.10))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(AppPalette.accentMid)
                )

            VStack(alignment: .leading, spacing: 8) {
                TextField(placeholder, text: text)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)

                Rectangle()
                    .fill(AppPalette.border)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 6)
        )
    }

    private var amountCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppPalette.accentMid.opacity(0.10))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "dollarsign.square.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(AppPalette.accentMid)
                )

            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)

                Rectangle()
                    .fill(AppPalette.border)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 6)
        )
    }

    private var splitButtonsSection: some View {
        VStack(spacing: 16) {
            Button {
                splitEquallySelected = true
                if isGroup {
                    selectedPaidByPeople = ["YOU"]
                    selectedSplitPeople = Set(groupPeople)
                    resetPaidAmountsForCurrentSelection()
                } else {
                    selectedCustomOption = .youPaidSplitEqually
                }
            } label: {
                Text("Split equally")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [
                                AppPalette.accentStart,
                                AppPalette.accentEnd
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: AppPalette.accentMid.opacity(0.18), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            if isGroup {
                groupCustomCard
            } else {
                Button {
                    splitEquallySelected = false
                    showCustomSplitSheet = true
                } label: {
                    Text(customTitle)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppPalette.card)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var groupCustomCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Customise")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            HStack(spacing: 8) {
                Text("Paid by")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Button {
                    splitEquallySelected = false
                    showPaidByPicker = true
                } label: {
                    Text(paidByTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppPalette.accentMid)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppPalette.accentMid.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Text("and")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Button {
                    splitEquallySelected = false
                    showSplitPicker = true
                } label: {
                    Text(splitTitle)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppPalette.accentMid)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(AppPalette.accentMid.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }

            Text("The payer does not need to be included in the split.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
        )
    }

    private var payerAmountsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Paid Amounts")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Spacer()

                Button {
                    fillPaidAmountsEqually()
                } label: {
                    Text("Split paid equally")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppPalette.accentMid)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppPalette.accentMid.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            ForEach(effectivePaidByPeople, id: \.self) { person in
                HStack(spacing: 12) {
                    Text(person)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppPalette.primaryText)
                        .frame(width: 90, alignment: .leading)

                    TextField("0.00", text: bindingForPaidAmount(person))
                        .keyboardType(.decimalPad)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppPalette.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppPalette.searchField)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppPalette.border, lineWidth: 1)
                                )
                        )
                }
            }

            HStack {
                Text("Total entered")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)

                Spacer()

                Text("$\(String(format: "%.2f", totalPaidAmount))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(totalPaidAmountMatches ? .green.opacity(0.9) : .red.opacity(0.85))
            }

            if enteredAmount > 0 && !totalPaidAmountMatches {
                Text("Entered payer amounts must equal $\(String(format: "%.2f", enteredAmount)).")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red.opacity(0.85))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
        )
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(summaryText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(summaryColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 5)
        )
    }
}

extension AddExpensePageView {
    private var participantCount: Int {
        max(selectedItem?.participantCount ?? 2, 2)
    }

    private var enteredAmount: Double {
        Double(amountText) ?? 0
    }

    private var paidByTitle: String {
        let values = effectivePaidByPeople
        return values.count == 1 ? values[0] : "\(values.count) people"
    }

    private var splitTitle: String {
        let values = effectiveSplitPeople
        return values.count == 1 ? "SPLIT \(values[0])" : "SPLIT \(values.count)"
    }

    private func bindingForPaidAmount(_ person: String) -> Binding<String> {
        Binding(
            get: { paidAmountsText[person] ?? "" },
            set: { paidAmountsText[person] = $0 }
        )
    }

    private func parsedPaidAmount(for person: String) -> Double {
        Double((paidAmountsText[person] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var paidAmountsDictionary: [String: Double] {
        Dictionary(uniqueKeysWithValues: effectivePaidByPeople.map { ($0, parsedPaidAmount(for: $0)) })
    }

    private var totalPaidAmount: Double {
        effectivePaidByPeople.reduce(0) { $0 + parsedPaidAmount(for: $1) }
    }

    private var totalPaidAmountMatches: Bool {
        abs(totalPaidAmount - enteredAmount) < 0.01
    }

    private func fillPaidAmountsEqually() {
        let people = effectivePaidByPeople
        guard !people.isEmpty else { return }

        let total = enteredAmount
        guard total > 0 else {
            for person in people {
                paidAmountsText[person] = ""
            }
            return
        }

        let evenShare = total / Double(people.count)
        var runningTotal: Double = 0

        for index in people.indices {
            let person = people[index]
            let value: Double

            if index == people.count - 1 {
                value = max(0, total - runningTotal)
            } else {
                value = (evenShare * 100).rounded() / 100
                runningTotal += value
            }

            paidAmountsText[person] = String(format: "%.2f", value)
        }
    }

    private func resetPaidAmountsForCurrentSelection() {
        let currentPeople = Set(effectivePaidByPeople)
        paidAmountsText = paidAmountsText.filter { currentPeople.contains($0.key) }

        let hasMissing = effectivePaidByPeople.contains { (paidAmountsText[$0] ?? "").isEmpty }
        if hasMissing || abs(totalPaidAmount - enteredAmount) > 0.01 {
            fillPaidAmountsEqually()
        }
    }

    private var groupYourPaidShare: Double {
        guard enteredAmount > 0 else { return 0 }
        return parsedPaidAmount(for: "YOU")
    }

    private var groupYourSplitShare: Double {
        guard enteredAmount > 0 else { return 0 }
        let splitters = max(effectiveSplitPeople.count, 1)
        return effectiveSplitPeople.contains("YOU") ? enteredAmount / Double(splitters) : 0
    }

    private var groupNetAmount: Double {
        groupYourPaidShare - groupYourSplitShare
    }

    private var customTitle: String {
        splitEquallySelected ? "Custom split" : selectedCustomOption.title
    }

    private var friendCalculatedAmount: Double {
        guard enteredAmount > 0 else { return 0 }

        if splitEquallySelected {
            return enteredAmount / Double(participantCount)
        }

        switch selectedCustomOption {
        case .youPaidSplitEqually, .theyPaidSplitEqually:
            return enteredAmount / Double(participantCount)
        case .youPaidTheyOweYouFull, .theyPaidYouOweFull:
            return enteredAmount
        }
    }

    private var friendDirection: BalanceDirection {
        if splitEquallySelected {
            return .owesYou
        }

        switch selectedCustomOption {
        case .youPaidSplitEqually, .youPaidTheyOweYouFull:
            return .owesYou
        case .theyPaidSplitEqually, .theyPaidYouOweFull:
            return .youOwe
        }
    }

    private var calculatedAmount: Double {
        isGroup ? abs(groupNetAmount) : friendCalculatedAmount
    }

    private var activeDirection: BalanceDirection {
        isGroup ? (groupNetAmount >= 0 ? .owesYou : .youOwe) : friendDirection
    }

    private var summaryText: String {
        let value = String(format: "%.2f", calculatedAmount)

        if isGroup {
            if groupNetAmount > 0 {
                return "You should get back $\(value)"
            } else if groupNetAmount < 0 {
                return "You owe $\(value)"
            } else {
                return "You are settled up"
            }
        }

        switch activeDirection {
        case .owesYou:
            return "They owe you $\(value)"
        case .youOwe:
            return "You owe $\(value)"
        }
    }

    private var summaryColor: Color {
        if calculatedAmount == 0 {
            return .gray
        }
        return activeDirection == .owesYou ? .green.opacity(0.9) : .red.opacity(0.85)
    }

    private var canSaveExpense: Bool {
        guard selectedItem != nil else { return false }
        guard !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard enteredAmount > 0 else { return false }

        if isGroup && !splitEquallySelected {
            return !effectivePaidByPeople.isEmpty &&
                !effectiveSplitPeople.isEmpty &&
                totalPaidAmountMatches
        }

        return true
    }

    private func saveExpense() {
        guard let selectedItem else { return }
        guard canSaveExpense else { return }

        let draft: GroupExpenseDraft? = isGroup ? GroupExpenseDraft(
            paidBy: effectivePaidByPeople,
            splitWith: effectiveSplitPeople,
            yourNetAmount: groupNetAmount,
            paidAmounts: paidAmountsDictionary
        ) : nil

        guard let image = receiptImage,
              let data = image.jpegData(compressionQuality: 0.6) else {
            onSaveExpense(
                selectedItem.id,
                descriptionText,
                calculatedAmount,
                activeDirection,
                draft,
                nil
            )
            resetAfterSave(for: selectedItem)
            return
        }

        isUploadingReceipt = true
        let expenseId = UUID().uuidString

        FirebaseService.shared.uploadReceiptImage(expenseId: expenseId, data: data) { result in
            DispatchQueue.main.async {
                isUploadingReceipt = false

                switch result {
                case .success(let url):
                    receiptURL = url
                    onSaveExpense(
                        selectedItem.id,
                        descriptionText,
                        calculatedAmount,
                        activeDirection,
                        draft,
                        url
                    )
                case .failure:
                    onSaveExpense(
                        selectedItem.id,
                        descriptionText,
                        calculatedAmount,
                        activeDirection,
                        draft,
                        nil
                    )
                }

                resetAfterSave(for: selectedItem)
            }
        }
    }

    private func resetAfterSave(for item: BalanceItem) {
        descriptionText = ""
        amountText = ""
        paidAmountsText = [:]
        receiptImage = nil
        receiptURL = ""
        selectedTab = item.kind == .group ? .friends : .home
    }
}

struct GroupMemberPickerSheet: View {
    let title: String
    let people: [String]
    @Binding var selectedPeople: Set<String>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppPalette.accentMid)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(people, id: \.self) { person in
                        Button {
                            toggle(person)
                        } label: {
                            HStack {
                                Text(person)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppPalette.primaryText)

                                Spacer()

                                Image(systemName: selectedPeople.contains(person) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPeople.contains(person) ? AppPalette.accentMid : AppPalette.secondaryText.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)

                        Divider()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .background(AppPalette.backgroundBottom)
    }

    private func toggle(_ person: String) {
        if selectedPeople.contains(person) {
            if selectedPeople.count > 1 {
                selectedPeople.remove(person)
            }
        } else {
            selectedPeople.insert(person)
        }
    }
}
