import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let monthlyID = "com.takedowniq.pro.monthly"
    static let yearlyID = "com.takedowniq.pro.yearly"
    static let seasonPassID = "com.takedowniq.season.pass"
    static let allIDs = [monthlyID, yearlyID, seasonPassID]

    @Published var isPro = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?
    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await refreshEntitlements() }
    }

    deinit { transactionListener?.cancel() }

    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var seasonProduct: Product? { products.first { $0.id == Self.seasonPassID } }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: Self.allIDs)
                .sorted { $0.price < $1.price }
            loadError = products.isEmpty ? "Purchase options are loading. Check back soon." : nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        var pro = false
        for id in [Self.monthlyID, Self.yearlyID] {
            if let result = await Transaction.currentEntitlement(for: id),
               case .verified(let transaction) = result,
               transaction.revocationDate == nil {
                pro = true
            }
        }
        if await seasonPassEntitlementActive() {
            pro = true
        }
        isPro = pro
    }

    private func seasonPassEntitlementActive() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.seasonPassID,
               transaction.revocationDate == nil {
                if let expiry = transaction.expirationDate {
                    return expiry > Date()
                }
                let ninetyDays: TimeInterval = 90 * 24 * 3600
                return transaction.purchaseDate.addingTimeInterval(ninetyDays) > Date()
            }
        }
        return false
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.refreshEntitlements()
                    }
                }
            }
        }
    }
}
