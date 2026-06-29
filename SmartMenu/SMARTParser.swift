import Foundation

struct SMARTField: Identifiable, Equatable {
    let label: String
    let value: String

    var id: String { label }
}

enum SMARTParser {
    static let labels = [
        "Model Number",
        "Temperature",
        "Data Units Read",
        "Data Units Written",
        "Power Cycles",
        "Power On Hours",
        "Unsafe Shutdowns",
        "Media and Data Integrity Errors",
        "Error Information Log Entries"
    ]

    static func parse(_ output: String) -> [SMARTField] {
        let parsed = Dictionary(uniqueKeysWithValues: output.split(whereSeparator: \ .isNewline).compactMap { rawLine -> (String, String)? in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let label = labels.first(where: { line.hasPrefix($0 + ":") }) else { return nil }
            let value = String(line.dropFirst(label.count + 1)).trimmingCharacters(in: .whitespaces)
            return (label, value.isEmpty ? "—" : value)
        })

        return labels.map { SMARTField(label: $0, value: parsed[$0] ?? "—") }
    }
}
