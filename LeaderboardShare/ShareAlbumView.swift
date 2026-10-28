import LinkPresentation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ShareAlbumView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\RankedList.sortOrder), SortDescriptor(\RankedList.createdAt, order: .reverse)]) private var lists: [RankedList]

    let extensionContext: NSExtensionContext?

    @State private var albumText = ""
    @State private var selectedListID: UUID?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Album") {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Reading shared album…")
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        TextField("Artist — Album", text: $albumText, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }

                Section("Add to") {
                    if lists.isEmpty {
                        Text("Create a list in Leaderboard first.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Ranked list", selection: $selectedListID) {
                            Text("Choose a list").tag(nil as UUID?)
                            ForEach(lists) { list in
                                Text(list.title).tag(list.id as UUID?)
                            }
                        }
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addAlbum() }
                        .disabled(isLoading || trimmedAlbumText.isEmpty || selectedListID == nil)
                }
            }
        }
        .task { await loadSharedAlbum() }
    }

    private var trimmedAlbumText: String {
        albumText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @MainActor
    private func loadSharedAlbum() async {
        guard let inputItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            isLoading = false
            errorMessage = "No shared album information was found."
            return
        }

        var textCandidates: [String] = []
        var sharedURL: URL?

        for item in inputItems {
            if let title = item.attributedTitle?.string { textCandidates.append(title) }
            if let content = item.attributedContentText?.string { textCandidates.append(content) }

            for provider in item.attachments ?? [] {
                if let name = provider.suggestedName { textCandidates.append(name) }
                if sharedURL == nil,
                   provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let value = try? await provider.sharedItem(for: UTType.url.identifier),
                   let url = value as? URL {
                    sharedURL = url
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                   let value = try? await provider.sharedItem(for: UTType.plainText.identifier),
                   let text = value as? String {
                    textCandidates.append(text)
                }
            }
        }

        if let sharedURL,
           let metadata = try? await LPMetadataProvider().startFetchingMetadata(for: sharedURL),
           let title = metadata.title {
            textCandidates.insert(title, at: 0)
        }

        albumText = AlbumTextParser.bestAlbumText(from: textCandidates)
        if albumText.isEmpty {
            errorMessage = "Album details weren’t detected. Enter the artist and album manually."
        }
        isLoading = false
    }

    private func addAlbum() {
        guard let selectedListID,
              let list = lists.first(where: { $0.id == selectedListID }),
              !trimmedAlbumText.isEmpty else { return }

        let item = RankedItem(text: trimmedAlbumText, rank: list.items.count)
        modelContext.insert(item)
        list.items.append(item)

        do {
            try modelContext.save()
            extensionContext?.completeRequest(returningItems: nil)
        } catch {
            errorMessage = "The album couldn’t be added. Please try again."
        }
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: CancellationError())
    }
}

private extension NSItemProvider {
    func sharedItem(for typeIdentifier: String) async throws -> NSSecureCoding? {
        try await withCheckedThrowingContinuation { continuation in
            loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: item) }
            }
        }
    }
}
