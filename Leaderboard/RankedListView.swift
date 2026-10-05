import SwiftUI
import SwiftData

struct RankedListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var list: RankedList
    @State private var newItemText = ""
    @FocusState private var addFieldFocused: Bool

    private var items: [RankedItem] { list.rankedItems }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView(
                    "Your List Is Empty",
                    systemImage: "arrow.down.to.line.compact",
                    description: Text("Add the first item below. You can reorder items at any time.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    RankedItemRow(rank: index + 1, item: item)
                }
                .onMove(perform: moveItems)
                .onDelete(perform: deleteItems)
            }

            HStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.tint)
                TextField("Add an item", text: $newItemText)
                    .focused($addFieldFocused)
                    .submitLabel(.done)
                    .onSubmit(addItem)
                Button("Add", action: addItem)
                    .disabled(trimmedNewItem.isEmpty)
            }
        }
        .navigationTitle(list.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                ShareLink(item: list.shareText, subject: Text(list.title)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .disabled(items.isEmpty)
                EditButton()
            }
        }
    }

    private var trimmedNewItem: String {
        newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addItem() {
        guard !trimmedNewItem.isEmpty else { return }
        let item = RankedItem(text: trimmedNewItem, rank: items.count)
        modelContext.insert(item)
        list.items.append(item)
        newItemText = ""
        addFieldFocused = true
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() { item.rank = index }
    }

    private func deleteItems(at offsets: IndexSet) {
        let doomed = offsets.map { items[$0] }
        let doomedIDs = Set(doomed.map(\.persistentModelID))
        let remaining = items.filter { !doomedIDs.contains($0.persistentModelID) }
        for item in doomed { modelContext.delete(item) }
        for (index, item) in remaining.enumerated() { item.rank = index }
    }
}

private struct RankedItemRow: View {
    let rank: Int
    @Bindable var item: RankedItem

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 28, alignment: .trailing)
            TextField("Item", text: $item.text, axis: .vertical)
                .lineLimit(1...3)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Rank \(rank), \(item.text)")
    }
}
