import XCTest

final class DiskInfoTests: XCTestCase {
    private let sample = DiskSMARTSnapshot(
        model: "APPLE SSD AP1024Z",
        temperatureKelvin: 309,
        availableSpare: 100,
        percentageUsed: 3,
        dataUnitsRead: 123_123_256,
        dataUnitsWritten: 86_816_732,
        powerCycles: 293,
        powerOnHours: 1_566,
        unsafeShutdowns: 20,
        mediaErrors: 0,
        errorLogEntries: 0
    )

    func testExposesExpectedLabels() {
        let labels = DiskInfo.fields(from: sample).map(\.label)
        XCTAssertEqual(labels, [
            "Model Number", "Temperature", "Used", "Available Spare",
            "Data Units Read", "Data Units Written", "Power Cycles",
            "Power On Hours", "Unsafe Shutdowns",
            "Media and Data Integrity Errors", "Error Information Log Entries",
        ])
    }

    func testValueFormatting() {
        let fields = DiskInfo.fields(from: sample)
        func value(_ label: String) -> String? { fields.first { $0.label == label }?.value }

        XCTAssertEqual(value("Model Number"), "APPLE SSD AP1024Z")
        XCTAssertEqual(value("Temperature"), "36 Celsius")
        XCTAssertEqual(value("Used"), "3%")
        XCTAssertEqual(value("Available Spare"), "100%")
        XCTAssertEqual(value("Power On Hours"), "1,566")
    }

    func testDataUnitsConversion() {
        // 123,123,256 units × 512,000 bytes ≈ 63.0 TB.
        XCTAssertEqual(DiskInfo.dataUnits(123_123_256), "123,123,256 [63.0 TB]")
    }
}
