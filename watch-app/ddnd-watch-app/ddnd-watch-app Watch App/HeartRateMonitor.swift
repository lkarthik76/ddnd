//
//  HeartRateMonitor.swift
//  ddnd-watch-app
//
//  Created by Karthikeyan Lakshminarayanan on 09/06/25.
//

import Combine
import Foundation
import HealthKit
import WatchKit

class HeartRateMonitor: NSObject, ObservableObject, HKWorkoutSessionDelegate,
    HKLiveWorkoutBuilderDelegate
{

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var runtimeSession: WKExtendedRuntimeSession?
    private var uploadTimer: Timer?

    @Published var heartRate: Double = 0.0

    override init() {
        super.init()
        requestAuthorization()
    }

    private func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(
            toShare: typesToShare,
            read: typesToRead
        ) {
            success,
            error in
            if success {
                print("HealthKit authorization granted.")
                DispatchQueue.main.async {
                    self.startWorkoutSession()
                    self.startBackgroundSession()
                    self.debugFetchPastHeartRates()
                }
            } else if let error = error {
                print("❌ Authorization failed: \(error.localizedDescription)")
            }
        }

    }

    private func startWorkoutSession() {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .other
        configuration.locationType = .outdoor
        do {
            session = try HKWorkoutSession(
                healthStore: healthStore,
                configuration: configuration
            )
            builder = session?.associatedWorkoutBuilder()

            session?.delegate = self
            builder?.delegate = self

            builder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )
            print("🚀 Attempting to start session...")
            session?.startActivity(with: Date())
            print("✅ Called startActivity()")
            builder?.beginCollection(withStart: Date()) { success, error in
                if !success, let error = error {
                    print(
                        "❌ beginCollection error: \(error.localizedDescription)"
                    )
                } else {
                    print("✅ beginCollection successful")
                }
            }
        } catch {
            print(
                "❌ Failed to start workout session: \(error.localizedDescription)"
            )
        }
    }

    private func startBackgroundSession() {
        runtimeSession = WKExtendedRuntimeSession()
        runtimeSession?.delegate = self
        runtimeSession?.start()
        print("⏳ Started extended runtime session")
    }

    private func debugFetchPastHeartRates() {
        let type = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-300),  // last 5 minutes
            end: nil,
            options: .strictStartDate
        )

        let query = HKSampleQuery(
            sampleType: type,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [
                NSSortDescriptor(
                    key: HKSampleSortIdentifierStartDate,
                    ascending: false
                )
            ]
        ) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample] else {
                print(
                    "❌ SampleQuery error: \(error?.localizedDescription ?? "unknown error")"
                )
                return
            }

            if samples.isEmpty {
                print("⚠️ No past HR samples found.")
            }

            for sample in samples {
                let bpm = sample.quantity.doubleValue(
                    for: HKUnit(from: "count/min")
                )
                print("📦 [PAST] HR Sample: \(bpm) BPM at \(sample.startDate)")
            }
        }

        healthStore.execute(query)
    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        print(
            "🌀 Workout state changed: \(fromState.rawValue) → \(toState.rawValue)"
        )

        switch toState {
        case .running:
            print("✅ Workout is now RUNNING")
        case .ended:
            print("🛑 Workout ended")
        case .notStarted:
            print("🚫 Workout not started")
        case .paused:
            print("⏸️ Workout paused")
        case .prepared:
            print("🔄 Workout is prepared")
        case .stopped:
            print("❌ Workout stopped")
        @unknown default:
            print("❓ Unknown workout state")
        }

    }

    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: any Error
    ) {
        print("❌ Workout session error: \(error.localizedDescription)")
    }

    func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        print(
            "📥 didCollectDataOf called with: \(collectedTypes.map { $0.identifier })"
        )

        for type in collectedTypes {
            print("📦 Collected: \(type.identifier)")
        }

        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        guard collectedTypes.contains(hrType) else {
            print("⚠️ No HR type in collectedTypes")
            return
        }

        if let statistics = workoutBuilder.statistics(
            for: HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ),
            let quantity = statistics.mostRecentQuantity()
        {

            let bpm = quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("❤️ HR: \(bpm)")
            DispatchQueue.main.async {
                self.heartRate = bpm
                print("❤️ Updated HR: \(bpm)")
            }
        } else {
            print("⚠️ No heart rate quantity found.")
        }
    }

    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    private func unit(for identifier: HKQuantityTypeIdentifier) -> HKUnit {
        switch identifier {
        case .heartRate:
            return .count().unitDivided(by: .minute())
        case .stepCount:
            return .count()
        case .activeEnergyBurned:
            return .kilocalorie()
        default:
            return .count()
        }
    }

    private func collectLiveHealthDataFromBuilder() -> [String: [Any]] {
        let builderStats: [HKQuantityTypeIdentifier: String] = [
            .heartRate: "hr",
            .stepCount: "sc",
            .activeEnergyBurned: "ae",
        ]

        var liveData: [String: [Any]] = [:]

        for (identifier, key) in builderStats {
            guard
                let quantityType = HKQuantityType.quantityType(
                    forIdentifier: identifier
                ),
                let stats = builder?.statistics(for: quantityType),
                let quantity = stats.mostRecentQuantity(),
                let date = stats.mostRecentQuantityDateInterval()?.start
            else { continue }

            let value = quantity.doubleValue(for: unit(for: identifier))
            liveData[key] = [value, ISO8601DateFormatter().string(from: date)]
        }

        return liveData
    }

    private func collectLatestHealthData(
        completion: @escaping ([String: [Any]]) -> Void
    ) {
        var results: [String: [Any]] = [:]
        let group = DispatchGroup()

        let typeMap: [HKQuantityTypeIdentifier: String] = [
            .heartRate: "hr",
            .heartRateVariabilitySDNN: "hrv",
            .oxygenSaturation: "bo",
            .respiratoryRate: "rr",
            .stepCount: "sc",
            .activeEnergyBurned: "ae",
        ]

        for identifier in typeMap.keys {
            guard
                let quantityType = HKQuantityType.quantityType(
                    forIdentifier: identifier
                )
            else { continue }

            let predicate = HKQuery.predicateForSamples(
                withStart: Date().addingTimeInterval(-3600),
                end: nil,
                options: .strictStartDate
            )

            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [
                    NSSortDescriptor(
                        key: HKSampleSortIdentifierStartDate,
                        ascending: false
                    )
                ]
            ) { _, samples, _ in
                if let sample = samples?.first as? HKQuantitySample {
                    var value: Double
                    if identifier == .oxygenSaturation {
                        value =
                            sample.quantity.doubleValue(for: .percent()) * 100
                    } else if identifier == .stepCount {
                        value = sample.quantity.doubleValue(for: .count())
                    } else if identifier == .activeEnergyBurned {
                        value = sample.quantity.doubleValue(for: .kilocalorie())
                    } else {
                        value = sample.quantity.doubleValue(
                            for: .count().unitDivided(by: .minute())
                        )
                    }

                    results[typeMap[identifier]!] = [
                        value,
                        ISO8601DateFormatter().string(from: sample.startDate),
                    ]
                }
                group.leave()
            }

            group.enter()
            healthStore.execute(query)
        }

        group.notify(queue: .main) {
            completion(results)
        }
    }

    private func sendHealthDataToAWS(healthData: [String: [Any]]) {
        guard
            let url = URL(
                string:
                    "https://x3lurwrtk3.execute-api.us-east-1.amazonaws.com/prod/health"
            )
        else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = UserSession.current
        
        let payload: [String: Any] = [
            "uid": session.shortUserId,// short_user_id
            "did": session.driverId, // driver_id
            "ts": ISO8601DateFormatter().string(from: Date()),
            "dt": "apple_watch", // short for device_type = apple_watch
            "hd": healthData, // short for health_data
        ]

        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: payload,
                options: [.prettyPrinted]
            )
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 JSON Payload:\n\(jsonString)")
            }
            request.httpBody = jsonData
        } catch {
            print("❌ Failed to encode JSON")
            return
        }

        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("❌ Failed to send data: \(error.localizedDescription)")
            } else {
                print("✅ Health data sent")
            }
        }.resume()
    }

}

extension HeartRateMonitor: WKExtendedRuntimeSessionDelegate {
    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: (any Error)?
    ) {
        print(
            "🛑 Extended runtime session invalidated. Reason: \(reason.rawValue)"
        )
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")
        }
        uploadTimer?.invalidate()
    }

    func extendedRuntimeSessionDidStart(_ session: WKExtendedRuntimeSession) {
        print("✅ Extended runtime session started")

        uploadTimer = Timer.scheduledTimer(
            withTimeInterval: 10.0,
            repeats: true
        ) { _ in
            let liveData = self.collectLiveHealthDataFromBuilder()
            self.collectLatestHealthData { sampledData in
                var merged = liveData
                for (key, value) in sampledData where merged[key] == nil {
                    merged[key] = value
                }
                self.sendHealthDataToAWS(healthData: merged)
            }
        }
    }

    func extendedRuntimeSessionWillExpire(_ session: WKExtendedRuntimeSession) {
        print("⚠️ Extended runtime session will expire soon")
    }

}
