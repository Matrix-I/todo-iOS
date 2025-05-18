import SwiftUI
import CoreData

struct TodoDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var todo: Todo
    @State private var title: String
    @State private var isCompleted: Bool
    @State private var priority: Priority
    @State private var dueDate: Date
    
    init(todo: Todo) {
        self.todo = todo
        _title = State(initialValue: todo.title)
        _isCompleted = State(initialValue: todo.isCompleted)
        _priority = State(initialValue: todo.priorityEnum)
        _dueDate = State(initialValue: todo.dueDate ?? Date())
    }
    
    var body: some View {
        Form {
            Section(header: Text("Task Details")) {
                TextField("Title", text: $title)
                
                Toggle("Completed", isOn: $isCompleted)
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                
                DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
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
