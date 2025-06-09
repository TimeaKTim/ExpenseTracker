//
//  Settings.swift
//  Expense Tracker
//
//  Created by Tímea Kónya on 10.02.2025.
//

import SwiftUI
import UserNotifications

struct Settings: View {
    /// User Properties
    @AppStorage("userName") private var userName: String = ""
    /// App Lock Properties
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("lockWhenAppGoesBackground") private var lockWhenAppGoesBackground: Bool = false
    @AppStorage("notificationEnabled") private var notificationEnabled: Bool = false
    @AppStorage("monthlyNotificationEnabled") private var monthlyNotificationEnabled: Bool = false
    var body: some View {
        NavigationStack {
            List {
                Section("User Name") {
                    TextField("", text: $userName)
                }
                
                Section("App Lock"){
                    Toggle("Enable App Lock", isOn: $isAppLockEnabled)
                    
                    if isAppLockEnabled {
                        Toggle("Lock When App Goes Background", isOn: $lockWhenAppGoesBackground)
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationEnabled)
                        .onChange(of: notificationEnabled) { _, newValue in
                            if newValue {
                                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
                                    if success {
                                        print("All set!")
                                    } else if let error = error {
                                        print(error.localizedDescription)
                                    }
                                }
                            }
                        }
                    
                    if notificationEnabled {
                        Toggle("Monthly Notification", isOn: $monthlyNotificationEnabled)
                                .onChange(of: monthlyNotificationEnabled) { _, newValue in
                                    if newValue {
                                        scheduleMonthlyNotification()
                                    } else {
                                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["monthly_notification"])
                                    }
                                }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}


func scheduleMonthlyNotification() {
    let content = UNMutableNotificationContent()
    content.title = "Expense Tracker"
    content.body = "Don't forget to track your expenses! Upload your receipts to the app to get a clear picture of your spendings."
    content.sound = .default

    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .hour, .minute], from: now)

    var monthlyDateComponents = DateComponents()
    monthlyDateComponents.day = components.day
    monthlyDateComponents.hour = components.hour ?? 9
    monthlyDateComponents.minute = components.minute ?? 0
    
    let immediateTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    let immediateRequest = UNNotificationRequest(
        identifier: "monthly_notification_now",
        content: content,
        trigger: immediateTrigger
    )

    let monthlyTrigger = UNCalendarNotificationTrigger(dateMatching: monthlyDateComponents, repeats: true)
    let monthlyRequest = UNNotificationRequest(
        identifier: "monthly_notification",
        content: content,
        trigger: monthlyTrigger
    )

    let center = UNUserNotificationCenter.current()
    center.add(immediateRequest) { error in
        if let error = error {
            print("Immediate notification error: \(error.localizedDescription)")
        }
    }

    center.add(monthlyRequest) { error in
        if let error = error {
            print("Monthly notification error: \(error.localizedDescription)")
        } else {
            print("Monthly notification scheduled.")
        }
    }
}

#Preview {
    ContentView()
}
