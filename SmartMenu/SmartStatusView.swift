import SwiftUI

@MainActor
final class SmartStatusModel: ObservableObject {
    @Published private(set) var fields = SMARTParser.parse("")
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    func refresh() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                fields = SMARTParser.parse(try await SmartctlRunner.run())
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}

struct SmartStatusView: View {
    @StateObject private var model = SmartStatusModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if model.isLoading {
                Text("Loading SMART data…")
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(model.fields) { field in
                HStack(alignment: .firstTextBaseline) {
                    Text(field.label)
                    Spacer(minLength: 16)
                    Text(field.value)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Divider()

            HStack {
                Button("Refresh") { model.refresh() }
                    .disabled(model.isLoading)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
            }
        }
        .frame(width: 420)
        .padding()
        .task { model.refresh() }
    }
}
