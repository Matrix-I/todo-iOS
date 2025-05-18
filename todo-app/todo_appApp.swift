//
//  todo_appApp.swift
//  todo-app
//
//  Created by Linh Nguyen on 18.05.2025.
//

import SwiftUI

@main
struct todo_appApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
