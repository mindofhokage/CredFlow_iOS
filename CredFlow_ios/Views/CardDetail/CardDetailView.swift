
import SwiftUI

struct CardDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    @State private var vm: CardDetailViewModel
    @State private var editingExpense: Expense?
    @State private var showSearch = false
    @FocusState private var searchFocused: Bool

    var onCardUpdated: ((Card) -> Void)?
    var onCardDeleted: (() -> Void)?
    var onDismiss: (() -> Void)?

    init(card: Card,
         onCardUpdated: ((Card) -> Void)? = nil,
         onCardDeleted: (() -> Void)? = nil,
         onDismiss: (() -> Void)? = nil) {
        _vm = State(initialValue: CardDetailViewModel(card: card))
        self.onCardUpdated = onCardUpdated
        self.onCardDeleted = onCardDeleted
        self.onDismiss = onDismiss
    }

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    private var periodFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = loc.locale
        return f
    }

    private func fmt(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = loc.locale
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func fmtFull(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = loc.locale
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PremiumBackground()

            ScrollView {
                VStack(spacing: 0) {

                    // ── Card widget ──────────────────────────────────
                    CreditCardWidget(card: vm.card)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 24)

                    // ── Stats hero ────────────────────────────────────
                    heroStatsSection
                        .padding(.bottom, 20)

                    // ── Search bar ────────────────────────────────────
                    if showSearch {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            TextField(loc.t("cardDetail.searchPlaceholder"), text: $vm.searchText)
                                .font(.system(size: 15))
                                .focused($searchFocused)
                                .submitLabel(.search)
                            if !vm.searchText.isEmpty {
                                Button {
                                    vm.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(cardBg)
                                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    // ── Category filter ───────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterPill(label: loc.t("cardDetail.all"), icon: nil, isSelected: vm.selectedCategory == nil) {
                                vm.selectedCategory = nil
                            }
                            ForEach(ExpenseCategory.allCases) { cat in
                                filterPill(label: cat.displayName, icon: cat.icon,
                                           isSelected: vm.selectedCategory == cat.rawValue) {
                                    vm.selectedCategory = vm.selectedCategory == cat.rawValue ? nil : cat.rawValue
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 2)
                    }
                    .padding(.bottom, 20)

                    // ── Expense list ──────────────────────────────────
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)

                    } else if vm.filteredExpenses.isEmpty {
                        emptyState

                    } else {
                        // Summary bar
                        let totalFiltered = vm.filteredExpenses.reduce(0) { $0 + $1.amount }
                        let paidCount = vm.filteredExpenses.filter(\.isPaid).count
                        let unpaidCount = vm.filteredExpenses.count - paidCount

                        HStack {
                            Text("\(vm.filteredExpenses.count) \(vm.filteredExpenses.count == 1 ? loc.t("cardDetail.expenseSingular").lowercased() : loc.t("cardDetail.expensePlural").lowercased())")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.tertiary)
                            Spacer()
                            if paidCount > 0 && unpaidCount > 0 {
                                HStack(spacing: 4) {
                                    Circle().fill(Color.adaptiveBg(colorScheme)).frame(width: 5, height: 5)
                                    Text("\(unpaidCount)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                    Text("·")
                                        .foregroundStyle(.quaternary)
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.tertiary)
                                    Text("\(paidCount)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Text(fmtFull(totalFiltered))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 10)

                        // Grouped expenses
                        VStack(spacing: 16) {
                            ForEach(vm.expensesByDate, id: \.date) { group in
                                let dailyTotal = group.expenses.reduce(0) { $0 + $1.amount }

                                VStack(spacing: 0) {
                                    // Date header inside card
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(group.date, style: .date)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.tertiary)
                                            .textCase(.uppercase)
                                            .tracking(1.0)
                                        Spacer()
                                        Text(fmtFull(dailyTotal))
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 14)
                                    .padding(.bottom, 10)

                                    // Thin separator
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.08))
                                        .frame(height: 1)
                                        .padding(.horizontal, 12)

                                    // Expense rows
                                    ForEach(Array(group.expenses.enumerated()), id: \.element.id) { idx, expense in
                                        SwipeableExpenseRow(expense: expense) {
                                            editingExpense = expense
                                        } onTogglePaid: {
                                            Task { await vm.togglePaid(expense) }
                                        } onDelete: {
                                            Task { await vm.deleteExpense(expense) }
                                        }

                                        if idx < group.expenses.count - 1 {
                                            Divider().padding(.leading, 64)
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(cardBg)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 12, y: 3)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal, 24)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 100)
            }
            .scrollDismissesKeyboard(.interactively)

            // ── FAB ─────────────────────────────────────────────
            Button {
                vm.showAddExpense = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.adaptiveFg(colorScheme))
                    .frame(width: 60, height: 60)
                    .background(Color.adaptiveBg(colorScheme))
                    .clipShape(Circle())
                    .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.25), radius: 14, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 28)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if onDismiss != nil {
                    Button {
                        onDismiss?()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text(loc.t("common.back"))
                                .font(.system(size: 16))
                        }
                        .foregroundStyle(Color.adaptiveBg(colorScheme))
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(vm.card.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text(vm.card.provider.uppercased())
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            showSearch.toggle()
                            if !showSearch {
                                vm.searchText = ""
                                searchFocused = false
                            } else {
                                searchFocused = true
                            }
                        }
                    } label: {
                        Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                    }
                    Button {
                        vm.showEditCard = true
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color.adaptiveBg(colorScheme))
                    }
                }
            }
        }
        .sheet(isPresented: $vm.showAddExpense) {
            AddExpenseView(card: vm.card) { Task { await vm.loadExpenses() } }
                .environment(authService)
        }
        .sheet(item: $editingExpense) { expense in
            AddExpenseView(card: vm.card, expense: expense) { Task { await vm.loadExpenses() } }
                .environment(authService)
        }
        .sheet(isPresented: $vm.showEditCard) {
            EditCardView(card: vm.card) { updated in
                vm.card = updated
                onCardUpdated?(updated)
            } onDeleted: {
                    onCardDeleted?()
                }
        }
        .task { await vm.loadExpenses() }
    }

    // MARK: - Hero Stats

    @ViewBuilder
    private var heroStatsSection: some View {
        let period     = vm.billingPeriod
        let solde      = vm.solde
        let available  = vm.available
        let limit      = vm.card.creditLimit
        let count      = vm.filteredExpenses.count
        let progress   = limit > 0 ? min(solde / limit, 1.0) : 0

        VStack(spacing: 0) {

            // ── Grand solde ────────────────────────────────────
            VStack(spacing: 6) {
                Text(loc.t("cardDetail.balance").uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)

                Text(fmtFull(solde))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: solde)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 18)

            // ── Progress bar ───────────────────────────────────
            VStack(spacing: 10) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.10))
                            .frame(height: 6)
                        Capsule()
                            .fill(Color.adaptiveBg(colorScheme))
                            .frame(width: max(geo.size.width * progress, 6), height: 6)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text(loc.t("cardDetail.percentUsed"))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text(fmt(solde))
                        .font(.system(size: 11, weight: .semibold))
                    Text(loc.t("dashboard.outOf"))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Text(fmt(limit))
                        .font(.system(size: 11, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            // ── Divider ────────────────────────────────────────
            Rectangle()
                .fill(Color.secondary.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // ── Period navigation ──────────────────────────────
            HStack {
                Button {
                    Task { await vm.goToPreviousPeriod() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("\(periodFormatter.string(from: period.start)) – \(periodFormatter.string(from: period.end))")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await vm.goToNextPeriod() }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(vm.isCurrentPeriod ? .quaternary : .secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(vm.isCurrentPeriod)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            // ── Divider ────────────────────────────────────────
            Rectangle()
                .fill(Color.secondary.opacity(0.10))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // ── Mini stats row ─────────────────────────────────
            HStack(spacing: 0) {
                miniStat(
                    icon: "arrow.up.right",
                    value: fmt(solde),
                    label: loc.t("cardDetail.balance")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 1, height: 32)

                miniStat(
                    icon: "creditcard",
                    value: fmt(available),
                    label: loc.t("cardDetail.available")
                )

                Rectangle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 1, height: 32)

                miniStat(
                    icon: "list.bullet",
                    value: "\(count)",
                    label: count == 1 ? loc.t("cardDetail.expenseSingular") : loc.t("cardDetail.expensePlural")
                )
            }
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBg)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 16, y: 4)
        )
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func miniStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        let isSearching = !vm.searchText.trimmingCharacters(in: .whitespaces).isEmpty
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.07))
                    .frame(width: 72, height: 72)
                Image(systemName: isSearching ? "magnifyingglass" : "tray")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                Text(isSearching ? loc.t("cardDetail.noResults") : loc.t("cardDetail.noExpenses"))
                    .font(.system(size: 16, weight: .semibold))
                if !isSearching {
                    Text(vm.isCurrentPeriod ? loc.t("cardDetail.tapPlusToAdd") : loc.t("cardDetail.noExpensesPast"))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Filter pill

    @ViewBuilder
    private func filterPill(label: String, icon: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon).font(.system(size: 11))
                }
                Text(label).font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.adaptiveBg(colorScheme)
                    : (colorScheme == .dark ? Color(white: 0.18) : Color.white)
            )
            .foregroundStyle(
                isSelected
                    ? Color.adaptiveFg(colorScheme)
                    : Color.secondary
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0.04), radius: 6, y: 2)
        }
    }
}

