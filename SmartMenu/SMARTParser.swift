import Foundation

struct SMARTField: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { label }
}

/// A pure-Swift view of the NVMe SMART log, decoupled from IOKit so the
/// display formatting can be unit-tested without hardware.
struct DiskSMARTSnapshot: Equatable {
    var model: String
    var temperatureKelvin: Int
    var availableSpare: Int
    var percentageUsed: Int
    var dataUnitsRead: UInt64
    var dataUnitsWritten: UInt64
    var powerCycles: UInt64
    var powerOnHours: UInt64
    var unsafeShutdowns: UInt64
    var mediaErrors: UInt64
    var errorLogEntries: UInt64
}

enum DiskInfo {
    static func fields(from snapshot: DiskSMARTSnapshot) -> [SMARTField] {
        [
            SMARTField(label: "Model Number", value: snapshot.model),
            SMARTField(label: "Temperature", value: "\(snapshot.temperatureKelvin - 273) Celsius"),
            SMARTField(label: "Used", value: "\(snapshot.percentageUsed)%"),
            SMARTField(label: "Available Spare", value: "\(snapshot.availableSpare)%"),
            SMARTField(label: "Data Units Read", value: dataUnits(snapshot.dataUnitsRead)),
            SMARTField(label: "Data Units Written", value: dataUnits(snapshot.dataUnitsWritten)),
            SMARTField(label: "Power Cycles", value: grouped(snapshot.powerCycles)),
            SMARTField(label: "Power On Hours", value: grouped(snapshot.powerOnHours)),
            SMARTField(label: "Unsafe Shutdowns", value: grouped(snapshot.unsafeShutdowns)),
            SMARTField(label: "Media and Data Integrity Errors", value: grouped(snapshot.mediaErrors)),
            SMARTField(label: "Error Information Log Entries", value: grouped(snapshot.errorLogEntries)),
        ]
    }

    /// NVMe reports data units in multiples of 512,000 bytes; show the raw
    /// count plus a human-readable TB total, matching `smartctl`'s style.
    static func dataUnits(_ units: UInt64) -> String {
        let terabytes = Double(units) * 512_000 / 1_000_000_000_000
        return "\(grouped(units)) [\(String(format: "%.1f", terabytes)) TB]"
    }

    static func grouped(_ value: UInt64) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US") // comma grouping, like smartctl
        return formatter
    }()
}
