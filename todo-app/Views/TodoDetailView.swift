import SwiftUI
import CoreData
import UserNotifications

struct TodoDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var todo: Todo
    @State private var title: String
    @State private var isCompleted: Bool
    @State private var priority: Priority
    @State private var dueDate: Date
    @State private var hasTime: Bool
    @State private var hasAlarm: Bool
    @State private var alarmOffset: Int
    
    // Available alarm offset options in minutes
    private let alarmOffsetOptions = [15, 30, 60, 120, 1440] // 15 min, 30 min, 1 hour, 2 hours, 1 day
    
    init(todo: Todo) {
        self.todo = todo
        _title = State(initialValue: todo.title)
        _isCompleted = State(initialValue: todo.isCompleted)
        _priority = State(initialValue: todo.priorityEnum)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
        _hasTime = State(initialValue: todo.hasTime)
        _hasAlarm = State(initialValue: todo.hasAlarm)
        _alarmOffset = State(initialValue: Int(todo.alarmOffset))
        
        // If alarmOffset is not one of our standard options, default to 30 minutes
        if !alarmOffsetOptions.contains(Int(todo.alarmOffset)) {
            _alarmOffset = State(initialValue: 30)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                TextField("Title", text: $title)
                
                Toggle("Completed", isOn: $isCompleted)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                DatePicker("Due Date", selection: $dueDate, displayedComponents: hasTime ? [.date, .hourAndMinute] : .date)
                
                // Only show time and alarm options for incomplete tasks
                if !isCompleted {
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
                } else {
                    // Show a message for completed tasks
                    Text("Time and reminder settings are disabled for completed tasks")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 4)
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
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: deleteTodo) {
                    Text("Delete Task")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
        }
        .navigationTitle("Edit Task")
    }
    
    private func saveChanges() {
        withAnimation {
            todo.title = title
            todo.isCompleted = isCompleted
            todo.priority = priority.rawValue
            todo.dueDate = dueDate
            
            // If task is completed, disable time and alarm settings
            if isCompleted {
                todo.hasTime = false
                todo.hasAlarm = false
                cancelNotification(for: todo)
            } else {
                todo.hasTime = hasTime
                todo.hasAlarm = hasAlarm
                todo.alarmOffset = Int16(alarmOffset)
                
                // Schedule or cancel notification based on alarm settings
                if hasTime && hasAlarm {
                    scheduleNotification(for: todo)
                } else {
                    cancelNotification(for: todo)
                }
            }
            
            todo.timestamp = Date()
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteTodo() {
        withAnimation {
            // Cancel any pending notifications
            cancelNotification(for: todo)
            
            viewContext.delete(todo)
            
            do {
                try viewContext.save()
                presentationMode.wrappedValue.dismiss()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Schedule a local notification for the todo item
    private func scheduleNotification(for todo: Todo) {
        // Cancel any existing notification first
        cancelNotification(for: todo)
        
        // Make sure we have a due date
        guard let dueDate = todo.dueDate else { return }
        
        // Calculate notification time (due date minus alarm offset)
        let notificationTime = Calendar.current.date(byAdding: .minute, value: -Int(todo.alarmOffset), to: dueDate)
        guard let notificationTime = notificationTime else { return }
        
        // Don't schedule if the notification time is in the past
        guard notificationTime > Date() else { return }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Todo Reminder"
        content.body = todo.title
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
    
    // Cancel a notification for a todo item
    private func cancelNotification(for todo: Todo) {
        guard let id = todo.id?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

struct TodoDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let todo = Todo.create(in: context, title: "Sample Task")
        return NavigationView {
            TodoDetailView(todo: todo)
                .environment(\.managedObjectContext, context)
        }
    }
}
