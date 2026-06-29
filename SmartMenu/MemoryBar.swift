import SwiftUI
import AppKit

/// The `app` SF Symbol (a rounded square) used as a tank that fills bottom-up
/// by `fraction`: the `app.fill` glyph is clipped to the bottom portion and
/// the `app` outline is drawn on top so the empty part still reads as a frame.
struct MemorySquare: View {
    var fraction: Double

    var body: some View {
        ZStack {
            Image(systemName: "app.fill")
                .mask {
                    GeometryReader { geometry in
                        Rectangle()
                            .frame(height: geometry.size.height * fraction)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
            Image(systemName: "app")
        }
        .foregroundStyle(.primary)
        .accessibilityLabel("Memory usage \(Int((fraction * 100).rounded())) percent")
    }
}

/// A flat horizontal usage bar for inside the panel — no battery chrome,
/// just a track and a pressure-colored fill.
struct MemoryUsageBar: View {
    var fraction: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(memoryPressureColor(for: fraction))
                    .frame(width: max(4, geometry.size.width * fraction))
            }
        }
        .frame(height: 6)
    }
}

/// `MenuBarExtra` only renders `Text`/`Image` labels reliably — a raw SwiftUI
/// shape comes out blank. So we rasterize the gauge to a template `NSImage`,
/// which the menu bar tints to match its appearance (Light/Dark) automatically.
@MainActor
enum MenuBarGauge {
    static func image(fraction: Double) -> NSImage {
        let renderer = ImageRenderer(content:
            MemorySquare(fraction: fraction)
                .font(.system(size: 15, weight: .regular))
                .frame(width: 16, height: 16)
        )
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let image = renderer.nsImage else { return NSImage() }
        image.isTemplate = true
        return image
    }
}
