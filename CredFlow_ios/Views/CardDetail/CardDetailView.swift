
import SwiftUI

struct CardDetailView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm: CardDetailViewModel

    init(card: Card) {
        _vm = State(initialValue: CardDetailViewModel(card: card))
    }

    private var periodFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "fr_CA")
        return f
    }

    var body: some View {
        ZStack {
            PremiumBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Card widget
                    CreditCardWidget(card: vm.card)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Billing + progress
                    VStack(spacing: 14) {
                        let period = vm.billingPeriod
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Text("Période : \(periodFormatter.string(from: period.start)) → \(periodFormatter.string(from: period.end))")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        SpendingProgressBar(spent: vm.totalSpent, limit: vm.card.creditLimit)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
                    )
                    .padding(.horizontal, 20)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            filterPill(label: "Tout", icon: nil, color: .primary, isSelected: vm.selectedCategory == nil) {
                                vm.selectedCategory = nil
                            }
                            ForEach(ExpenseCategory.allCases) { cat in
                                filterPill(label: cat.displayName, icon: cat.icon, color: cat.color,
                                           isSelected: vm.selectedCategory == cat.rawValue) {
                                    vm.selectedCategory = vm.selectedCategory == cat.rawValue ? nil : cat.rawValue
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)
                    }

                    // Expense list
                    if vm.isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }.padding(.top, 32)
                    } else if vm.filteredExpenses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundStyle(.secondary)
                            Text("Aucune dépense")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 50)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(vm.expensesByDate, id: \.date) { group in
                                VStack(alignment: .leading, spacing: 0) {
                                    // Date header
                                    Text(group.date, style: .date)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                        .tracking(0.4)
                                        .padding(.horizontal, 16)
                                        .padding(.top, 14)
                                        .padding(.bottom, 8)

                                    // Expenses
                                    ForEach(group.expenses) { expense in
                                        VStack(spacing: 0) {
                                            ExpenseRow(expense: expense)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 4)
                                                .swipeActions(edge: .trailing) {
                                                    Button(role: .destructive) {
                                                        Task { await vm.deleteExpense(expense) }
                                                    } label: {
                                                        Label("Supprimer", systemImage: "trash")
                                                    }
                                                }
                                            if expense.id != group.expenses.last?.id {
                                                Divider().padding(.leading, 68)
                                            }
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                                        .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        vm.showAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.adaptiveFg(colorScheme))
                            .frame(width: 58, height: 58)
                            .background(Color.adaptiveBg(colorScheme))
                            .clipShape(Circle())
                            .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.3), radius: 12, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle(vm.card.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        .sheet(isPresented: $vm.showEditCard) {
            EditCardView(card: vm.card) { updated in vm.card = updated } onDeleted: {}
        }
        .task { await vm.loadExpenses() }
    }

    @ViewBuilder
    private func filterPill(label: String, icon: String?, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
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
                    ? (colorScheme == .dark ? Color.white : Color.black)
                    : (colorScheme == .dark ? Color(white: 0.18) : Color.white)
            )
            .foregroundStyle(
                isSelected
                    ? (colorScheme == .dark ? Color.black : Color.white)
                    : color
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(isSelected ? 0.15 : 0.05), radius: 4, y: 1)
        }
    }
}
