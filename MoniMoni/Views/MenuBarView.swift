import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()
                .padding(.vertical, 6)

            metricsList

            Divider()
                .padding(.vertical, 6)

            pollingIntervalPicker

            Divider()
                .padding(.vertical, 6)

            footer
        }
        .padding(12)
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("MoniMoni")
                .font(.headline)
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("MoniMoni")
    }

    private var metricsList: some View {
        VStack(spacing: 4) {
            ForEach(MetricType.allCases) { type in
                MetricRow(
                    type: type,
                    valueText: monitor.metrics.detailText(for: type),
                    isSelected: monitor.selectedMetric == type
                ) {
                    monitor.selectedMetric = type
                }
            }
        }
    }

    private var pollingIntervalPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Polling Interval")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Polling Interval", selection: $monitor.refreshInterval) {
                Text("1 second").tag(1.0)
                Text("2 seconds").tag(2.0)
                Text("5 seconds").tag(5.0)
                Text("10 seconds").tag(10.0)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .accessibilityLabel("Polling Interval")
            .accessibilityValue(pollingIntervalAccessibilityValue)
        }
    }

    private var pollingIntervalAccessibilityValue: String {
        let seconds = Int(monitor.refreshInterval)
        return seconds == 1 ? "1 second" : "\(seconds) seconds"
    }

    private var footer: some View {
        HStack {
            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
            .accessibilityLabel("Quit MoniMoni")
        }
    }
}

private struct MetricRow: View {
    let type: MetricType
    let valueText: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 10) {
                Image(systemName: type.systemImage)
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .accessibilityHidden(true)

                Text(type.title)
                    .foregroundStyle(.primary)

                Spacer()

                Text(valueText)
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Tap to show in menu bar")
        .accessibilityLabel(type.title)
        .accessibilityValue(valueText)
        .accessibilityHint("Shows this metric in the menu bar")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    MenuBarView(monitor: SystemMonitor())
}
