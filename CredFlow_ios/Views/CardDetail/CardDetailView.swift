
import SwiftUI

struct CardDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm: CardDetailViewModel
    @State private var editingExpense: Expense?

    var onCardUpdated: ((Card) -> Void)?
    var onCardDeleted: (() -> Void)?

    init(card: Card, onCardUpdated: ((Card) -> Void)? = nil, onCardDeleted: (() -> Void)? = nil) {
        _vm = State(initialValue: CardDetailViewModel(card: card))
        self.onCardUpdated = onCardUpdated
        self.onCardDeleted = onCardDeleted
    }

    private var cardBg: Color {
        colorScheme == .dark ? Color(white: 0.13) : Color.white
    }

    private var periodFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "fr_CA")
        return f
    }

    private func fmt(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private func fmtFull(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "CAD"
        f.locale = Locale(identifier: "fr_CA")
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PremiumBackground()

            ScrollView {
                VStack(spacing: 20) {

                    // ── Card widget ──────────────────────────────────
                    CreditCardWidget(card: vm.card)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // ── Stats ────────────────────────────────────────
                    statsSection

                    // ── Category filter ──────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterPill(label: "Tout", icon: nil, isSelected: vm.selectedCategory == nil) {
                                vm.selectedCategory = nil
                            }
                            ForEach(ExpenseCategory.allCases) { cat in
                                filterPill(label: cat.displayName, icon: cat.icon,
                                           isSelected: vm.selectedCategory == cat.rawValue) {
                                    vm.selectedCategory = vm.selectedCategory == cat.rawValue ? nil : cat.rawValue
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 2)
                    }

                    // ── Expense list ─────────────────────────────────
                    if vm.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)

                    } else if vm.filteredExpenses.isEmpty {
                        emptyState

                    } else {
                        VStack(spacing: 2) {
                            ForEach(vm.expensesByDate, id: \.date) { group in
                                let dailyTotal = group.expenses.reduce(0) { $0 + $1.amount }

                                // Date header + daily total
                                HStack(alignment: .firstTextBaseline) {
                                    Text(group.date, style: .date)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    Spacer()
                                    Text(fmtFull(dailyTotal))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                                .padding(.bottom, 6)

                                // Rows
                                VStack(spacing: 0) {
                                    ForEach(group.expenses) { expense in
                                        VStack(spacing: 0) {
                                            Button {
                                                editingExpense = expense
                                            } label: {
                                                ExpenseRow(expense: expense)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 11)
                                                    .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button {
                                                    Task { await vm.togglePaid(expense) }
                                                } label: {
                                                    Label(
                                                        expense.isPaid ? "Marquer non payé" : "Marquer comme payé",
                                                        systemImage: expense.isPaid ? "arrow.uturn.left.circle" : "checkmark.circle.fill"
                                                    )
                                                }
                                                Button(role: .destructive) {
                                                    Task { await vm.deleteExpense(expense) }
                                                } label: {
                                                    Label("Supprimer", systemImage: "trash")
                                                }
                                            }

                                            if expense.id != group.expenses.last?.id {
                                                Divider().padding(.leading, 64)
                                            }
                                        }
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(cardBg)
                                        .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 10, y: 2)
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, 100)
            }

            // ── FAB ─────────────────────────────────────────────
            Button {
                vm.showAddExpense = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.adaptiveFg(colorScheme))
                    .frame(width: 56, height: 56)
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
                Button {
                    vm.showEditCard = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.adaptiveBg(colorScheme))
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

    // MARK: - Stats section

    @ViewBuilder
    private var statsSection: some View {
        let period     = vm.billingPeriod
        let solde      = vm.solde
        let available  = vm.available
        let limit      = vm.card.creditLimit
        let count      = vm.filteredExpenses.count
        let progress   = limit > 0 ? min(solde / limit, 1.0) : 0

        VStack(spacing: 16) {

            // Three stats
            HStack(spacing: 0) {
                statCell(value: fmt(solde), label: "Solde")
                statDivider
                statCell(value: fmt(available), label: "Disponible")
                statDivider
                statCell(value: "\(count)", label: count == 1 ? "Dépense" : "Dépenses")
            }

            // Progress bar + period
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(height: 5)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.adaptiveBg(colorScheme))
                            .frame(width: geo.size.width * progress, height: 5)
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                }
                .frame(height: 5)

                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                    Text("\(periodFormatter.string(from: period.start)) – \(periodFormatter.string(from: period.end))")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(Int(progress * 100))% utilisé")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06), radius: 12, y: 3)
        )
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var statDivider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.15))
            .frame(width: 1, height: 36)
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.07))
                    .frame(width: 72, height: 72)
                Image(systemName: "tray")
                    .font(.system(size: 28, weight: .thin))
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 6) {
                Text("Aucune dépense")
                    .font(.system(size: 16, weight: .semibold))
                Text("Appuyez sur + pour enregistrer\nvotre première dépense")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
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
            .shadow(color: .black.opacity(isSelected ? 0.12 : 0.04), radius: 4, y: 1)
        }
    }
}
