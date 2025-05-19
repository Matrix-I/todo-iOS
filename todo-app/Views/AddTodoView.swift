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
    
    // Available alarm offset options in minutes
    private let alarmOffsetOptions = [15, 30, 60, 120, 1440] // 15 min, 30 min, 1 hour, 2 hours, 1 day
    
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
                                Text("15 minutes before").tag(15)
                                Text("30 minutes before").tag(30)
                                Text("1 hour before").tag(60)
                                Text("2 hours before").tag(120)
                                Text("1 day before").tag(1440)
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
                        Button(action: createTodo) {
                            Text("Create")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(title.isEmpty ? Color.gray : Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(title.isEmpty)
                        
                        Button(action: { isPresented = false }) {
                            Text("Cancel")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                    }
                }
            }
            .navigationTitle("New Task")
        }
    }
    
    private func createTodo() {
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
        if minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        } else if minutes < 1440 { // less than a day
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "\(hours) hour\(hours == 1 ? "" : "s") \(remainingMinutes) minute\(remainingMinutes == 1 ? "" : "s")"
            }
        } else { // days
            let days = minutes / 1440
            let remainingHours = (minutes % 1440) / 60
            
            if remainingHours == 0 {
                return "\(days) day\(days == 1 ? "" : "s")"
            } else {
                return "\(days) day\(days == 1 ? "" : "s") \(remainingHours) hour\(remainingHours == 1 ? "" : "s")"
            }
        }
    }
}
