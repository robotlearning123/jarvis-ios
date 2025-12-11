import SwiftUI

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.blue)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.user.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(viewModel.user.email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Member since \(viewModel.user.memberSince.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Statistics") {
                    StatRow(label: "Total Items", value: "\(viewModel.stats.totalItems)")
                    StatRow(label: "Items This Week", value: "\(viewModel.stats.itemsThisWeek)")
                    StatRow(label: "Items This Month", value: "\(viewModel.stats.itemsThisMonth)")
                }

                Section("Activity") {
                    ForEach(viewModel.recentActivity) { activity in
                        ActivityRow(activity: activity)
                    }
                }

                Section {
                    NavigationLink(destination: EditProfileView(user: $viewModel.user)) {
                        Label("Edit Profile", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        viewModel.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
        }
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .foregroundStyle(activity.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)

                Text(activity.timestamp, format: .relative(presentation: .named))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct EditProfileView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss

    @State private var editedName: String
    @State private var editedEmail: String
    @State private var editedBio: String

    init(user: Binding<User>) {
        self._user = user
        _editedName = State(initialValue: user.wrappedValue.name)
        _editedEmail = State(initialValue: user.wrappedValue.email)
        _editedBio = State(initialValue: user.wrappedValue.bio)
    }

    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $editedName)
                TextField("Email", text: $editedEmail)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            }

            Section("About") {
                TextField("Bio", text: $editedBio, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(!isValid)
            }
        }
    }

    private var isValid: Bool {
        !editedName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !editedEmail.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func saveChanges() {
        user.name = editedName
        user.email = editedEmail
        user.bio = editedBio
        dismiss()
    }
}

@Observable
class ProfileViewModel {
    var user = User(
        name: "John Appleseed",
        email: "john@example.com",
        bio: "iOS Developer passionate about SwiftUI",
        memberSince: Date().addingTimeInterval(-86400 * 180) // 180 days ago
    )

    var stats = UserStats(
        totalItems: 42,
        itemsThisWeek: 7,
        itemsThisMonth: 23
    )

    var recentActivity: [Activity] = [
        Activity(title: "Created new item", icon: "plus.circle.fill", color: .green, timestamp: Date().addingTimeInterval(-3600)),
        Activity(title: "Updated profile", icon: "person.fill", color: .blue, timestamp: Date().addingTimeInterval(-7200)),
        Activity(title: "Deleted item", icon: "trash.fill", color: .red, timestamp: Date().addingTimeInterval(-86400)),
        Activity(title: "Shared item", icon: "square.and.arrow.up.fill", color: .orange, timestamp: Date().addingTimeInterval(-172800)),
    ]

    func signOut() {
        // Implement sign out logic
        print("Signing out...")
    }
}

#Preview {
    ProfileView()
}
