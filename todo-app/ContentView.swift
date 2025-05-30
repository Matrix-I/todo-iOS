//
//  ContentView.swift
//  todo-app
//
//  Created by Linh Nguyen on 18.05.2025.
//

import SwiftUI
import CoreData
import UserNotifications

struct ContentView: View {
    // Font size variables for easy adjustment
    private let titleFontSize: CGFloat = 20
    private let detailsFontSize: CGFloat = 16
    private let secondaryFontSize: CGFloat = 14
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var newItemTitle = ""
    @State private var showingAddSheet = false
    @State private var showingClearAllAlert = false
    @State private var showingFilters = false
    @State private var selectedFilter: TodoFilter = .all
    @State private var selectedSortOption: SortOption = .dueDate
    @State private var notificationsAuthorized = false
    
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
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dueDate, priority, alphabetical
        
        var description: String {
            switch self {
            case .dueDate: return "Due Date"
            case .priority: return "Priority"
            case .alphabetical: return "Alphabetical"
            }
        }
        
        var id: String { self.rawValue }
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
        case (.all, .dueDate):
            return Array(itemsByDueDate)
        case (.all, .priority):
            return Array(itemsByDateCreated).sorted { $0.prioritySort > $1.prioritySort }
        case (.all, .alphabetical):
            return Array(itemsByDateCreated).sorted { $0.title < $1.title }
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
        case .dueDate:
            return items.sorted { item1, item2 in
                guard let date1 = item1.dueDate, let date2 = item2.dueDate else {
                    if item1.dueDate == nil && item2.dueDate != nil { return false }
                    if item1.dueDate != nil && item2.dueDate == nil { return true }
                    return false
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
    
    // Floating action button for adding new tasks
    private var addButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: { showingAddSheet = true }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
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
            Picker("Sort By", selection: $selectedSortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.description).tag(option)
                }
            }
        } label: {
            HStack {
                Text("Sort: \(selectedSortOption.description)")
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
                    .font(.system(size: titleFontSize))
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .gray : .primary)
                    .fontWeight(item.priorityEnum == .high ? .bold : .regular)
                
                HStack(spacing: 8) {
                    if let dueDate = item.dueDate {
                        HStack(spacing: 2) {
                            Image(systemName: item.hasTime ? "clock" : "calendar")
                                .font(.system(size: detailsFontSize))
                            if item.hasTime {
                                Text(dueDate, style: .date)
                                    .font(.system(size: detailsFontSize))
                                Text(dueDate, style: .time)
                                    .font(.system(size: detailsFontSize))
                            } else {
                                Text(dueDate, style: .date)
                                    .font(.system(size: detailsFontSize))
                            }
                            
                            if item.hasAlarm {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: detailsFontSize))
                                    .foregroundColor(.orange)
                            }
                        }
                        .foregroundColor(item.isOverdue ? .red : .gray)
                    }
                    
                    HStack(spacing: 2) {
                        Circle()
                            .fill(item.priorityColor)
                            .frame(width: 10, height: 10)
                        Text(item.priorityEnum.rawValue)
                            .font(.system(size: secondaryFontSize))
                    }
                    .foregroundColor(.gray)
                }
                
                // Removed date created section
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
        ZStack {
            NavigationView {
                VStack(spacing: 0) {
                    filterSortBar
                    todoList
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !items.isEmpty {
                            Button(action: { showingClearAllAlert = true }) {
                                Text("Clear All")
                            }
                            .alert(isPresented: $showingClearAllAlert) {
                                Alert(
                                    title: Text("Clear All Tasks"),
                                    message: Text("Are you sure you want to delete all tasks? This action cannot be undone."),
                                    primaryButton: .destructive(Text("Confirm")) {
                                        clearAllItems()
                                    },
                                    secondaryButton: .cancel()
                                )
                            }
                        }
                    }
                }
                .navigationTitle("Todo List")
                .onAppear {
                    requestNotificationPermissions()
                    clearNotificationBadge()
                }
            }
            
            // Floating action button
            addButton
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTodoView(isPresented: $showingAddSheet, viewContext: viewContext)
        }
    }
    
    // Request notification permissions
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if success {
                DispatchQueue.main.async {
                    self.notificationsAuthorized = true
                }
            } else if let error = error {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }
    
    // Cancel a notification for a todo item
    private func cancelNotification(for todo: Todo) {
        guard let id = todo.id?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
    
    // Clear the notification badge when app is opened
    private func clearNotificationBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("Error clearing badge: \(error)")
            }
        }
    }
    
    private func toggleComplete(item: Todo) {
        withAnimation {
            item.isCompleted.toggle()
            item.timestamp = Date() // Update timestamp when toggling completion
            
            // Disable alarm and cancel notifications if the task is completed
            if item.isCompleted && item.hasAlarm {
                item.hasAlarm = false // Disable the alarm
                cancelNotification(for: item)
            }
            
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
