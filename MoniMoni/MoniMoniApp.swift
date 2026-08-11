import SwiftUI

@main
struct MoniMoniApp: App {
    @StateObject private var monitor = SystemMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            MenuBarLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
    }
}

/// メニューバーに表示する短いラベル
private struct MenuBarLabel: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: monitor.selectedMetric.systemImage)
            Text(monitor.menuBarTitle)
                .monospacedDigit()
        }
        .font(.system(size: 12, weight: .medium))
        .help(monitor.selectedMetric.title)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(monitor.selectedMetric.title), \(monitor.menuBarTitle)")
    }
}
