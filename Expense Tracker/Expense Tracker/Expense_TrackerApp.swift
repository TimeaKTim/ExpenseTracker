//
//  Expense_TrackerApp.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import WidgetKit
import Firebase

@main
struct Expense_TrackerApp: App {
    init() {
            FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(for: [Transaction.self])
    }
}
