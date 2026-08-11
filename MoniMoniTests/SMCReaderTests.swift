import Testing
@testable import MoniMoni

struct SMCReaderTests {
    @Test func openAndCloseAreIdempotent() {
        let reader = SMCReader()
        // CI / サンドボックス / 一部環境では AppleSMC が開けない
        _ = reader.open()
        reader.close()
        reader.close()
        _ = reader.open()
        reader.close()
    }

    @Test func readCPUTemperatureReturnsNilOrPlausibleCelsius() {
        let reader = SMCReader()
        defer { reader.close() }

        if let temperature = reader.readCPUTemperature() {
            #expect(temperature > 0)
            #expect(temperature < 150)
        }
    }

    @Test func decoderRejectsShortPayloads() {
        #expect(SMCReader.decodeTemperature(dataType: "sp78", bytes: [56]) == nil)
        #expect(SMCReader.decodeTemperature(dataType: "flt ", bytes: [0, 0, 0]) == nil)
        #expect(SMCReader.decodeTemperature(dataType: "ui16", bytes: [0]) == nil)
        #expect(SMCReader.decodeTemperature(dataType: "ui8 ", bytes: []) == nil)
    }

    @Test func decoderReadsSupportedPayloads() {
        #expect(SMCReader.decodeTemperature(dataType: "sp78", bytes: [56, 128]) == 56.5)
        #expect(SMCReader.decodeTemperature(dataType: "ui16", bytes: [0, 64]) == 64)
        #expect(SMCReader.decodeTemperature(dataType: "ui8 ", bytes: [42]) == 42)
    }
}
