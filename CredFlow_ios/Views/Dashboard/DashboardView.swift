
import SwiftUI
internal import Auth

struct DashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var vm = DashboardViewModel()
    @State private var isStackExpanded = false
    @State private var showProfile = false
    @State private var cardToDelete: Card?
    @State private var pressedCardId: UUID?
    @State private var showHeader = false
    @State private var showHero = false
    @State private var showCards = false
    @State private var showFAB = false
    @State private var selectedCard: Card?
    @State private var fabGlow = false

    private let cardH: CGFloat = 216
    private let peekH: CGFloat = 62
    private let expandedGap: CGFloat = 16

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    var body: some View {
        ZStack {
            // ── Main dashboard ──────────────────────────────────
            NavigationStack {
                ZStack {
                    PremiumBackground()

                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {

                            // ── Header ───────────────────────────────────────
                            if showHeader {
                                headerSection
                                    .padding(.horizontal, 24)
                                    .padding(.top, 8)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            // ── Hero balance ─────────────────────────────────
                            if showHero, !vm.cards.isEmpty {
                                heroBalanceSection
                                    .padding(.horizontal, 24)
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            // ── Cards ────────────────────────────────────────
                            if vm.isLoading {
                                HStack { Spacer(); ProgressView(); Spacer() }
                                    .padding(.top, 40)
                            } else if vm.cards.isEmpty {
                                if showCards {
                                    emptyState
                                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                                }
                            } else if showCards {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        PremiumSectionLabel(title: loc.t("dashboard.myCards"))
                                        Spacer()
                                        if vm.cards.count > 1 {
                                            Button {
                                                withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                                                    isStackExpanded.toggle()
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(isStackExpanded ? loc.t("dashboard.collapse") : loc.t("dashboard.viewAll"))
                                                        .font(.system(size: 12, weight: .medium))
                                                    Image(systemName: isStackExpanded ? "chevron.up" : "chevron.down")
                                                        .font(.system(size: 10, weight: .semibold))
                                                }
                                                .foregroundStyle(Color.adaptiveBg(colorScheme))
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 24)

                                    stackedCardsSection
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }

                            if let err = vm.errorMessage {
                                Text(err).font(.caption).foregroundStyle(.red)
                                    .padding(.horizontal, 24)
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
                            if showFAB {
                                Button { vm.showAddCard = true } label: {
                                    ZStack {
                                        // Glow pulse
                                        Circle()
                                            .fill(Color.adaptiveBg(colorScheme).opacity(0.15))
                                            .frame(width: 80, height: 80)
                                            .scaleEffect(fabGlow ? 1.15 : 0.9)
                                            .opacity(fabGlow ? 0 : 0.5)

                                        Image(systemName: "plus")
                                            .font(.system(size: 22, weight: .semibold))
                                            .foregroundStyle(Color.adaptiveFg(colorScheme))
                                            .frame(width: 60, height: 60)
                                            .background(Color.adaptiveBg(colorScheme))
                                            .clipShape(Circle())
                                            .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.25), radius: 16, y: 6)
                                            .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.10), radius: 4, y: 2)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                                .padding(.trailing, 24)
                                .padding(.bottom, 32)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: false)) {
                                        fabGlow = true
                                    }
                                }
                            }
                        }
                    }

                    // ── Delete confirmation ──────────────────────────────
                    if cardToDelete != nil {
                        DeleteConfirmationOverlay(
                            title: loc.t("dashboard.deleteTitle"),
                            message: loc.t("dashboard.deleteMessage"),
                            isLoading: vm.isLoading,
                            onDelete: {
                                Task {
                                    if let card = cardToDelete {
                                        await vm.deleteCard(card)
                                        cardToDelete = nil
                                    }
                                }
                            },
                            onCancel: { cardToDelete = nil }
                        )
                        .zIndex(10)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: cardToDelete != nil)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Image("credflow_logo")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 24)
                            HStack(spacing: 0) {
                                Text("Cred").font(.system(size: 18, weight: .thin))
                                Text("Flow").font(.system(size: 18, weight: .black))
                            }
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
            // ── Card detail overlay ─────────────────────────────
            if let card = selectedCard {
                NavigationStack {
                    CardDetailView(
                        card: card,
                        onCardUpdated: { updated in
                            vm.updateCard(updated)
                            selectedCard = updated
                        },
                        onCardDeleted: {
                            vm.cards.removeAll { $0.id == card.id }
                            dismissDetail()
                        },
                        onDismiss: dismissDetail
                    )
                    .environment(authService)
                }
                .zIndex(5)
                .transition(.move(edge: .trailing))
            }
        }
        .task {
            await vm.loadCards()
            withAnimation(.snappy(duration: 0.3)) { showHeader = true }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.snappy(duration: 0.3)) { showHero = true }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.snappy(duration: 0.3)) { showCards = true }
            try? await Task.sleep(for: .milliseconds(80))
            withAnimation(.snappy(duration: 0.35)) { showFAB = true }
        }
    }

    // MARK: - Navigate to detail

    private func openCard(_ card: Card) {
        withAnimation(.snappy(duration: 0.35)) {
            selectedCard = card
        }
    }

    private func dismissDetail() {
        withAnimation(.snappy(duration: 0.35)) {
            selectedCard = nil
        }
    }

    // MARK: - Header

    private var userFirstName: String {
        if !authService.firstName.isEmpty {
            return authService.firstName
        }
        guard let email = authService.currentUser?.email else { return "" }
        let local = email.components(separatedBy: "@").first ?? ""
        return local.prefix(1).uppercased() + local.dropFirst()
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currentDateString())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(1.2)
            HStack(spacing: 6) {
                Text(loc.t("dashboard.hello"))
                    .font(.system(size: 28, weight: .thin))
                Text(userFirstName)
                    .font(.system(size: 28, weight: .black))
            }
        }
    }

    // MARK: - Hero Balance

    @ViewBuilder
    private var heroBalanceSection: some View {
        let progress = vm.totalLimit > 0 ? min(vm.totalSpent / vm.totalLimit, 1.0) : 0

        VStack(spacing: 0) {

            // ── Ring gauge + solde ──────────────────────────────
            ZStack {
                // Track
                Circle()
                    .stroke(Color.secondary.opacity(0.08), lineWidth: 8)
                    .frame(width: 150, height: 150)

                // Progress arc
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.adaptiveBg(colorScheme),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                // Center content
                VStack(spacing: 2) {
                    Text(fmtCurrencyFull(vm.totalSpent))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.4), value: vm.totalSpent)

                    Text(loc.t("dashboard.outOf") + " " + fmtCurrency(vm.totalLimit))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 24)

            // ── Divider ─────────────────────────────────────────
            Rectangle()
                .fill(Color.secondary.opacity(0.08))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // ── Stats row ───────────────────────────────────────
            HStack(spacing: 0) {
                miniStat(
                    icon: "arrow.up.right",
                    value: fmtCurrency(vm.totalSpent),
                    label: loc.t("dashboard.totalSpent")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 1, height: 36)

                miniStat(
                    icon: "creditcard",
                    value: fmtCurrency(vm.totalAvailable),
                    label: loc.t("dashboard.totalAvailable")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 1, height: 36)

                miniStat(
                    icon: "shield.checkered",
                    value: "\(vm.cards.count)",
                    label: vm.cards.count == 1 ? loc.t("dashboard.cardSingular") : loc.t("dashboard.cardPlural")
                )
            }
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(colorScheme == .dark
                      ? Color(white: 0.13).opacity(0.7)
                      : Color.white.opacity(0.7))
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.12 : 0.6),
                                    Color.white.opacity(colorScheme == .dark ? 0.04 : 0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 20, y: 6)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.03), radius: 4, y: 2)
        )
    }

    @ViewBuilder
    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.adaptiveBg(colorScheme).opacity(0.08))
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.adaptiveBg(colorScheme))
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
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
                        .scaleEffect(pressedCardId == card.id ? 0.95 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: pressedCardId)
                        .onTapGesture {
                            if n == 1 || isStackExpanded {
                                openCard(card)
                            } else {
                                withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                                    isStackExpanded = true
                                }
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.45) {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            cardToDelete = card
                        } onPressingChanged: { pressing in
                            pressedCardId = pressing ? card.id : nil
                        }
                        .animation(.spring(response: 0.42, dampingFraction: 0.80), value: isStackExpanded)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity).combined(with: .offset(y: 30)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.78), value: vm.cards.count)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 28) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(cardBg)
                    .frame(width: 88, height: 88)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
                Image(systemName: "creditcard")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text(loc.t("dashboard.noCards"))
                    .font(.system(size: 18, weight: .semibold))
                Text(loc.t("dashboard.addFirstCard"))
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
                    Text(loc.t("dashboard.addCard"))
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
        f.locale = loc.locale
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func fmtCurrencyFull(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = loc.locale
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func currentDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE d MMMM"
        fmt.locale = loc.locale
        return fmt.string(from: .now)
    }
}
