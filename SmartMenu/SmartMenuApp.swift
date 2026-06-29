import SwiftUI

@main
struct SmartMenuApp: App {
    var body: some Scene {
        MenuBarExtra("Smart Menu", systemImage: "externaldrive") {
            SmartStatusView()
        }
        .menuBarExtraStyle(.window)
    }
}
