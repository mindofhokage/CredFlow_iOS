# CredFlow iOS

Application iOS de gestion de cartes de crédit et de suivi des dépenses, construite avec SwiftUI et Supabase.

---

## Aperçu

CredFlow permet de suivre plusieurs cartes de crédit, d'enregistrer les dépenses par catégorie et de visualiser la consommation par période de facturation. L'interface est entièrement en français (locale `fr_CA`).

---

## Fonctionnalités

- **Authentification** — Inscription et connexion via Supabase Auth, restauration de session automatique au démarrage
- **Gestion des cartes** — Ajouter, modifier et supprimer des cartes de crédit avec prévisualisation en temps réel
- **Suivi des dépenses** — Enregistrer les dépenses par marchand, catégorie, date et note optionnelle
- **Période de facturation** — Calcul automatique de la période courante selon le jour de début configuré par carte
- **Barre de progression** — Visualisation du montant dépensé vs la limite, avec code couleur (vert / orange / rouge)
- **Filtrage par catégorie** — Filtre rapide des dépenses par catégorie depuis la vue détail d'une carte
- **Suppression par balayage** — Swipe-to-delete sur les dépenses

---

## Captures d'écran

> *(à compléter)*

---

## Tech Stack

| Composant | Technologie |
|---|---|
| Language | Swift 6+ |
| UI | SwiftUI (`@Observable`, `NavigationStack`) |
| Backend | [Supabase](https://supabase.com) (Auth + PostgreSQL) |
| SDK | [supabase-swift](https://github.com/supabase/supabase-swift) |
| Architecture | MVVM |
| Cible iOS | iOS 17+ |
| IDE | Xcode 16.3+ |

---

## Architecture

```
CredFlow_ios/
├── Config/
│   └── SupabaseConfig.swift        # URL et clé Supabase (à configurer)
├── Models/
│   ├── Card.swift                  # Modèle carte + CardNetwork enum
│   ├── Category.swift              # ExpenseCategory enum (10 catégories)
│   └── Expense.swift               # Modèle dépense
├── Services/
│   ├── SupabaseManager.swift       # Singleton client Supabase
│   ├── AuthService.swift           # Authentification (@Observable)
│   ├── CardService.swift           # CRUD cartes
│   └── ExpenseService.swift        # CRUD dépenses
├── ViewModels/
│   ├── AuthViewModel.swift         # État formulaire auth + validation
│   ├── DashboardViewModel.swift    # Liste des cartes
│   ├── CardDetailViewModel.swift   # Dépenses + filtres + période
│   └── AddExpenseViewModel.swift   # Formulaire ajout dépense
├── Views/
│   ├── AppRootView.swift           # Portail auth (Login ↔ Dashboard)
│   ├── Auth/                       # LoginView, SignUpView
│   ├── Dashboard/                  # DashboardView, CreditCardWidget
│   ├── Cards/                      # AddCardView, EditCardView
│   ├── CardDetail/                 # CardDetailView, ExpenseRow
│   ├── Expenses/                   # AddExpenseView
│   └── Components/                 # PremiumStyles, SpendingProgressBar, CategoryBadge
└── Utilities/
    └── BillingPeriod.swift         # Calcul de la période de facturation courante
```

**Flux de navigation :**

```
CredFlow_iosApp
  └── AppRootView  ──(non connecté)──► LoginView / SignUpView
                   ──(connecté)──────► DashboardView
                                         └── CardDetailView
                                               ├── AddExpenseView (sheet)
                                               └── EditCardView (sheet)
```

---

## Modèles de données

### Card

| Champ | Type | Description |
|---|---|---|
| `id` | UUID | Identifiant unique |
| `userId` | UUID | Utilisateur propriétaire |
| `name` | String | Surnom de la carte |
| `provider` | String | Émetteur (ex : Visa Desjardins) |
| `lastFour` | String | 4 derniers chiffres |
| `creditLimit` | Double | Limite de crédit (CAD) |
| `billingStartDay` | Int | Jour de début de cycle (1–28) |
| `network` | CardNetwork | `.visa`, `.mastercard`, `.amex` |
| `createdAt` | Date | Date de création |

### Expense

| Champ | Type | Description |
|---|---|---|
| `id` | UUID | Identifiant unique |
| `cardId` | UUID | Carte associée |
| `userId` | UUID | Utilisateur propriétaire |
| `amount` | Double | Montant (CAD) |
| `merchant` | String | Nom du marchand |
| `category` | String | Catégorie de la dépense |
| `date` | Date | Date de la transaction |
| `note` | String? | Note optionnelle |
| `createdAt` | Date | Date d'enregistrement |

### Catégories de dépenses

| Catégorie | Icône | Couleur |
|---|---|---|
| Alimentation | cart.fill | Orange |
| Restaurant | fork.knife | Rouge |
| Transport | car.fill | Bleu |
| Divertissement | tv.fill | Violet |
| Santé | cross.fill | Vert |
| Maison | house.fill | Marron |
| Voyages | airplane | Cyan |
| Shopping | bag.fill | Rose |
| Services | wrench.fill | Gris |
| Autre | ellipsis.circle.fill | Secondaire |

---

## Installation & Configuration

### Prérequis

- Xcode 16.3 ou supérieur
- Un projet [Supabase](https://supabase.com) actif

### 1. Cloner le dépôt

```bash
git clone https://github.com/mindofhokage/CredFlow_iOS.git
cd CredFlow_iOS
git checkout dev
```

### 2. Ajouter le package Supabase

Dans Xcode : **File → Add Package Dependencies**

```
https://github.com/supabase/supabase-swift
```

Sélectionner les modules : `Supabase`, `Auth`.

### 3. Configurer Supabase

Ouvrir `CredFlow_ios/Config/SupabaseConfig.swift` et remplacer les valeurs :

```swift
enum SupabaseConfig {
    static let url = URL(string: "https://<VOTRE_PROJECT_ID>.supabase.co")!
    static let anonKey = "<VOTRE_ANON_KEY>"
}
```

### 4. Créer les tables Supabase

Exécuter le SQL suivant dans l'éditeur SQL de votre projet Supabase :

```sql
-- Table des cartes
create table public.cards (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users not null,
  name          text not null,
  provider      text not null,
  last_four     text not null,
  credit_limit  numeric not null,
  billing_start_day int not null default 1,
  network       text not null default 'visa',
  created_at    timestamptz default now()
);

alter table public.cards enable row level security;
create policy "Users manage own cards" on public.cards
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Table des dépenses
create table public.expenses (
  id          uuid primary key default gen_random_uuid(),
  card_id     uuid references public.cards on delete cascade not null,
  user_id     uuid references auth.users not null,
  amount      numeric not null,
  merchant    text not null,
  category    text not null,
  date        date not null,
  note        text,
  created_at  timestamptz default now()
);

alter table public.expenses enable row level security;
create policy "Users manage own expenses" on public.expenses
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
```

### 5. Lancer l'application

Sélectionner un simulateur ou un appareil physique et appuyer sur **⌘ + R**.

---

## Branches Git

| Branche | Rôle |
|---|---|
| `dev` | Développement actif |
| `main` | *(à créer)* Production stable |

---

## Roadmap

- [ ] Résumé mensuel des dépenses (graphiques)
- [ ] Export CSV des dépenses
- [ ] Support multi-devises
- [ ] Notifications de dépassement de limite
- [ ] Widget iOS (WidgetKit)
- [ ] Tests unitaires et UI

---

## Licence

Ce projet est à usage personnel. Tous droits réservés.
