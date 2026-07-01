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
    @Published var infoMessage: String?
    /// 상품 목록을 불러오지 못한 경우(네트워크/스토어 오류) — Paywall에서 재시도 UI 표시
    @Published var loadFailed: Bool = false

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
        loadFailed = false
        do {
            let fetched = try await Product.products(for: Self.allIds)
            products = fetched.sorted {
                (Self.allIds.firstIndex(of: $0.id) ?? 0) < (Self.allIds.firstIndex(of: $1.id) ?? 0)
            }
            loadFailed = products.isEmpty
        } catch {
            print("[StoreKit] loadProducts 오류: \(error)")
            loadFailed = true
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let tx):
                    await refreshStatus()
                    await tx.finish()
                case .unverified(let tx, _):
                    // 검증 실패 트랜잭션도 정리해 결제 큐에 쌓이지 않도록 처리
                    await tx.finish()
                    purchaseError = "구매를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요."
                }
            case .pending:
                // Ask to Buy / 결제 승인 대기 등
                infoMessage = "구매 요청이 접수되었습니다. 승인이 완료되면 자동으로 잠금이 해제됩니다."
            case .userCancelled:
                break // 사용자가 취소 — 오류 아님
            @unknown default:
                break
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
            if !isPremium {
                infoMessage = "복원할 구매 내역이 없습니다."
            }
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
