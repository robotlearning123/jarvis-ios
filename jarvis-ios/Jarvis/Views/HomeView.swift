import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var viewModel = HomeViewModel()
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var isGridView = false

    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyStateView
                } else {
                    if isGridView {
                        gridView
                    } else {
                        listView
                    }
                }
            }
            .navigationTitle("JARVIS")
            .searchable(text: $searchText, prompt: "Search items...")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isGridView.toggle()
                    }) {
                        Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddSheet = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingAddSheet) {
                AddItemView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Items Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Tap the + button to add your first item")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Add Item") {
                showingAddSheet = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var listView: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ItemRow(item: item)
                }
            }
            .onDelete(perform: deleteItems)
        }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(filteredItems) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ItemCard(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }

    private func refreshData() async {
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

struct ItemRow: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.title)
                .font(.headline)

            if let description = item.itemDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct ItemCard: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)

            if let description = item.itemDescription {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Text(item.timestamp, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 120)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var showingValidationError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Title", text: $title)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .alert("Invalid Input", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please enter a valid title for the item.")
            }
        }
    }

    private func addItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)

        guard !trimmedTitle.isEmpty else {
            showingValidationError = true
            return
        }

        withAnimation {
            let newItem = Item(
                title: trimmedTitle,
                itemDescription: description.isEmpty ? nil : description
            )
            modelContext.insert(newItem)
            dismiss()
        }
    }
}

struct ItemDetailView: View {
    let item: Item
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String

    init(item: Item) {
        self.item = item
        _editedTitle = State(initialValue: item.title)
        _editedDescription = State(initialValue: item.itemDescription ?? "")
    }

    var body: some View {
        List {
            Section("Details") {
                if isEditing {
                    TextField("Title", text: $editedTitle)
                    TextField("Description", text: $editedDescription, axis: .vertical)
                        .lineLimit(3...6)
                } else {
                    LabeledContent("Title", value: item.title)

                    if let description = item.itemDescription {
                        LabeledContent("Description") {
                            Text(description)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Metadata") {
                LabeledContent("Created", value: item.timestamp, format: Date.FormatStyle(date: .long, time: .shortened))
            }
        }
        .navigationTitle("Item Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
            }
        }
    }

    private func saveChanges() {
        item.title = editedTitle.trimmingCharacters(in: .whitespaces)
        item.itemDescription = editedDescription.isEmpty ? nil : editedDescription
    }
}

@Observable
class HomeViewModel {
    var isLoading = false
    var errorMessage: String?

    func loadData() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        isLoading = false
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Item.self, inMemory: true)
}
