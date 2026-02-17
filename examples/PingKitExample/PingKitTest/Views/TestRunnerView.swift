import SwiftUI

struct TestRunnerView: View {
    @AppStorage("apiKey") private var apiKey = ""
    @StateObject private var runner = TestRunner()

    var body: some View {
        List {
            if apiKey.isEmpty {
                Section {
                    Label("Configure an API key first", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            // Start / Run Again button
            Section {
                Button {
                    Task { await runner.runAll() }
                } label: {
                    HStack {
                        Spacer()
                        Label(
                            runner.results.isEmpty ? "Start Test Suite" : "Run Again",
                            systemImage: runner.results.isEmpty ? "play.fill" : "arrow.clockwise"
                        )
                        .font(.headline)
                        Spacer()
                    }
                }
                .disabled(runner.isRunning || apiKey.isEmpty)
            }

            // Progress
            if runner.isRunning {
                Section("Progress") {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(
                            value: Double(runner.completedCount),
                            total: Double(runner.totalTests)
                        )
                        Text("\(runner.completedCount)/\(runner.totalTests) — \(runner.currentTestName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Summary bar
            if !runner.results.isEmpty {
                Section("Summary") {
                    HStack(spacing: 16) {
                        SummaryPill(count: runner.passedCount, label: "Passed", color: .green)
                        SummaryPill(count: runner.failedCount, label: "Failed", color: .red)
                        SummaryPill(count: runner.skippedCount, label: "Skipped", color: .orange)
                        Spacer()
                    }
                }
            }

            // Grouped results
            ForEach(runner.groupedResults, id: \.0) { category, results in
                Section(category) {
                    ForEach(results) { result in
                        TestResultRow(result: result)
                    }
                }
            }
        }
        .navigationTitle("Test Runner")
        .animation(.default, value: runner.completedCount)
    }
}

// MARK: - Summary Pill

private struct SummaryPill: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Test Result Row

private struct TestResultRow: View {
    let result: TestResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                    Text(result.name)
                        .foregroundStyle(.primary)
                    Spacer()
                    if result.duration > 0 {
                        Text(String(format: "%.1fs", result.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(result.detail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(.top, 6)
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 2)
    }

    private var iconName: String {
        switch result.status {
        case .passed: "checkmark.circle.fill"
        case .failed: "xmark.circle.fill"
        case .skipped: "minus.circle.fill"
        }
    }

    private var iconColor: Color {
        switch result.status {
        case .passed: .green
        case .failed: .red
        case .skipped: .orange
        }
    }
}

#Preview {
    NavigationStack {
        TestRunnerView()
    }
}
