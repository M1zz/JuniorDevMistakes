import StoreKit

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product IDs
    static let monthlyId  = "com.leeo.JuniorDevMistakes.pro.monthly"
    static let yearlyId   = "com.leeo.JuniorDevMistakes.pro.yearly"
    static let lifetimeId = "com.leeo.JuniorDevMistakes.pro.lifetime"
    static let allIds     = [monthlyId, yearlyId, lifetimeId]

    /// 첫 N개 카테고리(0-indexed)는 무료
    static let freeCategoryLimit = 3

    // MARK: - Published State
    @Published var products: [Product] = []
    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var purchaseError: String?

    private let premiumKey = "isPremiumUnlocked"
    private var updateTask: Task<Void, Never>?

    init() {
        isPremium = UserDefaults.standard.bool(forKey: premiumKey)
        updateTask = startListening()
        Task {
            await loadProducts()
            await refreshStatus()
        }
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            let fetched = try await Product.products(for: Self.allIds)
            products = fetched.sorted {
                (Self.allIds.firstIndex(of: $0.id) ?? 0) < (Self.allIds.firstIndex(of: $1.id) ?? 0)
            }
        } catch {
            print("[StoreKit] loadProducts 오류: \(error)")
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result,
               case .verified(let tx) = verification {
                await refreshStatus()
                await tx.finish()
            }
        } catch {
            purchaseError = "구매 중 오류가 발생했습니다."
        }
    }

    // MARK: - Restore
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshStatus()
        } catch {
            purchaseError = "구매 복원에 실패했습니다."
        }
    }

    // MARK: - Status Refresh
    func refreshStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  Self.allIds.contains(tx.productID),
                  tx.revocationDate == nil else { continue }
            if let exp = tx.expirationDate {
                if exp > Date() { active = true }
            } else {
                active = true // 평생 이용권
            }
        }
        setPremium(active)
    }

    // MARK: - Category Access
    func isCategoryLocked(_ categoryId: Int) -> Bool {
        !isPremium && categoryId >= Self.freeCategoryLimit
    }

    // MARK: - Helpers
    private func setPremium(_ value: Bool) {
        isPremium = value
        UserDefaults.standard.set(value, forKey: premiumKey)
    }

    private func startListening() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await refreshStatus()
                    await tx.finish()
                }
            }
        }
    }
}
