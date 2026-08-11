import Foundation

struct SystemMetrics: Equatable {
    /// CPU 温度（℃）。取得できない場合は nil
    var cpuTemperature: Double?
    /// CPU 使用率 0–100
    var cpuUsage: Double?
    /// GPU 使用率 0–100
    var gpuUsage: Double?
    /// メモリ使用率 0–100
    var memoryUsage: Double?
    /// 最終更新時刻
    var updatedAt: Date = Date()

    static let empty = SystemMetrics()

    func value(for type: MetricType) -> Double? {
        switch type {
        case .cpuTemperature: return cpuTemperature
        case .cpuUsage: return cpuUsage
        case .gpuUsage: return gpuUsage
        case .memoryUsage: return memoryUsage
        }
    }

    /// メニューバー用の短い表示文字列
    func menuBarText(for type: MetricType) -> String {
        guard let value = value(for: type) else {
            return "—"
        }
        switch type {
        case .cpuTemperature:
            return String(format: "%.0f℃", value)
        case .cpuUsage, .gpuUsage, .memoryUsage:
            return String(format: "%.0f%%", value)
        }
    }

    /// 詳細行用の表示文字列
    func detailText(for type: MetricType) -> String {
        guard let value = value(for: type) else {
            return "Unavailable"
        }
        switch type {
        case .cpuTemperature:
            return String(format: "%.1f ℃", value)
        case .cpuUsage, .gpuUsage, .memoryUsage:
            return String(format: "%.1f %%", value)
        }
    }
}