// MARK: - SwipeableExpenseRow

private struct SwipeableExpenseRow: View {
    @Environment(LocalizationManager.self) private var loc
    @Environment(\.colorScheme) private var colorScheme

    let expense: Expense
    let onTap: () -> Void
    let onTogglePaid: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var prevTranslation: CGFloat = 0

    private let actionWidth: CGFloat = 72

    var body: some View {
        ZStack(alignment: .trailing) {
            // Action révélée par le swipe
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
                onTogglePaid()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: expense.isPaid ? "arrow.uturn.left" : "checkmark")
                        .font(.system(size: 15, weight: .semibold))
                    Text(expense.isPaid ? loc.t("cardDetail.markUnpaid") : loc.t("cardDetail.markPaid"))
                        .font(.system(size: 9, weight: .medium))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .frame(width: actionWidth)
                .frame(maxHeight: .infinity)
            }
            .background(expense.isPaid ? Color(white: colorScheme == .dark ? 0.35 : 0.55) : Color.black)

            // Ligne principale
            ExpenseRow(expense: expense)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .contentShape(Rectangle())
                .background(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                .offset(x: offset)
                .onTapGesture {
                    if offset != 0 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
                    } else {
                        onTap()
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { value in
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            let delta = value.translation.width - prevTranslation
                            prevTranslation = value.translation.width
                            offset = min(0, max(offset + delta, -actionWidth))
                        }
                        .onEnded { value in
                            prevTranslation = 0
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                offset = offset < -(actionWidth / 2) ? -actionWidth : 0
                            }
                        }
                )
                .contextMenu {
                    Button {
                        onTogglePaid()
                    } label: {
                        Label(
                            expense.isPaid ? loc.t("cardDetail.markUnpaid") : loc.t("cardDetail.markPaid"),
                            systemImage: expense.isPaid ? "arrow.uturn.left.circle" : "checkmark.circle.fill"
                        )
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(loc.t("common.delete"), systemImage: "trash")
                    }
                }
        }
        .clipped()
        .onChange(of: expense.isPaid) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { offset = 0 }
        }
    }
}
