import SwiftUI
import UserNotifications

struct NotificationsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading notifications...")
                } else if notificationManager.notifications.isEmpty {
                    Text("No pending notifications")
                        .foregroundColor(.secondary)
                } else {
                    List {
                        ForEach(notificationManager.notifications, id: \.identifier) { notification in
                            VStack(alignment: .leading) {
                                Text(notification.content.title)
                                    .font(.headline)
                                if !notification.content.body.isEmpty {
                                    Text(notification.content.body)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if let trigger = notification.trigger as? UNCalendarNotificationTrigger,
                                   let nextTriggerDate = trigger.nextTriggerDate() {
                                    Text("Scheduled: \(nextTriggerDate, style: .date) at \(nextTriggerDate, style: .time)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: removeNotifications)
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                if !notificationManager.notifications.isEmpty {
                    Button("Clear All") {
                        clearAllNotifications()
                    }
                }
            }
        }
        .onAppear {
            loadNotifications()
        }
    }
    
    private func loadNotifications() {
        notificationManager.loadAllNotifications()
        isLoading = false
    }
    
    private func removeNotifications(at offsets: IndexSet) {
        let identifiers = offsets.map { notificationManager.notifications[$0].identifier }
        for id in identifiers {
            notificationManager.removeNotification(withId: id)
        }
    }
    
    private func clearAllNotifications() {
        notificationManager.clearAllNotifications()
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
