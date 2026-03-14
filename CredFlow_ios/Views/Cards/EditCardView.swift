
import SwiftUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var card: Card
    var onUpdated: (Card) -> Void
    var onDeleted: () -> Void

    @State private var name: String
    @State private var provider: String
    @State private var lastFour: String
    @State private var creditLimitText: String
    @State private var billingStartDay: Int
    @State private var network: CardNetwork
    @State private var colorIndex: Int
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirm = false
    @FocusState private var focusedField: Field?

    enum Field { case name, provider, lastFour, limit }

    init(card: Card, onUpdated: @escaping (Card) -> Void, onDeleted: @escaping () -> Void) {
        self.card = card
        self.onUpdated = onUpdated
        self.onDeleted = onDeleted
        _name = State(initialValue: card.name)
        _provider = State(initialValue: card.provider)
        _lastFour = State(initialValue: card.lastFour)
        _creditLimitText = State(initialValue: String(card.creditLimit))
        _billingStartDay = State(initialValue: card.billingStartDay)
        _network = State(initialValue: card.network)
        _colorIndex = State(initialValue: card.colorIndex)
    }

    private var previewCard: Card {
        Card(id: card.id, userId: card.userId,
             name: name.isEmpty ? card.name : name,
             provider: provider.isEmpty ? card.provider : provider,
             lastFour: lastFour.isEmpty ? card.lastFour : String(lastFour.prefix(4)),
             creditLimit: Double(creditLimitText) ?? card.creditLimit,
             billingStartDay: billingStartDay, network: network,
             colorIndex: colorIndex, createdAt: card.createdAt)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            CreditCardWidget(card: previewCard)
                                .padding(.top, 16)

                            VStack(spacing: 20) {
                                formSection(title: "Identité de la carte") {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "text.cursor", isFocused: focusedField == .name) {
                                            TextField("Nom de la carte", text: $name)
                                                .focused($focusedField, equals: .name)
                                                .submitLabel(.next)
                                                .onSubmit { focusedField = .provider }
                                        }
                                        PremiumField(icon: "building.columns", isFocused: focusedField == .provider) {
                                            TextField("Banque / Prestataire", text: $provider)
                                                .focused($focusedField, equals: .provider)
                                                .submitLabel(.next)
                                                .onSubmit { focusedField = .lastFour }
                                        }
                                        PremiumField(icon: "number", isFocused: focusedField == .lastFour) {
                                            TextField("4 derniers chiffres", text: $lastFour)
                                                .keyboardType(.numberPad)
                                                .focused($focusedField, equals: .lastFour)
                                                .onChange(of: lastFour) { _, new in
                                                    lastFour = String(new.filter(\.isNumber).prefix(4))
                                                }
                                        }
                                    }
                                }

                                formSection(title: "Informations financières") {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "dollarsign", isFocused: focusedField == .limit) {
                                            TextField("Limite de crédit", text: $creditLimitText)
                                                .keyboardType(.decimalPad)
                                                .focused($focusedField, equals: .limit)
                                        }

                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 20)
                                            Text("Début de facturation")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Stepper("", value: $billingStartDay, in: 1...28)
                                                .labelsHidden()
                                            Text("Jour \(billingStartDay)")
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14)
                                                .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                                                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 8, y: 2)
                                        )
                                    }
                                }

                                formSection(title: "Réseau de paiement") {
                                    Picker("Réseau", selection: $network) {
                                        ForEach(CardNetwork.allCases, id: \.self) { n in
                                            Text(n.displayName).tag(n)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                formSection(title: "Couleur de la carte") {
                                    colorPicker
                                }

                                if let err = errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                        Text(err).font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // Delete button
                                PremiumOutlineButton(title: "Supprimer la carte", isDestructive: true) {
                                    showDeleteConfirm = true
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    VStack(spacing: 0) {
                        Divider()
                        PremiumButton(title: "Enregistrer", isLoading: isLoading) {
                            Task { await updateCard() }
                        }
                        .padding(20)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
                }
            }
            .navigationTitle("Modifier la carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                        .foregroundStyle(Color.adaptiveBg(colorScheme))
                }
            }
            .confirmationDialog("Supprimer cette carte ?",
                                isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("Supprimer", role: .destructive) { Task { await deleteCard() } }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Toutes les dépenses associées seront supprimées.")
            }
        }
    }

    @ViewBuilder
    private var colorPicker: some View {
        HStack(spacing: 12) {
            ForEach(0..<CardProvider.colorVariants.count, id: \.self) { i in
                let variant = CardProvider.colorVariants[i]
                Button {
                    colorIndex = i
                } label: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(
                            colors: [variant.top, variant.bottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(colorIndex == i ? Color.adaptiveBg(colorScheme) : Color.clear, lineWidth: 2.5)
                        )
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(colorIndex == i ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
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

    private func updateCard() async {
        guard !name.isEmpty, !provider.isEmpty, lastFour.count == 4,
              let limit = Double(creditLimitText), limit > 0 else {
            errorMessage = "Veuillez remplir tous les champs correctement."
            return
        }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        var updated = card
        updated.name = name; updated.provider = provider; updated.lastFour = lastFour
        updated.creditLimit = limit; updated.billingStartDay = billingStartDay
        updated.network = network; updated.colorIndex = colorIndex
        do {
            try await CardService.updateCard(updated)
            onUpdated(updated); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    private func deleteCard() async {
        isLoading = true; defer { isLoading = false }
        do {
            try await CardService.deleteCard(id: card.id)
            onDeleted(); dismiss()
        } catch { errorMessage = error.localizedDescription }
    }
}
