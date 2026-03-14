
import SwiftUI
internal import Auth

struct AddExpenseView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let card: Card
    var onExpenseAdded: () -> Void

    @State private var vm = AddExpenseViewModel()
    @FocusState private var focusedField: Field?

    enum Field { case amount, merchant, note }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            Spacer().frame(height: 8)

                            // Amount hero input
                            VStack(spacing: 6) {
                                Text("Montant")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("$")
                                        .font(.system(size: 36, weight: .thin))
                                        .foregroundStyle(.secondary)
                                    TextField("0,00", text: $vm.amountText)
                                        .font(.system(size: 56, weight: .black))
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.center)
                                        .focused($focusedField, equals: .amount)
                                        .frame(maxWidth: 220)
                                }

                                // Card indicator
                                HStack(spacing: 6) {
                                    Image(systemName: "creditcard.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                    Text(card.name)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                    Text("•••• \(card.lastFour)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                                    .shadow(color: .black.opacity(0.06), radius: 12, y: 3)
                            )
                            .padding(.horizontal, 20)

                            VStack(spacing: 20) {
                                // Merchant
                                formSection(title: "Marchand") {
                                    PremiumField(icon: "storefront", isFocused: focusedField == .merchant) {
                                        TextField("Ex: Carrefour, Netflix...", text: $vm.merchant)
                                            .focused($focusedField, equals: .merchant)
                                            .submitLabel(.next)
                                            .onSubmit { focusedField = .note }
                                    }
                                }

                                // Category
                                formSection(title: "Catégorie") {
                                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                                        ForEach(ExpenseCategory.allCases) { cat in
                                            Button {
                                                vm.selectedCategory = cat
                                            } label: {
                                                VStack(spacing: 5) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(vm.selectedCategory == cat
                                                                  ? cat.color
                                                                  : cat.color.opacity(0.12))
                                                            .frame(width: 46, height: 46)
                                                        Image(systemName: cat.icon)
                                                            .foregroundStyle(vm.selectedCategory == cat ? .white : cat.color)
                                                            .font(.system(size: 18))
                                                    }
                                                    .shadow(color: vm.selectedCategory == cat ? cat.color.opacity(0.4) : .clear,
                                                            radius: 6, y: 3)
                                                    Text(cat.displayName)
                                                        .font(.system(size: 9, weight: .medium))
                                                        .foregroundStyle(vm.selectedCategory == cat ? .primary : .secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                                            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                                    )
                                }

                                // Date
                                formSection(title: "Date") {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        DatePicker("", selection: $vm.date, displayedComponents: .date)
                                            .labelsHidden()
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 8, y: 2)
                                    )
                                }

                                // Note
                                formSection(title: "Note (optionnel)") {
                                    PremiumField(icon: "note.text", isFocused: focusedField == .note) {
                                        TextField("Commentaire...", text: $vm.note)
                                            .focused($focusedField, equals: .note)
                                    }
                                }

                                if let err = vm.errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                        Text(err).font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    VStack(spacing: 0) {
                        Divider()
                        PremiumButton(title: "Ajouter la dépense", isLoading: vm.isLoading) {
                            Task { await addExpense() }
                        }
                        .padding(20)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
                }
            }
            .navigationTitle("Nouvelle dépense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.adaptiveBg(colorScheme))
                }
            }
        }
    }

    @ViewBuilder
    private func formSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            PremiumSectionLabel(title: title)
            content()
        }
    }

    private func addExpense() async {
        guard let userId = authService.currentUser?.id.uuidString else {
            vm.errorMessage = "Non authentifié."
            return
        }
        vm.isLoading = true; vm.errorMessage = nil
        defer { vm.isLoading = false }
        do {
            try await vm.addExpense(cardId: card.id, userId: userId)
            onExpenseAdded()
            dismiss()
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }
}
