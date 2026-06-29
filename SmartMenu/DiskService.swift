import Foundation

/// Bridges the Objective-C IOKit reader into Swift display fields.
enum DiskService {
    static func read() throws -> [SMARTField] {
        let reading = try DiskSMART.read()
        return DiskInfo.fields(from: DiskSMARTSnapshot(reading: reading))
    }
}

private extension DiskSMARTSnapshot {
    init(reading: DiskSMARTReading) {
        self.init(
            model: reading.model,
            temperatureKelvin: Int(reading.temperatureKelvin),
            availableSpare: Int(reading.availableSpare),
            percentageUsed: Int(reading.percentageUsed),
            dataUnitsRead: reading.dataUnitsRead,
            dataUnitsWritten: reading.dataUnitsWritten,
            powerCycles: reading.powerCycles,
            powerOnHours: reading.powerOnHours,
            unsafeShutdowns: reading.unsafeShutdowns,
            mediaErrors: reading.mediaErrors,
            errorLogEntries: reading.errorLogEntries
        )
    }
}
