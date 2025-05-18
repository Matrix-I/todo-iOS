//
//  ContentView.swift
//  todo-app
//
//  Created by Linh Nguyen on 18.05.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newItemTitle = ""
    @State private var showingFilters = false
    @State private var selectedFilter: TodoFilter = .all
    @State private var selectedSortOption: SortOption = .dateCreated
    
    enum TodoFilter {
        case all, active, completed, overdue
        
        var name: String {
            switch self {
            case .all: return "All"
            case .active: return "Active"
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            }
        }
    }
    
    enum SortOption {
        case dateCreated, dueDate, priority, alphabetical
        
        var name: String {
            switch self {
            case .dateCreated: return "Date Created"
            case .dueDate: return "Due Date"
            case .priority: return "Priority"
            case .alphabetical: return "A-Z"
            }
        }
    }
    
    // All items sorted by date created (default)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.timestamp, ascending: false)],
        animation: .default)
    private var itemsByDateCreated: FetchedResults<Todo>
    
    // All items sorted by due date
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.dueDate, ascending: true)],
        animation: .default)
    private var itemsByDueDate: FetchedResults<Todo>
    
    // All items sorted by priority
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.priority, ascending: false)],
        animation: .default)
    private var itemsByPriority: FetchedResults<Todo>
    
    // All items sorted alphabetically
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.title, ascending: true)],
        animation: .default)
    private var itemsAlphabetical: FetchedResults<Todo>
    
    // Active items (not completed)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == %@", NSNumber(value: false)),
        animation: .default)
    private var activeItems: FetchedResults<Todo>
    
    // Completed items
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.timestamp, ascending: false)],
        predicate: NSPredicate(format: "isCompleted == %@", NSNumber(value: true)),
        animation: .default)
    private var completedItems: FetchedResults<Todo>
    
    // Overdue items
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Todo.timestamp, ascending: false)],
        predicate: NSPredicate(format: "dueDate < %@ AND isCompleted == %@", Date() as NSDate, NSNumber(value: false)),
        animation: .default)
    private var overdueItems: FetchedResults<Todo>
    
    // Computed property to get the appropriate items based on current filter and sort options
    private var items: [Todo] {
        switch (selectedFilter, selectedSortOption) {
        case (.all, .dateCreated):
            return Array(itemsByDateCreated)
        case (.all, .dueDate):
            return Array(itemsByDueDate)
        case (.all, .priority):
            // Manual sorting by priority using the prioritySort property
            return Array(itemsByDateCreated).sorted { $0.prioritySort > $1.prioritySort }
        case (.all, .alphabetical):
            return Array(itemsAlphabetical)
        case (.active, _):
            return sortItems(Array(activeItems))
        case (.completed, _):
            return sortItems(Array(completedItems))
        case (.overdue, _):
            return sortItems(Array(overdueItems))
        }
    }
    
    // Helper function to sort filtered items
    private func sortItems(_ items: [Todo]) -> [Todo] {
        switch selectedSortOption {
        case .dateCreated:
            return items.sorted { $0.timestamp > $1.timestamp }
        case .dueDate:
            return items.sorted { 
                guard let date1 = $0.dueDate, let date2 = $1.dueDate else {
                    if $0.dueDate == nil && $1.dueDate != nil { return false }
                    if $0.dueDate != nil && $1.dueDate == nil { return true }
                    return $0.timestamp > $1.timestamp
                }
                return date1 < date2
            }
        case .priority:
            // Use the prioritySort property for sorting
            return items.sorted { 
                // If priorities are the same, sort by timestamp (newest first)
                if $0.prioritySort == $1.prioritySort {
                    return $0.timestamp > $1.timestamp
                }
                
                // Higher priority value comes first
                return $0.prioritySort > $1.prioritySort
            }
        case .alphabetical:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }
    
    // MARK: - View Components
    
    private var addTaskBar: some View {
        HStack {
            TextField("Add a new task...", text: $newItemTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: addItem) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .disabled(newItemTitle.isEmpty)
            .padding(.trailing, 8)
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private var filterMenu: some View {
        Menu {
            ForEach([TodoFilter.all, .active, .completed, .overdue], id: \.self) { filter in
                Button(action: {
                    selectedFilter = filter
                }) {
                    HStack {
                        Text(filter.name)
                        if selectedFilter == filter {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text("Filter: \(selectedFilter.name)")
                Image(systemName: "chevron.down")
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
    }
    
    private var sortMenu: some View {
        Menu {
            ForEach([SortOption.dateCreated, .dueDate, .priority, .alphabetical], id: \.self) { option in
                Button(action: {
                    selectedSortOption = option
                }) {
                    HStack {
                        Text(option.name)
                        if selectedSortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text("Sort: \(selectedSortOption.name)")
                Image(systemName: "chevron.down")
            }
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(8)
        }
    }
    
    private var filterSortBar: some View {
        HStack {
            filterMenu
            Spacer()
            sortMenu
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
    
    private func todoItemView(for item: Todo) -> some View {
        HStack {
            Button(action: {
                toggleComplete(item: item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(BorderlessButtonStyle())
            .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                    .fontWeight(item.priority == "High" ? .bold : .regular)
                
                HStack(spacing: 8) {
                    if let dueDate = item.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(dueDate, style: .date)
                                .font(.caption)
                        }
                        .foregroundColor(item.isOverdue ? .red : .gray)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(item.priorityColor)
                            .frame(width: 8, height: 8)
                        Text(item.priority ?? "Medium")
                            .font(.caption)
                    }
                    .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var todoList: some View {
        List {
            ForEach(items, id: \.id) { item in
                NavigationLink(destination: TodoDetailView(todo: item)) {
                    todoItemView(for: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                addTaskBar
                filterSortBar
                todoList
            }
            .navigationTitle("Todo List")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !items.isEmpty {
                        Button(action: clearAllItems) {
                            Text("Clear All")
                        }
                    }
                }
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            let newItem = Todo(context: viewContext)
            newItem.id = UUID()
            newItem.title = newItemTitle
            newItem.isCompleted = false
            newItem.priority = "Medium" // Default priority
            newItem.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) // Default due date: tomorrow
            newItem.timestamp = Date()
            
            do {
                try viewContext.save()
                newItemTitle = ""
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func toggleComplete(item: Todo) {
        withAnimation {
            item.isCompleted.toggle()
            item.timestamp = Date()
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func clearAllItems() {
        withAnimation {
            items.forEach { viewContext.delete($0) }
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
