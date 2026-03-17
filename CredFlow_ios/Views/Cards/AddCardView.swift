
import SwiftUI
internal import Auth

struct AddCardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc

    var onCardAdded: (Card) -> Void

    @State private var name = ""
    @State private var provider = ""
    @State private var providerQuery = ""
    @State private var lastFour = ""
    @State private var creditLimitText = ""
    @State private var billingStartDay = 1
    @State private var network: CardNetwork = .visa
    @State private var colorIndex: Int = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showProviderSuggestions = false
    @FocusState private var focusedField: Field?

    enum Field { case name, provider, lastFour, limit }

    private var filteredProviders: [String] {
        guard !providerQuery.isEmpty else { return [] }
        return CardProvider.presetProviders.filter {
            $0.localizedCaseInsensitiveContains(providerQuery)
        }
    }

    private var previewCard: Card {
        Card(
            id: UUID(), userId: UUID(),
            name: name.isEmpty ? loc.t("addCard.previewName") : name,
            provider: provider.isEmpty ? loc.t("addCard.previewBank") : provider,
            lastFour: lastFour.isEmpty ? "0000" : String(lastFour.prefix(4)).padding(toLength: 4, withPad: "0", startingAt: 0),
            creditLimit: Double(creditLimitText) ?? 0,
            billingStartDay: billingStartDay,
            network: network,
            colorIndex: colorIndex,
            createdAt: .now
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Live card preview
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

                                        VStack(spacing: 8) {
                                            PremiumField(icon: "building.columns", isFocused: focusedField == .provider) {
                                                TextField(loc.t("addCard.bankProvider"), text: $providerQuery)
                                                    .focused($focusedField, equals: .provider)
                                                    .autocorrectionDisabled()
                                                    .onChange(of: providerQuery) { _, new in
                                                        provider = new
                                                        showProviderSuggestions = !new.isEmpty
                                                    }
                                            }

                                            if showProviderSuggestions && !filteredProviders.isEmpty {
                                                VStack(alignment: .leading, spacing: 0) {
                                                    ForEach(filteredProviders, id: \.self) { s in
                                                        Button {
                                                            provider = s
                                                            providerQuery = s
                                                            showProviderSuggestions = false
                                                        } label: {
                                                            Text(s)
                                                                .font(.subheadline)
                                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                                .padding(.horizontal, 16)
                                                                .padding(.vertical, 12)
                                                                .foregroundStyle(.primary)
                                                        }
                                                        if s != filteredProviders.last {
                                                            Divider().padding(.leading, 16)
                                                        }
                                                    }
                                                }
                                                .background(
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                                                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                                                )
                                            }
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

                                        // Billing day
                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 20)
                                            Text(loc.t("addCard.billingStart"))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Stepper("\(loc.t("addCard.dayFormat")) \(billingStartDay)", value: $billingStartDay, in: 1...28)
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
                                                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                                        radius: 8, y: 2)
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
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Bottom button
                    VStack(spacing: 0) {
                        Divider()
                        PremiumButton(title: loc.t("addCard.addButton"), isLoading: isLoading) {
                            Task { await addCard() }
                        }
                        .padding(20)
                    }
                    .background(
                        colorScheme == .dark ? Color(white: 0.08) : Color.white
                    )
                }
            }
            .navigationTitle(loc.t("addCard.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc.t("common.cancel")) { dismiss() }
                        .tint(Color.adaptiveBg(colorScheme))
                }
            }
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

    private func addCard() async {
        guard !name.isEmpty else { errorMessage = loc.t("addCard.errorName"); return }
        guard !provider.isEmpty else { errorMessage = loc.t("addCard.errorBank"); return }
        guard lastFour.count == 4 else { errorMessage = loc.t("addCard.errorFourDigits"); return }
        guard let limit = Double(creditLimitText), limit > 0 else {
            errorMessage = loc.t("addCard.errorInvalidLimit"); return
        }
        guard let userId = authService.currentUser?.id.uuidString else {
            errorMessage = loc.t("common.notAuthenticated"); return
        }
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let input = CardInput(userId: userId, name: name, provider: provider,
                                  lastFour: lastFour, creditLimit: limit,
                                  billingStartDay: billingStartDay, network: network.rawValue,
                                  colorIndex: colorIndex)
            let card = try await CardService.addCard(input)
            onCardAdded(card)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
