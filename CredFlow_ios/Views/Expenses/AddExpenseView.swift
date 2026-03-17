
import SwiftUI
internal import Auth

struct AddExpenseView: View {
    @Environment(AuthService.self) private var authService
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let card: Card
    var onSaved: () -> Void

    @State private var vm: AddExpenseViewModel
    @FocusState private var focusedField: Field?

    enum Field { case amount, merchant, note }

    init(card: Card, expense: Expense? = nil, onSaved: @escaping () -> Void) {
        self.card = card
        self.onSaved = onSaved
        _vm = State(initialValue: AddExpenseViewModel(expense: expense))
    }

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    private var billingPeriodRange: ClosedRange<Date> {
        let period = BillingPeriod.current(startDay: card.billingStartDay)
        return period.start...period.end
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                // Delete confirmation overlay
                if vm.showDeleteConfirm {
                    DeleteConfirmationOverlay(
                        title: loc.t("addExpense.deleteTitle"),
                        message: loc.t("addExpense.deleteMessage"),
                        isLoading: vm.isLoading,
                        onDelete: { Task { await deleteExpense() } },
                        onCancel: { vm.showDeleteConfirm = false }
                    )
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 24) {
                            Spacer().frame(height: 4)

                            // ── Amount ──────────────────────────────────
                            VStack(spacing: 4) {
                                HStack(alignment: .lastTextBaseline, spacing: 2) {
                                    Text("$")
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundStyle(.secondary)
                                    TextField("0,00", text: $vm.amountText)
                                        .font(.system(size: 64, weight: .bold))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .focused($focusedField, equals: .amount)
                                        .frame(maxWidth: 240)
                                }
                                .frame(maxWidth: .infinity)

                                HStack(spacing: 5) {
                                    Image(systemName: "creditcard")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                    Text("\(card.name)  ···· \(card.lastFour)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                            // ── Classification ─────────────────────────
                            VStack(alignment: .leading, spacing: 16) {
                                // Category
                                VStack(alignment: .leading, spacing: 10) {
                                    PremiumSectionLabel(title: loc.t("addExpense.category"))

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(ExpenseCategory.allCases) { cat in
                                                Button {
                                                    vm.selectedCategory = cat
                                                } label: {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: cat.icon)
                                                            .font(.system(size: 12))
                                                        Text(cat.displayName)
                                                            .font(.system(size: 13, weight: .medium))
                                                    }
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 9)
                                                    .background(
                                                        vm.selectedCategory == cat
                                                            ? Color.adaptiveBg(colorScheme)
                                                            : cardBg
                                                    )
                                                    .foregroundStyle(
                                                        vm.selectedCategory == cat
                                                            ? Color.adaptiveFg(colorScheme)
                                                            : Color.secondary
                                                    )
                                                    .clipShape(Capsule())
                                                    .shadow(
                                                        color: .black.opacity(vm.selectedCategory == cat ? 0.12 : 0.04),
                                                        radius: vm.selectedCategory == cat ? 6 : 4, y: 2
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }

                                Divider()

                                // Date
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    Text(loc.t("addExpense.date"))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    DatePicker("", selection: $vm.date, in: billingPeriodRange, displayedComponents: .date)
                                        .labelsHidden()
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBg)
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                            )
                            .padding(.horizontal, 20)

                            // ── Détails ─────────────────────────────────
                            VStack(alignment: .leading, spacing: 10) {
                                PremiumSectionLabel(title: loc.t("addExpense.details"))
                                    .padding(.horizontal, 20)

                                VStack(spacing: 0) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "storefront")
                                            .font(.system(size: 15))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        TextField(loc.t("addExpense.merchant"), text: $vm.merchant)
                                            .focused($focusedField, equals: .merchant)
                                            .submitLabel(.next)
                                            .onSubmit { focusedField = .note }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)

                                    Divider().padding(.leading, 48)

                                    HStack(spacing: 12) {
                                        Image(systemName: "note.text")
                                            .font(.system(size: 15))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        TextField(loc.t("addExpense.noteOptional"), text: $vm.note)
                                            .focused($focusedField, equals: .note)
                                            .submitLabel(.done)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(cardBg)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                                )
                                .padding(.horizontal, 20)
                            }

                            // ── Paid toggle (edit only) ──────────────────
                            if vm.isEditing {
                                Button {
                                    vm.isPaid.toggle()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: vm.isPaid ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(vm.isPaid ? Color.adaptiveFg(colorScheme) : .secondary)
                                        Text(loc.t("addExpense.paymentDone"))
                                            .font(.subheadline)
                                            .foregroundStyle(vm.isPaid ? Color.adaptiveFg(colorScheme) : .primary)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(vm.isPaid
                                                  ? Color.adaptiveBg(colorScheme)
                                                  : cardBg)
                                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                            }

                            // ── Error ────────────────────────────────────
                            if let err = vm.errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                    Text(err).font(.caption)
                                }
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 24)
                            }

                            // ── Delete (edit only) ────────────────────────
                            if vm.isEditing {
                                Button {
                                    vm.showDeleteConfirm = true
                                } label: {
                                    Text(loc.t("addExpense.deleteExpense"))
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // ── Bottom button ─────────────────────────────────
                    VStack(spacing: 0) {
                        Divider()
                        PremiumButton(
                            title: vm.isEditing ? loc.t("common.save") : loc.t("addExpense.addButton"),
                            isLoading: vm.isLoading
                        ) {
                            Task { await saveExpense() }
                        }
                        .padding(20)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
                }
            }
            .navigationTitle(vm.isEditing ? loc.t("addExpense.editTitle") : loc.t("addExpense.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                        .tint(Color.adaptiveBg(colorScheme))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: vm.showDeleteConfirm)
        }
    }

    private func saveExpense() async {
        guard let userId = authService.currentUser?.id.uuidString else {
            vm.errorMessage = loc.t("common.notAuthenticated")
            return
        }
        vm.isLoading = true; vm.errorMessage = nil
        defer { vm.isLoading = false }
        do {
            try await vm.save(cardId: card.id, userId: userId)
            onSaved()
            dismiss()
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }

    private func deleteExpense() async {
        vm.isLoading = true
        defer { vm.isLoading = false }
        do {
            try await vm.deleteExpense()
            onSaved()
            dismiss()
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}
