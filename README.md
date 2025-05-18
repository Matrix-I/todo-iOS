# Todo iOS App

## Overview

A modern, feature-rich todo list application built with SwiftUI and Core Data. This app helps you manage your tasks with an intuitive interface and powerful organization features.

![Todo App Screenshot](screenshots/app-screenshot.png)

## Features

- **Task Management**: Add, edit, complete, and delete tasks
- **Priority Levels**: Assign High, Medium, or Low priority to tasks with color coding
- **Due Dates**: Set and track due dates for your tasks
- **Filtering**: Filter tasks by All, Active, Completed, or Overdue status
- **Sorting**: Sort tasks by Date Created, Due Date, Priority, or Alphabetically
- **Persistence**: All data is saved using Core Data for reliable storage
- **Modern UI**: Clean, intuitive interface built with SwiftUI

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Architecture

The app follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Core Data entities (Todo) with additional computed properties
- **Views**: SwiftUI views for displaying and interacting with todos
- **View Models**: Logic for filtering, sorting, and managing todos

## Project Structure

- `/Models`: Contains the Todo model and Core Data related files
- `/Views`: Contains all SwiftUI views including TodoDetailView
- `/todo_app.xcdatamodeld`: Core Data model definition

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run on a simulator or device

```bash
git clone <repository-url>
cd todo-app
open todo-app.xcodeproj
```

## Usage

- **Add a task**: Type in the text field at the top and press the + button
- **Complete a task**: Tap the circle next to a task
- **Edit a task**: Tap on a task to open the detail view
- **Delete a task**: Swipe left on a task
- **Filter tasks**: Use the Filter menu to select a filter
- **Sort tasks**: Use the Sort menu to change the sorting order
- **Clear all tasks**: Tap the "Clear All" button in the top right

## Future Enhancements

- Task categories/tags
- Recurring tasks
- Notifications for due dates
- Dark mode support
- iCloud sync

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- SwiftUI for the modern UI framework
- Core Data for persistence