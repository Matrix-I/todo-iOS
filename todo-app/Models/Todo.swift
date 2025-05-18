import Foundation
import CoreData
import SwiftUI

// Priority enum for type safety and reusability
enum Priority: String, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var sortValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
    
    static var defaultValue: Priority {
        return .medium
    }
    
    // Conformance to Identifiable
    var id: String { self.rawValue }
}

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
    
    var priorityEnum: Priority {
        guard let priorityString = priority, let priorityCase = Priority(rawValue: priorityString) else {
            return Priority.defaultValue
        }
        return priorityCase
    }
    
    var priorityColor: Color {
        return priorityEnum.color
    }
    
    var prioritySort: Int {
        return priorityEnum.sortValue
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
