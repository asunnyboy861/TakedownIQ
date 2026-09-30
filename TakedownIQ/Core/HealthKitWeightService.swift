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
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                let kg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: kg * 2.20462)
            }
            self.store.execute(query)
        }
    }
}
