import Foundation
import IOKit

/// IOAccelerator の PerformanceStatistics から GPU 使用率を取得
final class GPUUsageReader {
    func read() -> Double? {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")
        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard kr == KERN_SUCCESS else { return nil }
        defer { IOObjectRelease(iterator) }

        var samples: [Double] = []
        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            if let value = utilization(from: service) {
                samples.append(value)
            }
        }

        guard !samples.isEmpty else { return nil }
        // 複数 GPU / アクセラレータがある場合は最大値を表示
        return samples.max()
    }

    private func utilization(from service: io_registry_entry_t) -> Double? {
        var properties: Unmanaged<CFMutableDictionary>?
        let kr = IORegistryEntryCreateCFProperties(
            service,
            &properties,
            kCFAllocatorDefault,
            0
        )
        guard kr == KERN_SUCCESS, let dict = properties?.takeRetainedValue() as? [String: Any] else {
            return nil
        }

        if let stats = dict["PerformanceStatistics"] as? [String: Any] {
            // 単一キーで取れる場合はそれを優先
            let preferredKeys = [
                "Device Utilization %",
                "GPU Activity(%)"
            ]
            for key in preferredKeys {
                if let number = stats[key] as? NSNumber {
                    let value = number.doubleValue
                    if value >= 0 && value <= 100 {
                        return value
                    }
                }
            }

            // Apple Silicon では Renderer / Tiler の平均が有効なことが多い
            let renderer = (stats["Renderer Utilization %"] as? NSNumber)?.doubleValue
            let tiler = (stats["Tiler Utilization %"] as? NSNumber)?.doubleValue
            if let renderer, let tiler {
                return min(100, max(0, (renderer + tiler) / 2))
            }
            if let renderer { return min(100, max(0, renderer)) }
            if let tiler { return min(100, max(0, tiler)) }
        }

        return nil
    }
}
