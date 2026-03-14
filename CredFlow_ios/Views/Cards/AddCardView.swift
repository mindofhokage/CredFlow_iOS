
import SwiftUI
internal import Auth

struct AddCardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

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
            name: name.isEmpty ? "Nom de la carte" : name,
            provider: provider.isEmpty ? "Banque" : provider,
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
                                // Section: Identité
                                formSection(title: "Identité de la carte") {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "text.cursor", isFocused: focusedField == .name) {
                                            TextField("Nom de la carte", text: $name)
                                                .focused($focusedField, equals: .name)
                                                .submitLabel(.next)
                                                .onSubmit { focusedField = .provider }
                                        }

                                        VStack(spacing: 8) {
                                            PremiumField(icon: "building.columns", isFocused: focusedField == .provider) {
                                                TextField("Banque / Prestataire", text: $providerQuery)
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
                                            TextField("4 derniers chiffres", text: $lastFour)
                                                .keyboardType(.numberPad)
                                                .focused($focusedField, equals: .lastFour)
                                                .onChange(of: lastFour) { _, new in
                                                    lastFour = String(new.filter(\.isNumber).prefix(4))
                                                }
                                        }
                                    }
                                }

                                // Section: Financier
                                formSection(title: "Informations financières") {
                                    VStack(spacing: 12) {
                                        PremiumField(icon: "dollarsign", isFocused: focusedField == .limit) {
                                            TextField("Limite de crédit", text: $creditLimitText)
                                                .keyboardType(.decimalPad)
                                                .focused($focusedField, equals: .limit)
                                        }

                                        // Billing day
                                        HStack {
                                            Image(systemName: "calendar.badge.clock")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 20)
                                            Text("Début de facturation")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Stepper("Jour \(billingStartDay)", value: $billingStartDay, in: 1...28)
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
                                                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                                                        radius: 8, y: 2)
                                        )
                                    }
                                }

                                // Section: Réseau
                                formSection(title: "Réseau de paiement") {
                                    Picker("Réseau", selection: $network) {
                                        ForEach(CardNetwork.allCases, id: \.self) { n in
                                            Text(n.displayName).tag(n)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }

                                // Section: Couleur
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
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Bottom button
                    VStack(spacing: 0) {
                        Divider()
                        PremiumButton(title: "Ajouter la carte", isLoading: isLoading) {
                            Task { await addCard() }
                        }
                        .padding(20)
                    }
                    .background(
                        colorScheme == .dark ? Color(white: 0.08) : Color.white
                    )
                }
            }
            .navigationTitle("Nouvelle carte")
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

    private func addCard() async {
        guard !name.isEmpty else { errorMessage = "Veuillez entrer un nom."; return }
        guard !provider.isEmpty else { errorMessage = "Veuillez entrer une banque."; return }
        guard lastFour.count == 4 else { errorMessage = "Entrez exactement 4 chiffres."; return }
        guard let limit = Double(creditLimitText), limit > 0 else {
            errorMessage = "Limite de crédit invalide."; return
        }
        guard let userId = authService.currentUser?.id.uuidString else {
            errorMessage = "Non authentifié."; return
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
