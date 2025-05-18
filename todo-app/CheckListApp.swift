//
//  CheckListApp.swift
//  CheckListApp
//
//  Created by Linh Nguyen on 18.05.2025.
//
import SwiftUI
import UserNotifications

@main
struct CheckListApp: App {
    let persistenceController = PersistenceController.shared
    
    init() {
        // Clear badges on app launch
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Clear badges when app appears
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    UNUserNotificationCenter.current().setBadgeCount(0, withCompletionHandler: nil)
                }
        }
    }
}
