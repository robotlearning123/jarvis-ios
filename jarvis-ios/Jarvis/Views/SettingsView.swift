import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $viewModel.selectedTheme) {
                        ForEach(ThemeOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }

                    Toggle("Use System Font", isOn: $viewModel.useSystemFont)

                    ColorPicker("Accent Color", selection: $viewModel.accentColor)
                }

                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)

                    if viewModel.notificationsEnabled {
                        Toggle("Daily Reminders", isOn: $viewModel.dailyReminders)
                        Toggle("Item Updates", isOn: $viewModel.itemUpdates)

                        Picker("Notification Sound", selection: $viewModel.notificationSound) {
                            ForEach(NotificationSound.allCases) { sound in
                                Text(sound.rawValue).tag(sound)
                            }
                        }
                    }
                }

                Section("Data & Privacy") {
                    NavigationLink("Data Usage") {
                        DataUsageView()
                    }

                    NavigationLink("Privacy Policy") {
                        PrivacyPolicyView()
                    }

                    Button("Clear Cache") {
                        viewModel.clearCache()
                    }

                    Button("Export Data") {
                        viewModel.exportData()
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: viewModel.appVersion)
                    LabeledContent("Build", value: viewModel.buildNumber)

                    NavigationLink("Licenses") {
                        LicensesView()
                    }

                    Link("Rate on App Store", destination: URL(string: "https://apps.apple.com")!)
                }

                Section {
                    Button("Reset All Settings", role: .destructive) {
                        viewModel.showingResetConfirmation = true
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Settings", isPresented: $viewModel.showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetSettings()
                }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
        }
    }
}

struct DataUsageView: View {
    var body: some View {
        List {
            Section("Storage") {
                LabeledContent("App Size", value: "12.3 MB")
                LabeledContent("Documents & Data", value: "4.7 MB")
                LabeledContent("Cache", value: "1.2 MB")
            }

            Section {
                Button("Clear All Data", role: .destructive) {
                    // Implement clear data
                }
            }
        }
        .navigationTitle("Data Usage")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Your privacy is important to us. This app collects and processes data as follows:")
                    .font(.body)

                VStack(alignment: .leading, spacing: 12) {
                    PrivacySection(
                        title: "Data Collection",
                        content: "We collect information you provide directly to us, including items you create and your account information."
                    )

                    PrivacySection(
                        title: "Data Usage",
                        content: "Your data is used solely to provide app functionality and is stored locally on your device."
                    )

                    PrivacySection(
                        title: "Data Sharing",
                        content: "We do not share your personal information with third parties."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct LicensesView: View {
    let licenses = [
        License(name: "SwiftUI", type: "MIT License"),
        License(name: "SwiftData", type: "Apple License"),
    ]

    var body: some View {
        List(licenses) { license in
            VStack(alignment: .leading, spacing: 4) {
                Text(license.name)
                    .font(.headline)

                Text(license.type)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@Observable
class SettingsViewModel {
    var selectedTheme: ThemeOption = .system
    var useSystemFont = true
    var accentColor: Color = .blue

    var notificationsEnabled = true
    var dailyReminders = true
    var itemUpdates = true
    var notificationSound: NotificationSound = .default

    var showingResetConfirmation = false

    let appVersion = "1.0.0"
    let buildNumber = "1"

    func clearCache() {
        print("Clearing cache...")
    }

    func exportData() {
        print("Exporting data...")
    }

    func resetSettings() {
        selectedTheme = .system
        useSystemFont = true
        accentColor = .blue
        notificationsEnabled = true
        dailyReminders = true
        itemUpdates = true
        notificationSound = .default
    }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var id: String { rawValue }
}

enum NotificationSound: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case chime = "Chime"
    case bell = "Bell"
    case none = "None"

    var id: String { rawValue }
}

#Preview {
    SettingsView()
}
