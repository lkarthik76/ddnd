//
//  ContentView.swift
//  ddnd-watch-app Watch App
//
//  Created by Karthikeyan Lakshminarayanan on 22/06/25.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var monitor = HeartRateMonitor()
    @State private var riskLevel: String = "Loading..."
    @State private var lastUpdated: String = ""
    @State private var timeRemaining: Int = 60
    @State private var animateRisk = false
    @State private var refreshTimer: Timer?
    @State private var countdownTimer: Timer?

    var body: some View {
        VStack(spacing: 16) {
            // 🚗 Risk Block
            VStack(spacing: 4) {
                Text("🚗 Driving Risk")
                    .font(.headline)

                Text(riskLevel.capitalized)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(colorForRisk(riskLevel))
                    .scaleEffect(
                        animateRisk && riskLevel.lowercased() == "high"
                            ? 1.2 : 1.0
                    )
                    .animation(
                        .easeInOut(duration: 0.6).repeatCount(
                            3,
                            autoreverses: true
                        ),
                        value: animateRisk
                    )

                if !lastUpdated.isEmpty {
                    Text(lastUpdated)
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                Text("Refreshing in \(timeRemaining)s")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Divider()

            // ❤️ Heart Rate Block
            VStack(spacing: 4) {
                Text("❤️ Heart Rate")
                    .font(.headline)
                Text("\(Int(monitor.heartRate)) BPM")
                    .font(.title)
                    .foregroundColor(.red)
            }

        }
        .onAppear {
            startTimers()
            fetchRisk()
        }
        .onDisappear {
            refreshTimer?.invalidate()
            countdownTimer?.invalidate()
        }
        .padding()
    }

    // MARK: - Color Logic
    func colorForRisk(_ risk: String) -> Color {
        switch risk.lowercased() {
        case "high": return .red
        case "moderate": return .orange
        case "normal": return .green
        default: return .gray
        }
    }

    // MARK: - Risk Fetch + Animation + Haptics
    private func fetchRisk() {
        RiskService().fetchLatestRisk { risk, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Risk fetch error:", error.localizedDescription)
                }
                if let risk = risk {
                    if risk != self.riskLevel && risk.lowercased() == "high" {
                        // Trigger haptic feedback for high risk
                        WKInterfaceDevice.current().play(.notification)
                    }

                    self.riskLevel = risk
                    self.animateRisk = true
                    let formatter = DateFormatter()
                    formatter.timeStyle = .short
                    self.lastUpdated =
                        "Updated: \(formatter.string(from: Date()))"
                } else {
                    self.riskLevel = "Unavailable"
                    self.lastUpdated = ""
                }

                // Stop animation after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.animateRisk = false
                }
            }
        }
    }

    // MARK: - Refresh + Countdown
    private func startTimers() {
        // Refresh risk data every 60 sec
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 60.0,
            repeats: true
        ) { _ in
            self.fetchRisk()
            self.timeRemaining = 60
        }

        // Countdown every 1 sec
        countdownTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0,
            repeats: true
        ) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            }
        }
    }
}
