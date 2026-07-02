import Foundation
import StoreKit

@Observable
final class StoreManager {
    static let monthlyID = "com.noseyDewdrop.sunflower.pro.monthly"
    static let yearlyID = "com.noseyDewdrop.sunflower.pro.yearly"
    static let lifetimeID = "com.noseyDewdrop.sunflower.pro.lifetime"
    static let allIDs = [monthlyID, yearlyID, lifetimeID]

    var products: [Product] = []
    var isPro = false
    var purchaseError: String?
    var isLoading = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    @MainActor
    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: Self.allIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            purchaseError = "couldn't load products, check your connection"
        }
    }

    @MainActor
    func refreshEntitlements() async {
        var pro = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue,
               Self.allIDs.contains(transaction.productID) {
                pro = true
            }
        }
        isPro = pro
    }

    @MainActor
    func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if let transaction = try? verification.payloadValue {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled:
                break
            case .pending:
                purchaseError = "purchase is waiting for approval"
            @unknown default:
                break
            }
        } catch {
            purchaseError = "purchase failed, nothing was charged. try again"
        }
    }

    @MainActor
    func restore() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlements()
        if !isPro {
            purchaseError = "no previous purchase found"
        }
    }
}
