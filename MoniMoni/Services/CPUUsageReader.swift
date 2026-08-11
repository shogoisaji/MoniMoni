import Darwin
import Foundation

/// host_statistics(HOST_CPU_LOAD_INFO) による CPU 使用率の取得
final class CPUUsageReader {
    struct Load: Equatable {
        let user: UInt32
        let system: UInt32
        let idle: UInt32
        let nice: UInt32

        init(user: UInt32, system: UInt32, idle: UInt32, nice: UInt32) {
            self.user = user
            self.system = system
            self.idle = idle
            self.nice = nice
        }

        init(_ info: host_cpu_load_info) {
            self.init(
                user: info.cpu_ticks.0,
                system: info.cpu_ticks.1,
                idle: info.cpu_ticks.2,
                nice: info.cpu_ticks.3
            )
        }
    }

    private var previousLoad: Load?

    func read() -> Double? {
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        var info = host_cpu_load_info()

        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics(host, HOST_CPU_LOAD_INFO, rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let currentLoad = Load(info)
        defer { previousLoad = currentLoad }

        guard let previous = previousLoad else { return nil }
        return Self.percentage(current: currentLoad, previous: previous)
    }

    /// 2回のスナップショットから使用率を計算する。UInt32カウンタのラップを許容する。
    static func percentage(current: Load, previous: Load) -> Double? {
        let user = Double(current.user &- previous.user)
        let system = Double(current.system &- previous.system)
        let idle = Double(current.idle &- previous.idle)
        let nice = Double(current.nice &- previous.nice)

        let total = user + system + idle + nice
        guard total > 0 else { return nil }

        let used = user + system + nice
        return min(100, max(0, (used / total) * 100))
    }
}
