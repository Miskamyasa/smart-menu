import XCTest

final class SMARTParserTests: XCTestCase {
    func testParsesSelectedFieldsOnly() {
        let output = """
        Model Number:                       APPLE SSD AP1024Z
        Serial Number:                      ignored
        Temperature:                        36 Celsius
        Data Units Read:                    123,123,256 [63.0 TB]
        Data Units Written:                 45,000 [23.0 GB]
        Power Cycles:                       91
        Power On Hours:                     1,234
        Unsafe Shutdowns:                   4
        Media and Data Integrity Errors:    0
        Error Information Log Entries:      0
        """

        let fields = SMARTParser.parse(output)

        XCTAssertEqual(fields.map(\.label), SMARTParser.labels)
        XCTAssertEqual(fields.first { $0.label == "Model Number" }?.value, "APPLE SSD AP1024Z")
        XCTAssertEqual(fields.first { $0.label == "Data Units Read" }?.value, "123,123,256 [63.0 TB]")
        XCTAssertFalse(fields.contains { $0.label == "Serial Number" })
    }

    func testMissingFieldsUseEmDash() {
        let fields = SMARTParser.parse("Model Number: Test Drive")

        XCTAssertEqual(fields.first { $0.label == "Model Number" }?.value, "Test Drive")
        XCTAssertEqual(fields.first { $0.label == "Temperature" }?.value, "—")
    }
}
