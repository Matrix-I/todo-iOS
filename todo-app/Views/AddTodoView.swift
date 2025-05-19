import SwiftUI
import CoreData
import UserNotifications

struct AddTodoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isPresented: Bool
    let viewContext: NSManagedObjectContext
    
    // Task properties
    @State private var title = ""
    @State private var priority: Priority = .medium
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var hasTime = false
    @State private var hasAlarm = false
    @State private var alarmOffset = 30
    
    // Time constants
    private enum TimeConstants {
        static let minutesInHour = 60
        static let hoursInDay = 24
        static let minutesInDay = minutesInHour * hoursInDay
        
        // Alarm offset options
        static let fifteenMinutes = 15
        static let thirtyMinutes = 30
        static let oneHour = minutesInHour
        static let twoHours = oneHour * 2
        static let oneDay = minutesInDay
    }
    
    // Available alarm offset options in minutes
    private let alarmOffsetOptions = [
        TimeConstants.fifteenMinutes,
        TimeConstants.thirtyMinutes,
        TimeConstants.oneHour,
        TimeConstants.twoHours,
        TimeConstants.oneDay
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Title", text: $title)
                    
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: hasTime ? [.date, .hourAndMinute] : .date)
                    
                    Toggle("Include Time", isOn: $hasTime)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                    
                    if hasTime {
                        Toggle("Set Reminder", isOn: $hasAlarm)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                        
                        if hasAlarm {
                            Picker("Remind me", selection: $alarmOffset) {
                                Text("15 minutes before").tag(TimeConstants.fifteenMinutes)
                                Text("30 minutes before").tag(TimeConstants.thirtyMinutes)
                                Text("1 hour before").tag(TimeConstants.oneHour)
                                Text("2 hours before").tag(TimeConstants.twoHours)
                                Text("1 day before").tag(TimeConstants.oneDay)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases) { priority in
                            HStack {
                                Circle()
                                    .fill(priority.color)
                                    .frame(width: 12, height: 12)
                                Text(priority.rawValue)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    HStack {
                        // Create button with clear tap area
                        ZStack {
                            Button(action: createTodo) {
                                Text("Create")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(title.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Ensures tap area is confined to the button
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Cancel button with clear tap area
                        ZStack {
                            Button(action: { isPresented = false }) {
                                Text("Cancel")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .buttonStyle(BorderlessButtonStyle()) // Ensures tap area is confined to the button
                        }
                        .frame(maxWidth: .infinity)
                    }
                    // Make the section itself non-interactive
                    .contentShape(Rectangle())
                    .allowsHitTesting(true) // Allow hit testing only for the buttons
                }
            }
            .navigationTitle("New Task")
        }
    }
    
    private func createTodo() {
        // Only proceed if title is not empty
        guard !title.isEmpty else { return }
        
        withAnimation {
            let newItem = Todo(context: viewContext)
            newItem.id = UUID()
            newItem.title = title
            newItem.isCompleted = false
            newItem.priority = priority.rawValue
            newItem.dueDate = dueDate
            newItem.timestamp = Date()
            newItem.hasTime = hasTime
            newItem.hasAlarm = hasAlarm
            newItem.alarmOffset = Int16(alarmOffset)
            
            do {
                try viewContext.save()
                
                // Schedule notification if needed
                if hasAlarm && hasTime {
                    scheduleNotification(for: newItem)
                }
                
                isPresented = false
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Schedule a local notification for the todo item
    private func scheduleNotification(for todo: Todo) {
        // Make sure we have a due date
        guard let dueDate = todo.dueDate else { return }
        
        // Calculate notification time (due date minus alarm offset)
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -Int(todo.alarmOffset), to: dueDate)
        guard let notificationTime = notificationTime else { return }
        
        // Don't schedule if the notification time is in the past
        guard notificationTime > Date() else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        
        // Calculate remaining time between notification time and due date
        let remainingMinutes = Int(dueDate.timeIntervalSince(notificationTime) / 60)
        let formattedTime = formatRemainingTime(minutes: remainingMinutes)
        
        content.title = "Todo Reminder"
        content.body = "\(todo.title) - due in \(formattedTime)"
        content.sound = .default
        content.badge = 1
        
        // Create trigger based on date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request using the todo's ID as the identifier
        let request = UNNotificationRequest(identifier: todo.id?.uuidString ?? UUID().uuidString, content: content, trigger: trigger)
        
        // Add the notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // Helper function to format remaining time in a user-friendly way
    private func formatRemainingTime(minutes: Int) -> String {
        // Format a time unit with proper pluralization
        let formatUnit = { (value: Int, unit: String) -> String in
            "\(value) \(unit)\(value == 1 ? "" : "s")"
        }
        
        // Calculate time components
        let days = minutes / TimeConstants.minutesInDay
        let hours = (minutes % TimeConstants.minutesInDay) / TimeConstants.minutesInHour
        let mins = minutes % TimeConstants.minutesInHour
        
        // Build the formatted string based on available components
        switch (days, hours, mins) {
        case (0, 0, _):  // Only minutes
            return formatUnit(mins, "minute")
            
        case (0, _, 0):  // Only hours
            return formatUnit(hours, "hour")
            
        case (0, _, _):  // Hours and minutes
            return "\(formatUnit(hours, "hour")) \(formatUnit(mins, "minute"))"
            
        case (_, 0, _):  // Only days
            return formatUnit(days, "day")
            
        default:         // Days and hours
            return "\(formatUnit(days, "day")) \(formatUnit(hours, "hour"))"
        }
    }
}