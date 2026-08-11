import Foundation

/// メニューバーに表示できる監視項目
enum MetricType: String, CaseIterable, Identifiable, Codable {
    case cpuTemperature
    case cpuUsage
    case gpuUsage
    case memoryUsage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cpuTemperature: return "CPU Temperature"
        case .cpuUsage: return "CPU Usage"
        case .gpuUsage: return "GPU Usage"
        case .memoryUsage: return "Memory Usage"
        }
    }

    var shortTitle: String {
        switch self {
        case .cpuTemperature: return "CPU℃"
        case .cpuUsage: return "CPU%"
        case .gpuUsage: return "GPU%"
        case .memoryUsage: return "MEM%"
        }
    }

    var unit: String {
        switch self {
        case .cpuTemperature: return "℃"
        case .cpuUsage, .gpuUsage, .memoryUsage: return "%"
        }
    }

    var systemImage: String {
        switch self {
        case .cpuTemperature: return "thermometer.medium"
        case .cpuUsage: return "cpu"
        case .gpuUsage: return "display"
        case .memoryUsage: return "memorychip"
        }
    }
}
