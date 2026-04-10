//
//  EditExpensePageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 4/9/26.
//

import SwiftUI

struct EditExpensePageView: View {
    let parentName: String
    let expense: ExpenseEntry
    let onSave: (String, Double, GroupExpenseDraft?) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var descriptionText: String
    @State private var amountText: String
    @State private var showDeleteConfirm = false

    @State private var selectedPaidByPeople: Set<String>
    @State private var selectedSplitPeople: Set<String>
    @State private var paidAmountsText: [String: String]

    @State private var showPaidByPicker = false
    @State private var showSplitPicker = false

    init(
        parentName: String,
        expense: ExpenseEntry,
        onSave: @escaping (String, Double, GroupExpenseDraft?) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.parentName = parentName
        self.expense = expense
        self.onSave = onSave
        self.onDelete = onDelete

        self._descriptionText = State(initialValue: expense.description)
        self._amountText = State(initialValue: String(format: "%.2f", expense.amount))
        self._selectedPaidByPeople = State(initialValue: Set(expense.paidBy.isEmpty ? ["YOU"] : expense.paidBy))
        self._selectedSplitPeople = State(initialValue: Set(expense.splitWith))
        self._paidAmountsText = State(
            initialValue: expense.paidAmounts.reduce(into: [String: String]()) { result, item in
                result[item.key] = String(format: "%.2f", item.value)
            }
        )
    }

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Edit Expense",
                subtitle: parentName,
                height: 118,
                backAction: {
                    dismiss()
                }
            ) {
                Button {
                    saveChanges()
                } label: {
                    Text("Save")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.20))
                        .clipShape(Capsule())
                        .opacity(canSave ? 1 : 0.65)
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                expenseInfoCard
                descriptionCard
                amountCard

                if isGroupExpense {
                    groupCustomCard
                    payerAmountsCard
                    summaryCard
                }

                deleteButton
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showPaidByPicker) {
            EditGroupMemberPickerSheet(
                title: "Paid by",
                people: availableGroupPeople,
                selectedPeople: $selectedPaidByPeople
            )
        }
        .sheet(isPresented: $showSplitPicker) {
            EditGroupMemberPickerSheet(
                title: "Split with",
                people: availableGroupPeople,
                selectedPeople: $selectedSplitPeople
            )
        }
        .confirmationDialog(
            "Delete Expense",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Expense", role: .destructive) {
                onDelete()
                dismiss()
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This expense will be removed and balances will be updated.")
        }
        .onChange(of: amountText) { _, _ in
            if isGroupExpense {
                resetPaidAmountsForCurrentSelection()
            }
        }
        .onChange(of: selectedPaidByPeople) { _, _ in
            if isGroupExpense {
                resetPaidAmountsForCurrentSelection()
            }
        }
    }

    private var isGroupExpense: Bool {
        expense.isEditableGroupExpense
    }

    private var availableGroupPeople: [String] {
        let storedMembers = expense.groupMemberNames
        if !storedMembers.isEmpty {
            return Array(Set(["YOU"] + storedMembers)).sorted()
        }

        let merged = Array(Set(expense.paidBy + expense.splitWith + ["YOU"]))
        return merged.sorted()
    }

    private var effectivePaidByPeople: [String] {
        let values = Array(selectedPaidByPeople)
        return values.isEmpty ? ["YOU"] : values.sorted()
    }

    private var effectiveSplitPeople: [String] {
        let values = Array(selectedSplitPeople)
        return values.sorted()
    }

    private var enteredAmount: Double {
        Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var totalPaidAmount: Double {
        effectivePaidByPeople.reduce(0) { $0 + parsedPaidAmount(for: $1) }
    }

    private var totalPaidAmountMatches: Bool {
        abs(totalPaidAmount - enteredAmount) < 0.01
    }

    private var groupYourPaidShare: Double {
        parsedPaidAmount(for: "YOU")
    }

    private var groupYourSplitShare: Double {
        let splitters = max(effectiveSplitPeople.count, 1)
        return effectiveSplitPeople.contains("YOU") ? enteredAmount / Double(splitters) : 0
    }

    private var groupNetAmount: Double {
        groupYourPaidShare - groupYourSplitShare
    }

    private var canSave: Bool {
        guard !descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard enteredAmount > 0 else { return false }

        if isGroupExpense {
            return !effectivePaidByPeople.isEmpty &&
                !effectiveSplitPeople.isEmpty &&
                totalPaidAmountMatches
        }

        return true
    }

    private var expenseInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Expense Date")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(expense.dateText)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppPalette.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 24))
    }

    private var descriptionCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppPalette.accentMid.opacity(0.10))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(AppPalette.accentMid)
                )

            VStack(alignment: .leading, spacing: 8) {
                TextField("Enter description", text: $descriptionText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)

                Rectangle()
                    .fill(AppPalette.border)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground(cornerRadius: 22))
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
                amountField
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppPalette.primaryText)

                Rectangle()
                    .fill(AppPalette.border)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground(cornerRadius: 22))
    }

    @ViewBuilder
    private var amountField: some View {
        #if os(iOS)
        TextField("Enter amount", text: $amountText)
            .keyboardType(.decimalPad)
        #else
        TextField("Enter amount", text: $amountText)
        #endif
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

            Text("You can add or remove people included in this expense.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground(cornerRadius: 22))
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

                    paidAmountField(for: person)
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
        .background(cardBackground(cornerRadius: 22))
    }

    @ViewBuilder
    private func paidAmountField(for person: String) -> some View {
        #if os(iOS)
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
        #else
        TextField("0.00", text: bindingForPaidAmount(person))
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
        #endif
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            if groupNetAmount > 0 {
                Text("You should get back $\(String(format: "%.2f", abs(groupNetAmount)))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.green.opacity(0.9))
            } else if groupNetAmount < 0 {
                Text("You owe $\(String(format: "%.2f", abs(groupNetAmount)))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.red.opacity(0.85))
            } else {
                Text("You are settled up")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 22))
    }

    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            Text("Delete Expense")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.red.opacity(0.88))
                )
        }
        .buttonStyle(.plain)
    }

    private var paidByTitle: String {
        let values = effectivePaidByPeople
        return values.count == 1 ? values[0] : "\(values.count) people"
    }

    private var splitTitle: String {
        let values = effectiveSplitPeople
        return values.count == 1 ? values[0] : "\(values.count) people"
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

    private func saveChanges() {
        guard canSave else { return }

        let cleanedDescription = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)

        if isGroupExpense {
            let draft = GroupExpenseDraft(
                paidBy: effectivePaidByPeople,
                splitWith: effectiveSplitPeople,
                yourNetAmount: groupNetAmount,
                paidAmounts: Dictionary(uniqueKeysWithValues: effectivePaidByPeople.map { ($0, parsedPaidAmount(for: $0)) })
            )
            onSave(cleanedDescription, enteredAmount, draft)
        } else {
            onSave(cleanedDescription, enteredAmount, nil)
        }

        dismiss()
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 6)
    }
}

struct EditGroupMemberPickerSheet: View {
    let title: String
    let people: [String]
    @Binding var selectedPeople: Set<String>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if people.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(AppPalette.secondaryText)

                        Text("No people available")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
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
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedPeople.contains(person) ? AppPalette.accentMid : AppPalette.secondaryText.opacity(0.5))
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(AppPalette.card)
                        }
                    }
                    .scrollContentBackground(.hidden)
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
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ person: String) {
        if selectedPeople.contains(person) {
            selectedPeople.remove(person)
        } else {
            selectedPeople.insert(person)
        }
    }
}
