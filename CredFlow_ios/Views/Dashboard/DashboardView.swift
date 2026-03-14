
import SwiftUI

struct DashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = DashboardViewModel()
    @State private var path = NavigationPath()
    @State private var isStackExpanded = false
    @State private var showProfile = false

    private let cardH: CGFloat = 216
    private let peekH: CGFloat = 62
    private let expandedGap: CGFloat = 16

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PremiumBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // ── Header ───────────────────────────────────────
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 4)

                        // ── Stats ────────────────────────────────────────
                        if !vm.cards.isEmpty {
                            statsSection
                                .padding(.horizontal, 20)
                        }

                        // ── Cards ────────────────────────────────────────
                        if vm.isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }
                                .padding(.top, 40)
                        } else if vm.cards.isEmpty {
                            emptyState
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                // Section label
                                HStack {
                                    PremiumSectionLabel(title: "Mes cartes")
                                    Spacer()
                                    if vm.cards.count > 1 {
                                        Button {
                                            withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                                                isStackExpanded.toggle()
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(isStackExpanded ? "Réduire" : "Tout voir")
                                                    .font(.system(size: 12, weight: .medium))
                                                Image(systemName: isStackExpanded ? "chevron.up" : "chevron.down")
                                                    .font(.system(size: 10, weight: .semibold))
                                            }
                                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)

                                stackedCardsSection
                            }
                        }

                        if let err = vm.errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.loadCards() }

                // ── FAB ──────────────────────────────────────────────────
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button { vm.showAddCard = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.adaptiveFg(colorScheme))
                                .frame(width: 60, height: 60)
                                .background(Color.adaptiveBg(colorScheme))
                                .clipShape(Circle())
                                .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.30), radius: 14, y: 5)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card) { updated in
                    vm.updateCard(updated)
                } onCardDeleted: {
                    vm.cards.removeAll { $0.id == card.id }
                    path.removeLast()
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 20, weight: .thin))
                        Text("Flow").font(.system(size: 20, weight: .black))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                    }
                }
            }
            .sheet(isPresented: $vm.showAddCard) {
                AddCardView { newCard in vm.cards.insert(newCard, at: 0) }
                    .environment(authService)
            }
            .sheet(isPresented: $showProfile) {
                ProfileView().environment(authService)
            }
        }
        .task { await vm.loadCards() }
    }

    // MARK: - Header

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentDateString())
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.5)
            HStack(spacing: 0) {
                Text("Mes ")
                    .font(.system(size: 30, weight: .thin))
                Text("Cartes")
                    .font(.system(size: 30, weight: .black))
            }
        }
    }

    // MARK: - Stats

    @ViewBuilder
    private var statsSection: some View {
        let totalLimit = vm.cards.reduce(0.0) { $0 + $1.creditLimit }
        let cardBg = colorScheme == .dark ? Color(white: 0.13) : Color.white

        VStack(spacing: 14) {
            HStack(spacing: 0) {
                statCell(
                    value: fmtCurrency(totalLimit),
                    label: "Limite totale"
                )
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1, height: 36)
                statCell(
                    value: "\(vm.cards.count)",
                    label: vm.cards.count > 1 ? "Cartes" : "Carte"
                )
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 1, height: 36)
                statCell(
                    value: currentMonthName(),
                    label: "Période active"
                )
            }

            // Active cards indicator dots
            HStack(spacing: 5) {
                ForEach(0..<vm.cards.count, id: \.self) { i in
                    Capsule()
                        .fill(Color.adaptiveBg(colorScheme).opacity(isStackExpanded || i == 0 ? 1.0 : 0.25))
                        .frame(width: isStackExpanded || i == 0 ? 16 : 6, height: 4)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isStackExpanded)
                }
                Spacer()
                Image(systemName: "lock.shield")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                Text("Sécurisé")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, y: 3)
        )
    }

    @ViewBuilder
    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Stacked Cards

    @ViewBuilder
    private var stackedCardsSection: some View {
        let n = vm.cards.count

        VStack(spacing: 10) {
            ZStack(alignment: .top) {
                ForEach(Array(vm.cards.enumerated().reversed()), id: \.element.id) { idx, card in
                    let i = CGFloat(idx)
                    let topPad = isStackExpanded
                        ? (cardH + expandedGap) * i
                        : peekH * i

                    CreditCardWidget(card: card)
                        .padding(.top, topPad)
                        .onTapGesture {
                            if n == 1 || isStackExpanded {
                                path.append(card)
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                                    isStackExpanded = true
                                }
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                Task { await vm.deleteCard(card) }
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                        .animation(.spring(response: 0.42, dampingFraction: 0.80), value: isStackExpanded)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                Image(systemName: "creditcard")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text("Aucune carte")
                    .font(.system(size: 18, weight: .semibold))
                Text("Ajoutez votre première carte de crédit\npour suivre vos dépenses")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            Button {
                vm.showAddCard = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Ajouter une carte")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(Color.adaptiveFg(colorScheme))
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Color.adaptiveBg(colorScheme))
                .clipShape(Capsule())
                .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.25), radius: 10, y: 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func fmtCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func currentMonthName() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        fmt.locale = Locale(identifier: "fr_CA")
        return fmt.string(from: .now).capitalized
    }

    private func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE d MMMM"
        fmt.locale = Locale(identifier: "fr_CA")
        return fmt.string(from: .now)
    }
}
