//
// Page used to save a settlement for a selected friend.
//
//
//  SettleUpPageView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 3/24/26.
//

import SwiftUI

struct SettleUpPageView: View {
    let friend: BalanceItem
    let onBack: () -> Void
    let onSave: (String, Double, String) -> Void

    @State private var amountText: String = ""
    @State private var selectedMethod: String = ""
    @State private var showMethodPicker = false

    private let themePurple = AppPalette.accentMid

    var body: some View {
        FixedHeaderScrollContainer(headerHeight: 118) {
            CurvedBackHeader(
                title: "Settle Up",
                subtitle: friend.name,
                height: 118,
                backAction: {
                    onBack()
                }
            ) {
                Button {
                    saveSettle()
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
                friendCard
                outstandingCard
                amountCard
                paymentMethodCard
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .confirmationDialog("Payment Method", isPresented: $showMethodPicker, titleVisibility: .visible) {
            Button("Cash") { selectedMethod = "Cash" }
            Button("Transfer") { selectedMethod = "Transfer" }
            Button("Cancel", role: .cancel) { }
        }
        .onAppear {
            amountText = String(format: "%.2f", friend.amount)
        }
    }

    private var friendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friend")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(friend.name)
                .font(.system(size: 28, weight: .bold))
                .italic()
                .foregroundColor(AppPalette.primaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 24))
    }

    private var outstandingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Outstanding")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppPalette.secondaryText)

            Text(balanceText)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(friend.direction == .owesYou ? .green.opacity(0.85) : .red.opacity(0.85))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground(cornerRadius: 24))
    }

    private var amountCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(AppPalette.rowIconBg)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "dollarsign.square.fill")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundColor(themePurple)
                )

            VStack(alignment: .leading, spacing: 8) {
                Text("Enter amount")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)

                settlementAmountField

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
    private var settlementAmountField: some View {
        #if os(iOS)
        TextField("Enter amount", text: $amountText)
            .keyboardType(.decimalPad)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppPalette.primaryText)
        #else
        TextField("Enter amount", text: $amountText)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppPalette.primaryText)
        #endif
    }

    private var paymentMethodCard: some View {
        Button {
            showMethodPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Payment Method")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppPalette.secondaryText)

                    Text(selectedMethod.isEmpty ? "Choose payment method" : selectedMethod)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(selectedMethod.isEmpty ? AppPalette.secondaryText : AppPalette.primaryText)
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .foregroundColor(AppPalette.secondaryText)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(cardBackground(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private var enteredAmount: Double {
        Double(amountText.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
    }

    private var balanceText: String {
        let value = String(format: "%.2f", friend.amount)
        return friend.direction == .owesYou ? "They owe you $\(value)" : "You owe $\(value)"
    }

    private func saveSettle() {
        guard canSave else { return }
        onSave(friend.id, enteredAmount, selectedMethod)
    }

    private var canSave: Bool {
        enteredAmount > 0 && !selectedMethod.isEmpty
    }

    private func cardBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}
