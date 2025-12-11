# JARVIS iOS - Native iOS Development Guide

> **Project**: jarvis-ios (Native iOS App)
> **Stack**: Swift 5.9+ + SwiftUI + Xcode
> **Platform**: iOS 16.0+
> **Last Updated**: 2025-12-11

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [SwiftUI Guidelines](#swiftui-guidelines)
5. [Development Workflow](#development-workflow)
6. [Common Tasks](#common-tasks)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 Project Overview

### Purpose
Native iOS application for JARVIS AI assistant, providing seamless integration with iPhone features:
- 📱 Native iOS UI/UX with SwiftUI
- 🎤 Voice interaction via Siri integration
- 🔔 Push notifications
- 📲 Widget support
- ⌚ Apple Watch companion (planned)

### Requirements
- **Xcode**: 15.0+
- **iOS Deployment**: 16.0+
- **Swift**: 5.9+
- **macOS**: 13.0+ (for development)

### Key Features
- Native SwiftUI interface
- Real-time AI responses
- Voice commands
- Email integration
- Calendar sync
- Health data integration (planned)

---

## 🏗️ Architecture

### MVVM Pattern

```
┌─────────────────────────────────────────┐
│              Views (SwiftUI)            │
│  ┌──────────┬──────────┬──────────┐    │
│  │ HomeView │ProfileVw │SettingsVw│    │
│  └────┬─────┴────┬─────┴────┬─────┘    │
│       │          │          │           │
│       └──────────┼──────────┘           │
│                  │                      │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│          ViewModels                     │
│  @Observable classes that manage state  │
│  ┌──────────────────────────────┐      │
│  │  @Observable HomeViewModel   │      │
│  │  - @Published properties     │      │
│  │  - Business logic            │      │
│  │  - Calls services            │      │
│  └──────────────────────────────┘      │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Services Layer                │
│  ┌──────────┬──────────┬──────────┐    │
│  │AIService │VoiceServ │Realtime  │    │
│  │          │ice       │Service   │    │
│  └──────────┴──────────┴──────────┘    │
└──────────────────┼──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│            Models                       │
│  Data structures and business entities  │
└─────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
jarvis-ios/
├── Jarvis.xcodeproj/              # Xcode project file
│
├── Jarvis/                        # Main app target
│   ├── JarvisApp.swift            # App entry point
│   │   └── Line 10: @main App structure
│   │
│   ├── Views/                     # SwiftUI Views
│   │   ├── HomeView.swift         # Main dashboard
│   │   ├── ProfileView.swift      # User profile
│   │   ├── SettingsView.swift     # App settings
│   │   └── Components/            # Reusable components
│   │       ├── EmailCard.swift
│   │       ├── InsightCard.swift
│   │       └── VoiceButton.swift
│   │
│   ├── ViewModels/                # State management
│   │   ├── HomeViewModel.swift
│   │   ├── ProfileViewModel.swift
│   │   └── SettingsViewModel.swift
│   │
│   ├── Models/                    # Data models
│   │   ├── User.swift             # User model
│   │   ├── Email.swift            # Email model
│   │   ├── Insight.swift          # AI insight model
│   │   └── Item.swift             # Generic item
│   │
│   ├── Services/                  # Business logic services
│   │   ├── AIService.swift        # AI integration
│   │   ├── VoiceService.swift     # Voice handling
│   │   ├── RealtimeService.swift  # Real-time updates
│   │   └── NetworkService.swift   # API client
│   │
│   ├── Utilities/                 # Helper utilities
│   │   ├── Extensions/
│   │   │   ├── Color+Theme.swift
│   │   │   └── View+Extensions.swift
│   │   ├── Constants.swift        # App constants
│   │   └── Logger.swift           # Logging utility
│   │
│   ├── Resources/                 # Assets and resources
│   │   ├── Assets.xcassets/       # Images, colors
│   │   ├── Info.plist             # App configuration
│   │   └── Localizable.strings    # Localization
│   │
│   └── Preview Content/           # SwiftUI preview data
│       └── PreviewData.swift
│
├── JarvisTests/                   # Unit tests
│   ├── ViewModelTests/
│   ├── ServiceTests/
│   └── ModelTests/
│
├── JarvisUITests/                 # UI tests
│   └── HomeViewUITests.swift
│
└── CLAUDE.md                      # THIS FILE
```

---

## 🎨 SwiftUI Guidelines

### View Structure

```swift
// ✅ GOOD: Clean, composable view structure
struct HomeView: View {
    // 1. State and observed objects
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false

    // 2. Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    insightsSection
                    emailsSection
                }
            }
            .navigationTitle("JARVIS")
            .toolbar {
                toolbarContent
            }
        }
    }

    // 3. Extracted views for clarity
    private var headerSection: some View {
        VStack {
            Text("Good morning!")
            Text(viewModel.briefing)
        }
    }

    private var insightsSection: some View {
        ForEach(viewModel.insights) { insight in
            InsightCard(insight: insight)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Settings") {
                showingSettings = true
            }
        }
    }
}

// ❌ BAD: Everything in one giant body
struct HomeView: View {
    var body: some View {
        // 200 lines of nested code...
    }
}
```

### ViewModel Pattern

```swift
// ✅ GOOD: Observable ViewModel with Swift 5.9+
@Observable
final class HomeViewModel {
    // Properties automatically tracked
    var insights: [Insight] = []
    var isLoading = false
    var errorMessage: String?

    private let aiService: AIService

    init(aiService: AIService = .shared) {
        self.aiService = aiService
    }

    @MainActor
    func loadInsights() async {
        isLoading = true
        defer { isLoading = false }

        do {
            insights = try await aiService.fetchInsights()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Usage in View
struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        // View automatically updates when viewModel properties change
    }
}
```

### Naming Conventions

```swift
// Types: PascalCase
struct HomeView: View { }
class AIService { }
enum Priority { }

// Properties/Functions: camelCase
var emailList: [Email]
func fetchInsights() async throws -> [Insight]

// Constants: camelCase (Swift convention)
let maxRetryAttempts = 3
let apiBaseURL = "https://api.jarvis.ai"

// Environment values: camelCase
@Environment(\.colorScheme) var colorScheme

// State properties: descriptive names
@State private var isShowingSettings = false
@State private var selectedEmail: Email?
```

### State Management

```swift
// ✅ Use @State for simple, view-local state
@State private var isExpanded = false
@State private var searchText = ""

// ✅ Use @StateObject for creating ViewModels
@StateObject private var viewModel = HomeViewModel()

// ✅ Use @ObservedObject for passed-in ViewModels
@ObservedObject var viewModel: HomeViewModel

// ✅ Use @Environment for dependency injection
@Environment(\.dismiss) var dismiss
@Environment(\.colorScheme) var colorScheme

// ✅ Use @AppStorage for UserDefaults
@AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

// ❌ Don't use @State for complex objects
@State private var viewModel = HomeViewModel()  // Wrong!
```

---

## 🔧 Development Workflow

### Opening the Project

```bash
# Navigate to iOS project
cd jarvis-ios

# Open in Xcode
open Jarvis.xcodeproj
```

### Building and Running

1. **Select Target**:
   - Product → Destination → Select simulator or device
   - Recommended: iPhone 15 Pro simulator

2. **Build**:
   - ⌘ + B (Command + B)
   - Or: Product → Build

3. **Run**:
   - ⌘ + R (Command + R)
   - Or: Product → Run

4. **Preview**:
   - Open any SwiftUI view
   - Click "Resume" in preview canvas
   - Or: ⌥ + ⌘ + P (Option + Command + P)

### Code Formatting

```swift
// Use SwiftFormat or SwiftLint (if configured)
// Xcode auto-formatting: Ctrl + I (indent/format)

// Preferred style:
func fetchData() async throws -> [Email] {
    let response = try await networkService.request(
        endpoint: .emails,
        method: .get
    )
    return try decoder.decode([Email].self, from: response)
}
```

---

## 🛠️ Common Tasks

### Task 1: Add a New View

```swift
// 1. Create new Swift file: Views/NewFeatureView.swift
import SwiftUI

struct NewFeatureView: View {
    var body: some View {
        Text("New Feature")
            .navigationTitle("Feature")
    }
}

#Preview {
    NavigationStack {
        NewFeatureView()
    }
}

// 2. Add to navigation in HomeView
NavigationLink("New Feature") {
    NewFeatureView()
}
```

### Task 2: Add API Endpoint Integration

```swift
// 1. Define endpoint in NetworkService
extension APIEndpoint {
    static let insights = APIEndpoint(
        path: "/api/insights",
        method: .get
    )
}

// 2. Add service method
extension NetworkService {
    func fetchInsights() async throws -> [Insight] {
        try await request(
            endpoint: .insights,
            responseType: [Insight].self
        )
    }
}

// 3. Use in ViewModel
@MainActor
func loadInsights() async {
    do {
        insights = try await networkService.fetchInsights()
    } catch {
        handleError(error)
    }
}
```

### Task 3: Add New Model

```swift
// Models/Task.swift
import Foundation

struct Task: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var priority: Priority
    var dueDate: Date?

    enum Priority: String, Codable {
        case high, medium, low
    }
}

// Add Equatable for comparisons
extension Task: Equatable {
    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}

// Add mock data for previews
extension Task {
    static let mockData = [
        Task(
            id: UUID(),
            title: "Review pull request",
            isCompleted: false,
            priority: .high,
            dueDate: Date().addingTimeInterval(3600)
        ),
        // More mock data...
    ]
}
```

### Task 4: Add Settings Option

```swift
// In SettingsView.swift
struct SettingsView: View {
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("theme") private var theme = "auto"

    var body: some View {
        Form {
            Section("Preferences") {
                Toggle("Enable Notifications", isOn: $enableNotifications)

                Picker("Theme", selection: $theme) {
                    Text("Auto").tag("auto")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }
        }
    }
}
```

---

## 🧪 Testing

### Unit Tests

```swift
// JarvisTests/ViewModelTests/HomeViewModelTests.swift
import XCTest
@testable import Jarvis

final class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockAIService: MockAIService!

    override func setUp() {
        super.setUp()
        mockAIService = MockAIService()
        viewModel = HomeViewModel(aiService: mockAIService)
    }

    override func tearDown() {
        viewModel = nil
        mockAIService = nil
        super.tearDown()
    }

    func testLoadInsightsSuccess() async throws {
        // Given
        let expectedInsights = [Insight.mockData[0]]
        mockAIService.insightsToReturn = expectedInsights

        // When
        await viewModel.loadInsights()

        // Then
        XCTAssertEqual(viewModel.insights.count, 1)
        XCTAssertEqual(viewModel.insights, expectedInsights)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadInsightsFailure() async {
        // Given
        mockAIService.shouldFail = true

        // When
        await viewModel.loadInsights()

        // Then
        XCTAssertTrue(viewModel.insights.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}
```

### UI Tests

```swift
// JarvisUITests/HomeViewUITests.swift
import XCTest

final class HomeViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testNavigationToSettings() {
        // Tap settings button
        app.buttons["Settings"].tap()

        // Verify settings view is shown
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testInsightCardTap() {
        // Find first insight card
        let insightCard = app.buttons["insight-card-0"]

        // Verify it exists
        XCTAssertTrue(insightCard.waitForExistence(timeout: 2))

        // Tap it
        insightCard.tap()

        // Verify detail view opens
        XCTAssertTrue(app.navigationBars["Insight Details"].exists)
    }
}
```

### Running Tests

```bash
# In Xcode:
# ⌘ + U (Command + U) - Run all tests

# Command line:
xcodebuild test \
  -project Jarvis.xcodeproj \
  -scheme Jarvis \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## 🐛 Troubleshooting

### Issue: Build Errors After Git Pull

**Solution**:
```bash
# Clean build folder
⌘ + Shift + K (in Xcode)

# Or command line:
xcodebuild clean -project Jarvis.xcodeproj -scheme Jarvis

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Issue: Preview Not Working

**Solutions**:
1. **Restart Preview**: ⌥ + ⌘ + P
2. **Clean Build**: ⌘ + Shift + K
3. **Restart Xcode**
4. **Check Preview Code**:
   ```swift
   #Preview {
       HomeView()
           .environment(\.colorScheme, .light)
   }
   ```

### Issue: Simulator Not Responding

```bash
# Reset simulator
xcrun simctl shutdown all
xcrun simctl erase all

# Or use Xcode: Device → Erase All Content and Settings
```

### Issue: Code Signing Errors

1. **Check Team**: Xcode → Signing & Capabilities → Team
2. **Auto-signing**: Enable "Automatically manage signing"
3. **Bundle ID**: Ensure unique bundle identifier

---

## 📚 Best Practices

### SwiftUI

- ✅ Extract complex views into smaller components
- ✅ Use `@ViewBuilder` for flexible view composition
- ✅ Prefer `LazyVStack`/`LazyHStack` for long lists
- ✅ Use `.task()` modifier for async operations
- ⚠️ Avoid complex logic in view body
- ⚠️ Don't create `@StateObject` conditionally

### Async/Await

```swift
// ✅ GOOD: Proper async/await usage
@MainActor
func loadData() async {
    isLoading = true
    defer { isLoading = false }

    do {
        let data = try await service.fetchData()
        self.data = data
    } catch {
        errorMessage = error.localizedDescription
    }
}

// ❌ BAD: Blocking main thread
func loadData() {
    isLoading = true
    let data = service.fetchDataSync()  // Blocks!
    self.data = data
    isLoading = false
}
```

### Error Handling

```swift
// ✅ GOOD: User-friendly error messages
enum AppError: LocalizedError {
    case networkFailure
    case invalidResponse
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "Unable to connect. Please check your internet connection."
        case .invalidResponse:
            return "Received invalid data from server."
        case .unauthorized:
            return "Please sign in to continue."
        }
    }
}
```

---

## 🔗 Related Documentation

- **Root Guide**: `/CLAUDE.md` - Overall project structure
- **Backend API**: `/jarvis-demo/CLAUDE.md` - API documentation
- **Apple Docs**: [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

---

## 🎯 Key Files Reference

| File | Purpose | Key Lines |
|------|---------|-----------|
| `JarvisApp.swift` | App entry point | L10: @main |
| `Views/HomeView.swift` | Main view | L20: body |
| `Services/AIService.swift` | AI integration | L45: fetchInsights() |
| `Models/User.swift` | User model | L10: struct definition |

---

**Last Updated**: 2025-12-11
**Platform**: iOS 16.0+
**Language**: Swift 5.9+

Remember: Build often, preview frequently, test thoroughly.
