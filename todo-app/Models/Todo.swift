import Foundation
import CoreData
import SwiftUI

@objc(Todo)
public class Todo: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var title: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var timestamp: Date
    @NSManaged public var priority: String?
    @NSManaged public var dueDate: Date?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Todo> {
        return NSFetchRequest<Todo>(entityName: "Todo")
    }
    
    var priorityColor: Color {
        switch priority {
        case "High":
            return .red
        case "Medium":
            return .orange
        case "Low":
            return .green
        default:
            return .gray
        }
    }
    
    var prioritySort: Int {
        switch priority {
        case "High":
            return 3
        case "Medium":
            return 2
        case "Low":
            return 1
        default:
            return 0
        }
    }
    
    var isOverdue: Bool {
        if let dueDate = dueDate, !isCompleted {
            return dueDate < Date()
        }
        return false
    }
    
    var creationDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

extension Todo {
    static func create(in context: NSManagedObjectContext, title: String, isCompleted: Bool = false, priority: String = "Medium", dueDate: Date? = nil) -> Todo {
        let todo = Todo(context: context)
        todo.id = UUID()
        todo.title = title
        todo.isCompleted = isCompleted
        todo.priority = priority
        todo.dueDate = dueDate
        todo.timestamp = Date()
        return todo
    }
    
    static func basicFetchRequest() -> FetchRequest<Todo> {
        FetchRequest(entity: Todo.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \Todo.timestamp, ascending: true)])
    }
}
