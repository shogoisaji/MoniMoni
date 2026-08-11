import Foundation
import Testing
@testable import MoniMoni

struct CPUUsageReaderTests {
    @Test func firstReadReturnsNilBecauseBaselineIsMissing() {
        let reader = CPUUsageReader()
        #expect(reader.read() == nil)
    }

    @Test func secondReadReturnsNilOrValidPercent() {
        let reader = CPUUsageReader()
        _ = reader.read()

        // カウンタの更新タイミングに依存しないよう、短時間リトライする
        var usage: Double?
        for _ in 0..<10 {
            Thread.sleep(forTimeInterval: 0.02)
            if let value = reader.read() {
                usage = value
                break
            }
        }
        if let usage {
            #expect(usage >= 0)
            #expect(usage <= 100)
        }
    }

    @Test func successiveReadsStayWithinBounds() {
        let reader = CPUUsageReader()
        // 1 回目はベースライン確立のため nil
        #expect(reader.read() == nil)

        var samples: [Double] = []
        for _ in 0..<5 {
            // host CPU カウンタが進むよう少し待つ
            Thread.sleep(forTimeInterval: 0.05)
            if let value = reader.read() {
                samples.append(value)
                #expect(value >= 0 && value <= 100)
            }
        }

        // 実行環境によっては短時間にカウンタが進まないため、取得できた値だけ検証する。
        #expect(samples.allSatisfy { $0 >= 0 && $0 <= 100 })
    }

    @Test func percentageHandlesCounterWrap() {
        let previous = CPUUsageReader.Load(
            user: UInt32.max,
            system: 10,
            idle: 20,
            nice: 30
        )
        let current = CPUUsageReader.Load(
            user: 1,
            system: 11,
            idle: 21,
            nice: 31
        )

        #expect(CPUUsageReader.percentage(current: current, previous: previous) == 80)
    }
}
