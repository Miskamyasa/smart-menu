import Foundation
import SwiftUI

@MainActor
final class MemoryMonitor: ObservableObject {
    @Published private(set) var usedBytes: UInt64 = 0
    @Published private(set) var totalBytes: UInt64 = ProcessInfo.processInfo.physicalMemory

    private var timer: Timer?

    var usedFraction: Double {
        guard totalBytes > 0 else { return 0 }
        return min(1, max(0, Double(usedBytes) / Double(totalBytes)))
    }

    var percent: Int { Int((usedFraction * 100).rounded()) }

    var usedDescription: String { Self.formatter.string(fromByteCount: Int64(usedBytes)) }
    var totalDescription: String { Self.formatter.string(fromByteCount: Int64(totalBytes)) }

    init() {
        start()
    }

    func start() {
        guard timer == nil else { return }
        sample()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Matches Activity Monitor's "Memory Used" = App Memory + Wired + Compressed,
    /// where App Memory = internal (anonymous) pages minus purgeable pages.
    private func sample() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        let pageSize = UInt64(vm_kernel_page_size)
        let appMemory = UInt64(stats.internal_page_count) - UInt64(stats.purgeable_count)
        let wired = UInt64(stats.wire_count)
        let compressed = UInt64(stats.compressor_page_count)
        usedBytes = (appMemory + wired + compressed) * pageSize
    }

    private static let formatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.allowedUnits = [.useGB, .useMB]
        return formatter
    }()
}

/// Color cue shared by the menu-bar gauge and the in-panel bar.
/// `.primary` until memory pressure climbs, then warns — adapts to the
/// system appearance automatically.
func memoryPressureColor(for fraction: Double) -> Color {
    switch fraction {
    case ..<0.75: return .primary
    case ..<0.90: return .orange
    default: return .red
    }
}
