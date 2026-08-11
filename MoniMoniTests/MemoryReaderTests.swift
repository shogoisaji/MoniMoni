import Foundation
import Testing
@testable import MoniMoni

struct MemoryReaderTests {
    @Test func readReturnsPercentInValidRange() throws {
        let reader = MemoryReader()
        let usage = try #require(reader.read())

        #expect(usage >= 0)
        #expect(usage <= 100)
    }

    @Test func multipleReadsStayWithinBounds() throws {
        let reader = MemoryReader()
        let first = try #require(reader.read())
        let second = try #require(reader.read())

        #expect(first >= 0 && first <= 100)
        #expect(second >= 0 && second <= 100)
    }
}
