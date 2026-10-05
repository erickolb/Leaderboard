import SwiftUI

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("App Icon") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Score board icons created by Magnific - Flaticon")
                    Link(
                        "View icon attribution on Flaticon",
                        destination: URL(string: "https://www.flaticon.com/free-icons/score-board")!
                    )
                }
                .padding(.vertical, 6)
            }
        }
        .navigationTitle("Acknowledgements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}
