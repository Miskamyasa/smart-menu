import SwiftUI

@main
struct SmartMenuApp: App {
    @StateObject private var memory = MemoryMonitor()

    var body: some Scene {
        MenuBarExtra {
            SmartStatusView(memory: memory)
        } label: {
            Image(nsImage: MenuBarGauge.image(fraction: memory.usedFraction))
        }
        .menuBarExtraStyle(.window)
    }
}
