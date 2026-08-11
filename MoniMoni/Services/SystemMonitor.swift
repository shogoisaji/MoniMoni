import Foundation
import Combine

/// 定期的にシステムメトリクスを収集する ObservableObject
@MainActor
final class SystemMonitor: ObservableObject {
    @Published private(set) var metrics: SystemMetrics = .empty
    @Published var selectedMetric: MetricType {
        didSet {
            userDefaults.set(selectedMetric.rawValue, forKey: Self.selectedMetricKey)
        }
    }
    @Published var refreshInterval: TimeInterval {
        didSet {
            userDefaults.set(refreshInterval, forKey: Self.refreshIntervalKey)
            restartTimer()
        }
    }

    private let sampler = MetricsSampler()
    private let userDefaults: UserDefaults

    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?
    static let selectedMetricKey = "selectedMetric"
    static let refreshIntervalKey = "refreshInterval"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let raw = userDefaults.string(forKey: Self.selectedMetricKey),
           let saved = MetricType(rawValue: raw) {
            selectedMetric = saved
        } else {
            selectedMetric = .cpuTemperature
        }

        let savedInterval = userDefaults.double(forKey: Self.refreshIntervalKey)
        refreshInterval = savedInterval > 0 ? savedInterval : 2.0

        // 初回の計測を開始し、以降はタイマーで更新する
        refresh()
        restartTimer()
    }

    deinit {
        refreshTask?.cancel()
        timer?.invalidate()
    }

    /// 計測はバックグラウンドのMetricsSamplerで行い、結果だけMainActorへ反映する。
    func refresh() {
        refreshTask?.cancel()
        let sampler = self.sampler
        refreshTask = Task { [weak self, sampler] in
            let next = await sampler.read()
            guard !Task.isCancelled else { return }
            self?.metrics = next
        }
    }

    var menuBarTitle: String {
        metrics.menuBarText(for: selectedMetric)
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(1.0, refreshInterval)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }
}

/// IOKit / Mach の同期APIをMainActorから分離するための直列サンプラー。
private actor MetricsSampler {
    private let cpuReader = CPUUsageReader()
    private let memoryReader = MemoryReader()
    private let smcReader = SMCReader()
    private let gpuReader = GPUUsageReader()

    func read() -> SystemMetrics {
        var next = SystemMetrics()
        next.cpuUsage = cpuReader.read()
        next.cpuTemperature = smcReader.readCPUTemperature()
        next.gpuUsage = gpuReader.read()
        next.memoryUsage = memoryReader.read()
        next.updatedAt = Date()
        return next
    }
}
