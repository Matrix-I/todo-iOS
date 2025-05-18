import UserNotifications
import SwiftUI

class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published var notifications: [UNNotificationRequest] = []
    private var appNotifications: [String: UNNotificationRequest] = [:] // Stores all notifications in the app
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadAllNotifications()
        
        // Set up notification observer for when app comes to foreground
        NotificationCenter.default.addObserver(self, 
                                             selector: #selector(appWillEnterForeground), 
                                             name: UIApplication.willEnterForegroundNotification,
                                             object: nil)
    }
    
    @objc private func appWillEnterForeground() {
        loadAllNotifications()
    }
    
    func loadAllNotifications() {
        // Get system notifications to sync with our app's notifications
        let group = DispatchGroup()
        var systemNotifications: Set<String> = []
        
        // Get pending notifications
        group.enter()
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            systemNotifications.formUnion(requests.map { $0.identifier })
            group.leave()
        }
        
        // Get delivered notifications
        group.enter()
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            systemNotifications.formUnion(notifications.map { $0.request.identifier })
            group.leave()
        }
        
        // Update our app's notifications
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            // Remove any notifications that don't exist in the system anymore
            self.appNotifications = self.appNotifications.filter { systemNotifications.contains($0.key) }
            
            // Update the published notifications
            self.notifications = Array(self.appNotifications.values)
            
            // Update badge count based on unread notifications
            self.updateBadgeCount()
        }
    }
    
    func removeNotification(withId id: String) {
        // Remove from system
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        
        // Remove from our app's notifications
        appNotifications.removeValue(forKey: id)
        
        // Update UI
        notifications.removeAll { $0.identifier == id }
        updateBadgeCount()
    }
    
    func clearAllNotifications() {
        // Clear from system
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Clear from our app
        appNotifications.removeAll()
        notifications = []
        updateBadgeCount()
    }
    
    private func updateBadgeCount() {
        // Only show badge for unread notifications
        UIApplication.shared.applicationIconBadgeNumber = notifications.count
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // When notification is received while app is in foreground
        let request = notification.request
        appNotifications[request.identifier] = request
        notifications = Array(appNotifications.values)
        updateBadgeCount()
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // When user taps on a notification
        let request = response.notification.request
        
        // Handle different actions
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User opened the notification
            appNotifications.removeValue(forKey: request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
            
        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification
            appNotifications.removeValue(forKey: request.identifier)
            center.removeDeliveredNotifications(withIdentifiers: [request.identifier])
            
        default:
            // Custom actions if any
            break
        }
        
        // Update notifications list and badge
        notifications = Array(appNotifications.values)
        updateBadgeCount()
        UIApplication.shared.applicationIconBadgeNumber = 0
        completionHandler()
    }
}
