#!/usr/bin/env swift
//
// Generates the Smart Menu app icon: the same square "tank" gauge used in the
// menu bar, filled to 70%, on a rounded accent background. Re-run after tweaking
// the look:  swift scripts/make-appicon.swift
//
import SwiftUI
import AppKit

let fillFraction: CGFloat = 0.70

/// The icon artwork, drawn proportionally so it renders crisp at every size.
struct IconView: View {
    var body: some View {
        GeometryReader { geo in
            let s = geo.size.width
            let margin = s * 0.10                 // transparent breathing room
            let bg = s - margin * 2               // rounded background square
            let bgCorner = bg * 0.2237            // macOS "squircle" ratio
            let gauge = bg * 0.52                  // the square glyph size
            let gaugeCorner = gauge * 0.22
            let line = gauge * 0.085

            ZStack {
                RoundedRectangle(cornerRadius: bgCorner, style: .continuous)
                    .fill(LinearGradient(
                        // #813B7C, with a lighter top and darker bottom for depth.
                        colors: [Color(red: 0.60, green: 0.30, blue: 0.58),
                                 Color(red: 0.42, green: 0.16, blue: 0.40)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: bg, height: bg)

                ZStack {
                    // Bottom `fillFraction` of the square, solid.
                    RoundedRectangle(cornerRadius: gaugeCorner, style: .continuous)
                        .fill(Color.white)
                        .mask(alignment: .bottom) {
                            Rectangle().frame(height: gauge * fillFraction)
                        }
                    // Outline so the empty top still reads as a frame.
                    RoundedRectangle(cornerRadius: gaugeCorner, style: .continuous)
                        .strokeBorder(Color.white, lineWidth: line)
                }
                .frame(width: gauge, height: gauge)
            }
            .frame(width: s, height: s)
        }
    }
}

@MainActor
func png(size: CGFloat) -> Data {
    let renderer = ImageRenderer(content: IconView().frame(width: size, height: size))
    renderer.scale = 1
    guard let cg = renderer.cgImage else { fatalError("render failed at \(size)") }
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: size, height: size)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        fatalError("png encode failed at \(size)")
    }
    return data
}

// macOS AppIcon entries: (filename, pixel size, idiom-size, scale).
let entries: [(name: String, px: CGFloat, size: String, scale: String)] = [
    ("icon_16.png",   16,  "16x16",   "1x"),
    ("icon_32.png",   32,  "16x16",   "2x"),
    ("icon_32.png",   32,  "32x32",   "1x"),
    ("icon_64.png",   64,  "32x32",   "2x"),
    ("icon_128.png",  128, "128x128", "1x"),
    ("icon_256.png",  256, "128x128", "2x"),
    ("icon_256.png",  256, "256x256", "1x"),
    ("icon_512.png",  512, "256x256", "2x"),
    ("icon_512.png",  512, "512x512", "1x"),
    ("icon_1024.png", 1024,"512x512", "2x"),
]

let outDir = "SmartMenu/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// Write each unique PNG once.
let uniqueSizes = Set(entries.map { $0.px })
for px in uniqueSizes.sorted() {
    let name = entries.first { $0.px == px }!.name
    let data = MainActor.assumeIsolated { png(size: px) }
    try! data.write(to: URL(fileURLWithPath: "\(outDir)/\(name)"))
    print("wrote \(name) (\(Int(px))px)")
}

// Contents.json
let images = entries.map { e in
    "    { \"filename\" : \"\(e.name)\", \"idiom\" : \"mac\", \"scale\" : \"\(e.scale)\", \"size\" : \"\(e.size)\" }"
}.joined(separator: ",\n")
let contents = """
{
  "images" : [
\(images)
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try! contents.write(toFile: "\(outDir)/Contents.json", atomically: true, encoding: .utf8)
print("wrote Contents.json")
