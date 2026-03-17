//
//  CredFlow_iosApp.swift
//  CredFlow_ios
//
//  Created by Kevin Kombate on 2026-03-14.
//

import SwiftUI

@main
struct CredFlow_iosApp: App {
    @State private var localization = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(localization)
        }
    }
}
