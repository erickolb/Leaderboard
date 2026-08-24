import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RankedList.createdAt, order: .reverse) private var lists: [RankedList]
    @State private var showingNewList = false
    @State private var newListTitle = ""
    @State private var showingAcknowledgements = false

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView {
                        Label("No Ranked Lists", systemImage: "list.number")
                    } description: {
                        Text("Create a list, add your choices, then drag them into order.")
                    } actions: {
                        Button("Create a List") { showingNewList = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink(value: list) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(list.title).font(.headline)
                                    Text(itemCount(for: list))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 3)
                            }
                        }
                        .onDelete(perform: deleteLists)
                    }
                }
            }
            .navigationTitle("AlbumRank")
            .navigationDestination(for: RankedList.self) { list in
                RankedListView(list: list)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingAcknowledgements = true
                        } label: {
                            Label("Acknowledgements", systemImage: "info.circle")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNewList = true } label: {
                        Label("New List", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAcknowledgements) {
                NavigationStack {
                    AcknowledgementsView()
                }
            }
            .alert("New Ranked List", isPresented: $showingNewList) {
                TextField("List name", text: $newListTitle)
                Button("Cancel", role: .cancel) { newListTitle = "" }
                Button("Create", action: createList)
                    .disabled(newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } message: {
                Text("Give this ranking a name.")
            }
        }
    }

    private func itemCount(for list: RankedList) -> String {
        let count = list.items.count
        return "\(count) \(count == 1 ? "item" : "items")"
    }

    private func createList() {
        let title = newListTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        modelContext.insert(RankedList(title: title))
        newListTitle = ""
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(lists[index]) }
    }
}
