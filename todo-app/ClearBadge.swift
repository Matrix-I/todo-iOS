import SwiftUI
import UserNotifications

struct ClearBadgeView: View {
    @State private var badgeCleared = false
    
    var body: some View {
        VStack {
            Text(badgeCleared ? "Badge Cleared!" : "Clear Badge")
                .font(.title)
                .padding()
            
            Button("Clear Badge Now") {
                clearAllBadges()
                badgeCleared = true
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .onAppear {
            // Automatically clear badges when this view appears
            clearAllBadges()
            badgeCleared = true
        }
    }
    
    func clearAllBadges() {
        // Clear application badge
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        // Clear notification center badge
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
        
        // Remove all delivered notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        print("All badges and notifications cleared")
    }
}
