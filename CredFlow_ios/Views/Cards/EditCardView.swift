
import SwiftUI

struct EditCardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

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

                if showDeleteConfirm {
                    DeleteConfirmationOverlay(
                        title: loc.t("editCard.deleteTitle"),
                        message: loc.t("editCard.deleteMessage"),
                        isLoading: isLoading,
                        onDelete: { Task { await deleteCard() } },
                        onCancel: { showDeleteConfirm = false }
                    )
                    .zIndex(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            CreditCardWidget(card: previewCard)
                                .padding(.top, 16)

                            VStack(spacing: 20) {
                                // Section: Apparence
                                formSection(title: loc.t("addCard.appearance")) {
                                    VStack(spacing: 16) {
                                        // Couleur
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(loc.t("addCard.color"))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.secondary)
                                            colorPicker
                                        }

                                        Divider()

                                        // Réseau
                                        VStack(alignment: .leading, spacing: 10) {
                                            Text(loc.t("addCard.network"))
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(.secondary)
                                            Picker(loc.t("addCard.network"), selection: $network) {
                                                ForEach(CardNetwork.allCases, id: \.self) { n in
                                                    Text(n.displayName)
                                                        .font(.system(size: 13, weight: .thin))
                                                        .tag(n)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                                            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                                    )
                                }

                                // Section: Identité
                                formSection(title: loc.t("addCard.cardIdentity")) {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "text.cursor", isFocused: focusedField == .name) {
                                            TextField(loc.t("addCard.cardName"), text: $name)
                                                .focused($focusedField, equals: .name)
                                                .submitLabel(.next)
                                                .onSubmit { focusedField = .provider }
                                        }
                                        PremiumField(icon: "building.columns", isFocused: focusedField == .provider) {
                                            TextField(loc.t("addCard.bankProvider"), text: $provider)
                                                .focused($focusedField, equals: .provider)
                                                .submitLabel(.next)
                                                .onSubmit { focusedField = .lastFour }
                                        }
                                        PremiumField(icon: "number", isFocused: focusedField == .lastFour) {
                                            TextField(loc.t("addCard.lastFour"), text: $lastFour)
                                                .keyboardType(.numberPad)
                                                .focused($focusedField, equals: .lastFour)
                                                .onChange(of: lastFour) { _, new in
                                                    lastFour = String(new.filter(\.isNumber).prefix(4))
                                                }
                                        }
                                    }
                                }

                                // Section: Financier
                                formSection(title: loc.t("addCard.financialInfo")) {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "dollarsign", isFocused: focusedField == .limit) {
                                            TextField(loc.t("addCard.creditLimit"), text: $creditLimitText)
                                                .keyboardType(.decimalPad)
                                                .focused($focusedField, equals: .limit)
                                        }

                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 20)
                                            Text(loc.t("addCard.billingStart"))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Stepper("", value: $billingStartDay, in: 1...28)
                                                .labelsHidden()
                                            Text("\(loc.t("addCard.dayFormat")) \(billingStartDay)")
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

                                if let err = errorMessage {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill").font(.caption)
                                        Text(err).font(.caption)
                                    }
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }

                                // Delete button
                                PremiumOutlineButton(title: loc.t("editCard.deleteCard"), isDestructive: false) {
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
                        PremiumButton(title: loc.t("common.save"), isLoading: isLoading) {
                            Task { await updateCard() }
                        }
                        .padding(20)
                    }
                    .background(colorScheme == .dark ? Color(white: 0.08) : Color.white)
                }
            }
            .navigationTitle(loc.t("editCard.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                        .tint(Color.adaptiveBg(colorScheme))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showDeleteConfirm)
        }
    }

    @ViewBuilder
    private var colorPicker: some View {
        HStack(spacing: 16) {
            ForEach(0..<CardProvider.colorVariants.count, id: \.self) { i in
                let variant = CardProvider.colorVariants[i]
                let isSelected = colorIndex == i
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        colorIndex = i
                    }
                } label: {
                    Circle()
                        .fill(LinearGradient(
                            colors: [variant.top, variant.bottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .opacity(isSelected ? 1 : 0)
                                .scaleEffect(isSelected ? 1 : 0.5)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.adaptiveBg(colorScheme), lineWidth: isSelected ? 2.5 : 0)
                                .frame(width: 48, height: 48)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
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
            errorMessage = loc.t("editCard.errorFillAll")
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
