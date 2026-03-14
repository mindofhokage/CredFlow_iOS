
import SwiftUI

struct DashboardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = DashboardViewModel()
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PremiumBackground()

                ScrollView {

                    VStack(alignment: .leading, spacing: 28) {
                        // Header
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Bonjour 👋")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                            HStack(spacing: 0) {
                                Text("Mes ")
                                    .font(.system(size: 32, weight: .thin))
                                Text("Cartes")
                                    .font(.system(size: 32, weight: .black))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Summary pill
                        if !vm.cards.isEmpty {
                            HStack(spacing: 20) {
                                summaryPill(
                                    icon: "creditcard.fill",
                                    value: "\(vm.cards.count)",
                                    label: vm.cards.count > 1 ? "Cartes" : "Carte"
                                )
                                Divider().frame(height: 30)
                                summaryPill(
                                    icon: "calendar",
                                    value: currentMonthName(),
                                    label: "Période active"
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                                    .shadow(color: .black.opacity(0.05), radius: 10, y: 2)
                            )
                            .padding(.horizontal, 20)
                        }

                        // Cards
                        if vm.isLoading {
                            HStack { Spacer(); ProgressView(); Spacer() }.padding(.top, 40)
                        } else if vm.cards.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 16) {
                                ForEach(vm.cards) { card in
                                    Button {
                                        path.append(card)
                                    } label: {
                                        CreditCardWidget(card: card)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task { await vm.deleteCard(card) }
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        if let err = vm.errorMessage {
                            Text(err).font(.caption).foregroundStyle(.red)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .refreshable { await vm.loadCards() }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            vm.showAddCard = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.adaptiveFg(colorScheme))
                                .frame(width: 64, height: 64)
                                .background(Color.adaptiveBg(colorScheme))
                                .clipShape(Circle())
                                .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.35), radius: 16, y: 6)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Card.self) { card in
                CardDetailView(card: card)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 0) {
                        Text("Cred").font(.system(size: 20, weight: .thin))
                        Text("Flow").font(.system(size: 20, weight: .black))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Menu {
                            Button(role: .destructive) {
                                Task { try? await authService.signOut() }
                            } label: {
                                Label("Se déconnecter", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.title3)
                                .foregroundStyle(Color.adaptiveBg(colorScheme))
                        }
                    }
                }
            }
            .sheet(isPresented: $vm.showAddCard) {
                AddCardView { newCard in vm.cards.insert(newCard, at: 0) }
                    .environment(authService)
            }
        }
        .task { await vm.loadCards() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func summaryPill(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Text(value).font(.system(size: 15, weight: .semibold))
                Text(label).font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "creditcard")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(.secondary)
            Text("Aucune carte")
                .font(.headline)
            Text("Ajoutez votre première carte\nvia le bouton + en bas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private func currentMonthName() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        fmt.locale = Locale(identifier: "fr_CA")
        return fmt.string(from: .now).capitalized
    }
}
