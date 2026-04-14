//
//  AddExpensePageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//
// This page is used to add a new expense for either a friend or a group.
// Different UI parts are shown depending on the selected item.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct AddExpensePageView: View {
    let selectedItem: BalanceItem?
    let availableFriends: [BalanceItem]
    let onSaveExpense: (
        String,
        String,
        Double,
        BalanceDirection,
        GroupExpenseDraft?,
        String?,
        String,
        String,
        Double?,
        Double?
    ) -> Void

    let onAddMembersToGroup: (BalanceItem, [BalanceItem]) -> Void
    let onDeleteGroup: (BalanceItem) -> Void
    let onBack: (() -> Void)?
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

    @State private var showAddMembersSheet = false
    @State private var selectedNewMemberIDs: Set<String> = []
    @State private var showDeleteGroupConfirm = false
    
    @State private var locationNameText: String = ""
    @State private var locationAddressText: String = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil

    #if os(iOS)
    @State private var receiptImage: UIImage?
    #endif
    @State private var showReceiptPicker = false
    @State private var receiptURL: String = ""
    @State private var isUploadingReceipt = false

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Add Expense",
                subtitle: withName.isEmpty ? "Add a new expense" : withName,
                height: 118,
                backAction: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        if let onBack {
                            onBack()
                        } else {
                            selectedTab = .friends
                        }
                    }
                }
            ) {
                // ✅ UPDATED: Save button moved to header
                Button {
                    saveExpense()
                } label: {
                    HStack(spacing: 6) {
                        if isUploadingReceipt {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        }

                        Text("Save")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.20))
                    .clipShape(Capsule())
                    .opacity(canSaveExpense ? 1 : 0.6)
                }
                .buttonStyle(.plain)
                .disabled(!canSaveExpense || isUploadingReceipt)
            }
        } content: {
            VStack(alignment: .leading, spacing: 18) {
                nameCard
                cameraCard
                

                inputCard(
                    icon: "bag",
                    placeholder: "Enter description",
                    text: $descriptionText
                    
                )
                locationCard

                amountCard
                splitButtonsSection

                if isGroup && !splitEquallySelected {
                    payerAmountsCard
                }

                if isGroup {
                    groupManagementCard
                }

                if enteredAmount > 0 {
                    summaryCard
                }

                Spacer(minLength: 140)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
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
        .sheet(isPresented: $showAddMembersSheet) {
            AddGroupMembersSheet(
                availableFriends: addableFriends,
                selectedFriendIDs: $selectedNewMemberIDs,
                onSave: addSelectedMembers
            )
        }
        #if os(iOS)
        .sheet(isPresented: $showReceiptPicker) {
            ImagePicker(image: $receiptImage)
        }
        #endif
        .confirmationDialog(
            "Delete Group",
            isPresented: $showDeleteGroupConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete Group", role: .destructive) {
                deleteCurrentGroup()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This group will be deleted from your app and database.")
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
            withName = selectedItem?.name ?? ""
            #if os(iOS)
            receiptImage = nil
            #endif
            receiptURL = ""
            isUploadingReceipt = false
            selectedNewMemberIDs = []
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

    private var addableFriends: [BalanceItem] {
        guard let selectedItem, selectedItem.kind == .group else { return [] }
        let existingNames = Set(selectedItem.memberNames)
        return availableFriends.filter { !existingNames.contains($0.name) }
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
        .background(cardBackground(cornerRadius: 24))
    }

    private var cameraCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Receipt")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            #if os(iOS)
            Button {
                showReceiptPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: receiptButtonIcon)
                        .font(.system(size: 16, weight: .bold))

                    Text(receiptButtonTitle)
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [AppPalette.accentStart, AppPalette.accentEnd],
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
            #else
            HStack(spacing: 10) {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .bold))

                Text("Receipt image upload is available on iOS")
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundColor(AppPalette.secondaryText)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(AppPalette.rowIconBg)
            )
            #endif
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 24))
    }

    #if os(iOS)
    private var receiptButtonIcon: String {
        receiptImage == nil ? "camera.fill" : "checkmark.circle.fill"
    }

    private var receiptButtonTitle: String {
        receiptImage == nil ? "Take a picture / choose image" : "Receipt selected"
    }
    #endif

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
        .background(cardBackground(cornerRadius: 22))
    }
    private var locationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            inputCard(
                icon: "mappin.and.ellipse",
                placeholder: "Store, restaurant, or trip location",
                text: $locationNameText
            )

            TextField("Optional address / area", text: $locationAddressText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppPalette.searchField)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppPalette.border, lineWidth: 1)
                        )
                )
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
                amountTextField
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
    private var amountTextField: some View {
        #if os(iOS)
        TextField("Enter amount", text: $amountText)
            .keyboardType(.decimalPad)
        #else
        TextField("Enter amount", text: $amountText)
        #endif
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
                            colors: [AppPalette.accentStart, AppPalette.accentEnd],
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

    private var groupManagementCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manage Group")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppPalette.primaryText)

            Button {
                selectedNewMemberIDs = []
                showAddMembersSheet = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(AppPalette.accentMid.opacity(0.12))
                            .frame(width: 50, height: 50)

                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppPalette.accentMid)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Members")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)

                        Text("Add friends who are not already in this group")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppPalette.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppPalette.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(groupActionBackground)
            }
            .buttonStyle(.plain)
            .disabled(addableFriends.isEmpty)
            .opacity(addableFriends.isEmpty ? 0.6 : 1)

            Button {
                showDeleteGroupConfirm = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.red.opacity(0.12))
                            .frame(width: 50, height: 50)

                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red.opacity(0.9))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Group")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)

                        Text("Delete this group from app and database")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppPalette.secondaryText)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(AppPalette.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(groupActionBackground)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(cardBackground(cornerRadius: 22))
    }

    private var groupActionBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(AppPalette.searchField)
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
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

            Text(summaryText)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(summaryColor)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 22))
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

    private func addSelectedMembers() {
        guard let selectedItem, selectedItem.kind == .group else { return }

        let newMembers = addableFriends.filter { selectedNewMemberIDs.contains($0.id) }
        guard !newMembers.isEmpty else { return }

        onAddMembersToGroup(selectedItem, newMembers)
        showAddMembersSheet = false
        selectedNewMemberIDs = []
    }

    private func deleteCurrentGroup() {
        guard let selectedItem, selectedItem.kind == .group else { return }
        onDeleteGroup(selectedItem)
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

        let amountToSave = isGroup ? enteredAmount : calculatedAmount

        #if os(iOS)
        if let image = receiptImage,
           let data = image.jpegData(compressionQuality: 0.6) {
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
                            amountToSave,
                            activeDirection,
                            draft,
                            url,
                            locationNameText.trimmingCharacters(in: .whitespacesAndNewlines),
                            locationAddressText.trimmingCharacters(in: .whitespacesAndNewlines),
                            latitude,
                            longitude
                        )
                    case .failure:
                        onSaveExpense(
                            selectedItem.id,
                            descriptionText,
                            amountToSave,
                            activeDirection,
                            draft,
                            nil,
                            locationNameText.trimmingCharacters(in: .whitespacesAndNewlines),
                            locationAddressText.trimmingCharacters(in: .whitespacesAndNewlines),
                            latitude,
                            longitude
                        )
                        resetAfterSave()
                    }
                }
                return
            }
        }
        #endif

            onSaveExpense(
                selectedItem.id,
                descriptionText,
                amountToSave,
                activeDirection,
                draft,
                nil,
                locationNameText.trimmingCharacters(in: .whitespacesAndNewlines),
                locationAddressText.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude,
                longitude
            )
        resetAfterSave()
    }

    private func resetAfterSave() {
        descriptionText = ""
        amountText = ""
        locationNameText = ""
        locationAddressText = ""
        latitude = nil
        longitude = nil
        paidAmountsText = [:]
        #if os(iOS)
        receiptImage = nil
        #endif
        receiptURL = ""
    }
}

struct GroupMemberPickerSheet: View {
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

struct AddGroupMembersSheet: View {
    let availableFriends: [BalanceItem]
    @Binding var selectedFriendIDs: Set<String>
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if availableFriends.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(AppPalette.secondaryText)

                        Text("No more friends to add")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppPalette.primaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(availableFriends) { friend in
                            Button {
                                toggle(friend.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(AppPalette.accentMid.opacity(0.15))
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            Text(String(friend.name.prefix(1)))
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(AppPalette.accentMid)
                                        )

                                    Text(friend.name)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(AppPalette.primaryText)

                                    Spacer()

                                    Image(systemName: selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedFriendIDs.contains(friend.id) ? AppPalette.accentMid : AppPalette.secondaryText.opacity(0.5))
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
            .navigationTitle("Add Members")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(selectedFriendIDs.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func toggle(_ id: String) {
        if selectedFriendIDs.contains(id) {
            selectedFriendIDs.remove(id)
        } else {
            selectedFriendIDs.insert(id)
        }
    }
}
