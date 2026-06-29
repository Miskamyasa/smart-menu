import SwiftUI

@MainActor
final class SmartStatusModel: ObservableObject {
    @Published private(set) var fields: [SMARTField] = []
    @Published private(set) var errorMessage: String?

    func refresh() {
        do {
            fields = try DiskService.read()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct SmartStatusView: View {
    @ObservedObject var memory: MemoryMonitor
    @StateObject private var model = SmartStatusModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            VStack(alignment: .leading, spacing: 18) {
                memorySection
                diskSection
            }
            .padding(14)

            Divider()

            footer
        }
        .frame(width: 420)
        // No fixed color scheme: semantic colors and materials throughout
        // follow the system Light/Dark appearance (and accent) automatically.
        .task { model.refresh() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.tint)
            Text("Smart Menu")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Memory

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Memory")

            HStack(alignment: .firstTextBaseline) {
                Text("\(memory.percent)%")
                    .font(.title3.weight(.semibold).monospacedDigit())
                Spacer()
                Text("\(memory.usedDescription) of \(memory.totalDescription)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            MemoryUsageBar(fraction: memory.usedFraction)
        }
    }

    // MARK: - Disk

    private var diskSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Disk")
            diskContent
        }
    }

    @ViewBuilder
    private var diskContent: some View {
        if let errorMessage = model.errorMessage {
            Label {
                Text(errorMessage)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.callout)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        } else {
            VStack(spacing: 0) {
                ForEach(Array(model.fields.enumerated()), id: \.element.id) { index, field in
                    SmartFieldRow(field: field)
                        .background(index.isMultiple(of: 2) ? Color.clear : Color.primary.opacity(0.04))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button { model.refresh() } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Spacer()

            Button { NSApplication.shared.terminate(nil) } label: {
                Label("Quit", systemImage: "power")
            }
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.secondary)
    }
}

private struct SmartFieldRow: View {
    let field: SMARTField

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(field.label)
                .font(.callout)
            Spacer(minLength: 16)
            Text(field.value)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }
}
