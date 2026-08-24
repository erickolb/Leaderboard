import SwiftUI

struct AcknowledgementsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("App Icon") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Dvd icons created by Magnific - Flaticon")
                    Link(
                        "View icon attribution on Flaticon",
                        destination: URL(string: "https://www.flaticon.com/free-icons/dvd")!
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
