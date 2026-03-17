
import Foundation
import SwiftUI

// MARK: - Language

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case fr = "fr"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .fr: return "Français"
        }
    }

    var flag: String {
        switch self {
        case .en: return "🇬🇧"
        case .fr: return "🇫🇷"
        }
    }

    var locale: Locale {
        switch self {
        case .en: return Locale(identifier: "en_CA")
        case .fr: return Locale(identifier: "fr_CA")
        }
    }
}

// MARK: - Manager

@Observable
@MainActor
final class LocalizationManager {
    static let shared = LocalizationManager()

    private let key = "credflow_app_language"

    var currentLanguage: AppLanguage {
        didSet { UserDefaults.standard.set(currentLanguage.rawValue, forKey: key) }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: key),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            self.currentLanguage = preferred.hasPrefix("fr") ? .fr : .en
        }
    }

    func t(_ key: String) -> String {
        guard let entry = Translations.all[key] else {
            #if DEBUG
            print("⚠️ Missing key: \(key)")
            #endif
            return key
        }
        return entry[currentLanguage] ?? key
    }

    var locale: Locale { currentLanguage.locale }
}

// MARK: - Translations

struct Translations {
    static let all: [String: [AppLanguage: String]] = [

        // ─── Common ─────────────────────────────────────────
        "common.cancel":            [.fr: "Annuler",          .en: "Cancel"],
        "common.save":              [.fr: "Enregistrer",      .en: "Save"],
        "common.delete":            [.fr: "Supprimer",        .en: "Delete"],
        "common.close":             [.fr: "Fermer",           .en: "Close"],
        "common.confirm":           [.fr: "Confirmer",        .en: "Confirm"],
        "common.or":                [.fr: "ou",               .en: "or"],
        "common.password":          [.fr: "Mot de passe",     .en: "Password"],
        "common.email":             [.fr: "Adresse e-mail",   .en: "Email address"],
        "common.notAuthenticated":  [.fr: "Non authentifié.", .en: "Not authenticated."],

        // ─── App ────────────────────────────────────────────
        "app.tagline":              [.fr: "Votre gestionnaire de crédit", .en: "Your credit manager"],

        // ─── Biometric ──────────────────────────────────────
        "biometric.unlockFaceID":      [.fr: "Déverrouiller avec Face ID",  .en: "Unlock with Face ID"],
        "biometric.unlockTouchID":     [.fr: "Déverrouiller avec Touch ID", .en: "Unlock with Touch ID"],
        "biometric.secureAccess":      [.fr: "Accès sécurisé",              .en: "Secure access"],
        "biometric.useFaceIDAccess":   [.fr: "Utilisez Face ID pour accéder à CredFlow",  .en: "Use Face ID to access CredFlow"],
        "biometric.useTouchIDAccess":  [.fr: "Utilisez Touch ID pour accéder à CredFlow", .en: "Use Touch ID to access CredFlow"],
        "biometric.authFailed":        [.fr: "Authentification échouée. Réessayez.",       .en: "Authentication failed. Try again."],
        "biometric.unlockReason":      [.fr: "Déverrouillez CredFlow",      .en: "Unlock CredFlow"],
        "biometric.accessReason":      [.fr: "Accédez à CredFlow",          .en: "Access CredFlow"],

        // ─── Login ──────────────────────────────────────────
        "login.quickAccess":         [.fr: "Accès rapide",       .en: "Quick access"],
        "login.useFaceIDInstant":    [.fr: "Utilisez Face ID pour vous connecter instantanément",
                                      .en: "Use Face ID to sign in instantly"],
        "login.useTouchIDInstant":   [.fr: "Utilisez Touch ID pour vous connecter instantanément",
                                      .en: "Use Touch ID to sign in instantly"],
        "login.continueFaceID":      [.fr: "Continuer avec Face ID",  .en: "Continue with Face ID"],
        "login.continueTouchID":     [.fr: "Continuer avec Touch ID", .en: "Continue with Touch ID"],
        "login.section":             [.fr: "Connexion",               .en: "Sign in"],
        "login.signIn":              [.fr: "Se connecter",            .en: "Sign in"],
        "login.createAccount":       [.fr: "Créer un compte",        .en: "Create an account"],

        // ─── SignUp ─────────────────────────────────────────
        "signup.subtitle":           [.fr: "Créez votre compte gratuitement", .en: "Create your account for free"],
        "signup.confirmPassword":    [.fr: "Confirmer le mot de passe",       .en: "Confirm password"],
        "signup.createAccount":      [.fr: "Créer un compte",                 .en: "Create an account"],
        "signup.checkEmail":         [.fr: "Vérifiez votre e-mail",           .en: "Check your email"],
        "signup.confirmationSent":   [.fr: "Un lien de confirmation a été envoyé à",
                                      .en: "A confirmation link has been sent to"],
        "signup.clickAndReturn":     [.fr: "Cliquez dessus puis revenez vous connecter.",
                                      .en: "Click it then come back to sign in."],
        "signup.backToLogin":        [.fr: "Retour à la connexion",  .en: "Back to sign in"],

        // ─── Dashboard ──────────────────────────────────────
        "dashboard.my":              [.fr: "Mes ",    .en: "My "],
        "dashboard.cards":           [.fr: "Cartes",  .en: "Cards"],
        "dashboard.myCards":         [.fr: "Mes cartes",    .en: "My cards"],
        "dashboard.collapse":        [.fr: "Réduire",       .en: "Collapse"],
        "dashboard.viewAll":         [.fr: "Tout voir",     .en: "View all"],
        "dashboard.totalLimit":      [.fr: "Limite totale", .en: "Total limit"],
        "dashboard.cardSingular":    [.fr: "Carte",         .en: "Card"],
        "dashboard.cardPlural":      [.fr: "Cartes",        .en: "Cards"],
        "dashboard.activePeriod":    [.fr: "Période active", .en: "Active period"],
        "dashboard.secured":         [.fr: "Sécurisé",      .en: "Secured"],
        "dashboard.noCards":         [.fr: "Aucune carte",   .en: "No cards"],
        "dashboard.addFirstCard":    [.fr: "Ajoutez votre première carte de crédit\npour suivre vos dépenses",
                                      .en: "Add your first credit card\nto track your expenses"],
        "dashboard.addCard":         [.fr: "Ajouter une carte", .en: "Add a card"],
        "dashboard.deleteTitle":     [.fr: "Supprimer la carte ?", .en: "Delete card?"],
        "dashboard.deleteMessage":   [.fr: "Toutes les dépenses associées seront également supprimées. Cette action est irréversible.",
                                      .en: "All associated expenses will also be deleted. This action cannot be undone."],

        // ─── AddCard ────────────────────────────────────────
        "addCard.title":             [.fr: "Nouvelle carte",           .en: "New card"],
        "addCard.appearance":        [.fr: "Apparence",                .en: "Appearance"],
        "addCard.color":             [.fr: "Couleur",                  .en: "Color"],
        "addCard.network":           [.fr: "Réseau",                   .en: "Network"],
        "addCard.cardIdentity":      [.fr: "Identité de la carte",    .en: "Card identity"],
        "addCard.cardName":          [.fr: "Nom de la carte",         .en: "Card name"],
        "addCard.bankProvider":      [.fr: "Banque / Prestataire",    .en: "Bank / Provider"],
        "addCard.lastFour":          [.fr: "4 derniers chiffres",     .en: "Last 4 digits"],
        "addCard.financialInfo":     [.fr: "Informations financières", .en: "Financial information"],
        "addCard.creditLimit":       [.fr: "Limite de crédit",        .en: "Credit limit"],
        "addCard.billingStart":      [.fr: "Début de facturation",    .en: "Billing start"],
        "addCard.addButton":         [.fr: "Ajouter la carte",        .en: "Add card"],
        "addCard.previewName":       [.fr: "Nom de la carte",         .en: "Card name"],
        "addCard.previewBank":       [.fr: "Banque",                  .en: "Bank"],
        "addCard.errorName":         [.fr: "Veuillez entrer un nom.", .en: "Please enter a name."],
        "addCard.errorBank":         [.fr: "Veuillez entrer une banque.", .en: "Please enter a bank."],
        "addCard.errorFourDigits":   [.fr: "Entrez exactement 4 chiffres.", .en: "Enter exactly 4 digits."],
        "addCard.errorInvalidLimit": [.fr: "Limite de crédit invalide.",    .en: "Invalid credit limit."],
        "addCard.dayFormat":         [.fr: "Jour",  .en: "Day"],

        // ─── EditCard ───────────────────────────────────────
        "editCard.title":            [.fr: "Modifier la carte",           .en: "Edit card"],
        "editCard.deleteCard":       [.fr: "Supprimer la carte",          .en: "Delete card"],
        "editCard.deleteTitle":      [.fr: "Supprimer cette carte ?",     .en: "Delete this card?"],
        "editCard.deleteMessage":    [.fr: "Toutes les dépenses associées seront supprimées.",
                                      .en: "All associated expenses will be deleted."],
        "editCard.errorFillAll":     [.fr: "Veuillez remplir tous les champs correctement.",
                                      .en: "Please fill in all fields correctly."],

        // ─── CardDetail ─────────────────────────────────────
        "cardDetail.balance":        [.fr: "Solde",       .en: "Balance"],
        "cardDetail.available":      [.fr: "Disponible",  .en: "Available"],
        "cardDetail.expenseSingular":[.fr: "Dépense",     .en: "Expense"],
        "cardDetail.expensePlural":  [.fr: "Dépenses",    .en: "Expenses"],
        "cardDetail.percentUsed":    [.fr: "utilisé",     .en: "used"],
        "cardDetail.all":            [.fr: "Tout",        .en: "All"],
        "cardDetail.markUnpaid":     [.fr: "Marquer non payé",     .en: "Mark as unpaid"],
        "cardDetail.markPaid":       [.fr: "Marquer comme payé",   .en: "Mark as paid"],
        "cardDetail.noExpenses":     [.fr: "Aucune dépense",       .en: "No expenses"],
        "cardDetail.tapPlusToAdd":   [.fr: "Appuyez sur + pour enregistrer\nvotre première dépense",
                                      .en: "Tap + to record\nyour first expense"],

        // ─── AddExpense ─────────────────────────────────────
        "addExpense.title":          [.fr: "Nouvelle dépense",    .en: "New expense"],
        "addExpense.editTitle":      [.fr: "Modifier",            .en: "Edit"],
        "addExpense.category":       [.fr: "Catégorie",           .en: "Category"],
        "addExpense.date":           [.fr: "Date",                .en: "Date"],
        "addExpense.details":        [.fr: "Détails",             .en: "Details"],
        "addExpense.merchant":       [.fr: "Marchand",            .en: "Merchant"],
        "addExpense.noteOptional":   [.fr: "Note (optionnel)",    .en: "Note (optional)"],
        "addExpense.paymentDone":    [.fr: "Paiement effectué",   .en: "Payment made"],
        "addExpense.deleteExpense":  [.fr: "Supprimer la dépense",    .en: "Delete expense"],
        "addExpense.addButton":      [.fr: "Ajouter la dépense",     .en: "Add expense"],
        "addExpense.deleteTitle":    [.fr: "Supprimer la dépense ?",  .en: "Delete expense?"],
        "addExpense.deleteMessage":  [.fr: "Cette action est irréversible.", .en: "This action cannot be undone."],
        "addExpense.errorAmount":    [.fr: "Montant invalide.",           .en: "Invalid amount."],
        "addExpense.errorMerchant":  [.fr: "Veuillez entrer un marchand.", .en: "Please enter a merchant."],

        // ─── Profile ────────────────────────────────────────
        "profile.my":                [.fr: "Mon ",    .en: "My "],
        "profile.profile":           [.fr: "Profil",  .en: "Profile"],
        "profile.activeAccount":     [.fr: "Compte actif",  .en: "Active account"],
        "profile.securityPrivacy":   [.fr: "Sécurité & Confidentialité", .en: "Security & Privacy"],
        "profile.changePassword":    [.fr: "Changer le mot de passe",    .en: "Change password"],
        "profile.changeEmail":       [.fr: "Changer l'adresse e-mail",   .en: "Change email address"],
        "profile.language":          [.fr: "Langue",        .en: "Language"],
        "profile.information":       [.fr: "Informations",  .en: "Information"],
        "profile.version":           [.fr: "Version",       .en: "Version"],
        "profile.platform":          [.fr: "Plateforme",    .en: "Platform"],
        "profile.developer":         [.fr: "Développeur",   .en: "Developer"],
        "profile.signOut":           [.fr: "Se déconnecter", .en: "Sign out"],
        "profile.enableFaceID":      [.fr: "Activer Face ID",  .en: "Enable Face ID"],
        "profile.enableTouchID":     [.fr: "Activer Touch ID", .en: "Enable Touch ID"],
        "profile.faceIDPrompt":      [.fr: "Entrez votre mot de passe pour sauvegarder vos identifiants de façon sécurisée.",
                                      .en: "Enter your password to securely save your credentials."],
        "profile.enterPasswordError":[.fr: "Veuillez entrer votre mot de passe.", .en: "Please enter your password."],
        "profile.wrongPassword":     [.fr: "Mot de passe incorrect.",             .en: "Incorrect password."],

        // ─── ChangePassword ─────────────────────────────────
        "changePassword.title":          [.fr: "Mot de passe",               .en: "Password"],
        "changePassword.newSection":     [.fr: "Nouveau mot de passe",       .en: "New password"],
        "changePassword.newPlaceholder": [.fr: "Nouveau mot de passe",       .en: "New password"],
        "changePassword.confirmPlaceholder": [.fr: "Confirmer le mot de passe", .en: "Confirm password"],
        "changePassword.success":        [.fr: "Mot de passe mis à jour avec succès.", .en: "Password updated successfully."],
        "changePassword.errorEmpty":     [.fr: "Veuillez entrer un nouveau mot de passe.", .en: "Please enter a new password."],
        "changePassword.errorMismatch":  [.fr: "Les mots de passe ne correspondent pas.", .en: "Passwords do not match."],
        "changePassword.errorMinLength": [.fr: "Le mot de passe doit contenir au moins 6 caractères.",
                                          .en: "Password must be at least 6 characters."],

        // ─── ChangeEmail ────────────────────────────────────
        "changeEmail.title":         [.fr: "Adresse e-mail",             .en: "Email address"],
        "changeEmail.currentSection":[.fr: "Adresse actuelle",           .en: "Current address"],
        "changeEmail.newSection":    [.fr: "Nouvelle adresse",           .en: "New address"],
        "changeEmail.newPlaceholder":[.fr: "Nouvelle adresse e-mail",    .en: "New email address"],
        "changeEmail.success":       [.fr: "Un lien de confirmation a été envoyé à votre nouvelle adresse.",
                                      .en: "A confirmation link has been sent to your new address."],
        "changeEmail.errorEmpty":    [.fr: "Veuillez entrer une nouvelle adresse e-mail.", .en: "Please enter a new email address."],
        "changeEmail.errorInvalid":  [.fr: "Adresse e-mail invalide.",   .en: "Invalid email address."],
        "changeEmail.updateButton":  [.fr: "Mettre à jour",             .en: "Update"],

        // ─── Auth Validation ────────────────────────────────
        "auth.fillAllFields":        [.fr: "Veuillez remplir tous les champs.", .en: "Please fill in all fields."],
        "auth.passwordsMismatch":    [.fr: "Les mots de passe ne correspondent pas.", .en: "Passwords do not match."],
        "auth.passwordMinLength":    [.fr: "Le mot de passe doit contenir au moins 6 caractères.",
                                      .en: "Password must be at least 6 characters."],

        // ─── Categories ─────────────────────────────────────
        "category.alimentation":     [.fr: "Alimentation",    .en: "Groceries"],
        "category.restaurant":       [.fr: "Restaurant",      .en: "Dining"],
        "category.transport":        [.fr: "Transport",       .en: "Transport"],
        "category.divertissement":   [.fr: "Divertissement",  .en: "Entertainment"],
        "category.sante":            [.fr: "Santé",           .en: "Health"],
        "category.maison":           [.fr: "Maison",          .en: "Home"],
        "category.voyages":          [.fr: "Voyages",         .en: "Travel"],
        "category.shopping":         [.fr: "Shopping",        .en: "Shopping"],
        "category.services":         [.fr: "Services",        .en: "Services"],
        "category.autre":            [.fr: "Autre",           .en: "Other"],

        // ─── SpendingProgressBar ────────────────────────────
        "spending.outOf":            [.fr: "sur",   .en: "of"],
    ]
}
