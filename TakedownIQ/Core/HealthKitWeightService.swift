import Foundation
import HealthKit

final class HealthKitWeightService: ObservableObject {
    static let shared = HealthKitWeightService()
    private let store = HKHealthStore()
    private let bodyMassType = HKQuantityType(.bodyMass)

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    @Published var authorized = false

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [bodyMassType])
            await MainActor.run { self.authorized = true }
            return true
        } catch {
            return false
        }
    }

    func latestWeight() async -> Double? {
        guard isAvailable else { return nil }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Double?, Never>) in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 5, sortDescriptors: nil) { _, samples, _ in
                guard let sample = samples?.compactMap({ $0 as? HKQuantitySample }).max(by: { $0.endDate < $1.endDate }) else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: kg * 2.20462)
            }
            store.execute(query)
        }
    }
}
