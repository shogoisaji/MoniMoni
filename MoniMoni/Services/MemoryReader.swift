import Darwin
import Foundation

/// 物理メモリの使用率（0–100%）を取得
final class MemoryReader {
    func read() -> Double? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let host = mach_host_self()
        defer { mach_port_deallocate(mach_task_self_, host) }

        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(host, HOST_VM_INFO64, rebound, &count)
            }
        }

        guard result == KERN_SUCCESS else { return nil }

        let pageSize = UInt64(vm_kernel_page_size)
        let total = ProcessInfo.processInfo.physicalMemory
        guard total > 0 else { return nil }

        // Activity Monitor に近い「使用中」: active + wired + compressed
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = min(total, active + wired + compressed)

        let percent = (Double(used) / Double(total)) * 100
        return min(100, max(0, percent))
    }
}
