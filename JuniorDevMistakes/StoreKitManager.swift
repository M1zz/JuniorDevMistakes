import StoreKit
import LeeoKit

@MainActor
final class StoreKitManager: ObservableObject {

    // MARK: - Product IDs
    static let monthlyId  = "com.leeo.JuniorDevMistakes.pro.1monthly"
    static let yearlyId   = "com.leeo.JuniorDevMistakes.pro.1yearly"
    static let lifetimeId = "com.leeo.JuniorDevMistakes.pro.1lifetime"
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
            // 할인 배너가 첫 구독 할인을 받을 수 있는 사람인지 보려고 파는 상품을 알려 준다 (LeeoKit).
            LeeoSale.productIDs = Self.allIds
            let fetched = try await Product.products(for: Self.allIds)
            products = fetched.sorted {
                (Self.allIds.firstIndex(of: $0.id) ?? 0) < (Self.allIds.firstIndex(of: $1.id) ?? 0)
            }
            // 진단: 요청한 ID 중 실제로 돌아온 것과 누락된 것을 로그로 남김
            let returned = Set(fetched.map(\.id))
            let missing = Self.allIds.filter { !returned.contains($0) }
            print("[StoreKit] 요청 \(Self.allIds.count)개, 응답 \(fetched.count)개 → \(returned.sorted())")
            if !missing.isEmpty {
                print("[StoreKit] ⚠️ 누락된 상품 ID(ASC에서 조회 불가): \(missing)")
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
                    purchaseError = String(localized: "구매를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.")
                }
            case .pending:
                // Ask to Buy / 결제 승인 대기 등
                infoMessage = String(localized: "구매 요청이 접수되었습니다. 승인이 완료되면 자동으로 잠금이 해제됩니다.")
            case .userCancelled:
                break // 사용자가 취소 — 오류 아님
            @unknown default:
                break
            }
        } catch {
            purchaseError = String(localized: "구매 중 오류가 발생했습니다.")
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
                infoMessage = String(localized: "복원할 구매 내역이 없습니다.")
            }
        } catch {
            purchaseError = String(localized: "구매 복원에 실패했습니다.")
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
        if ScreenshotScene.current != nil { return }  // 스크린샷은 PRO 화면으로 고정
        isPremium = value
        UserDefaults.standard.set(value, forKey: premiumKey)
    }

    private func startListening() -> Task<Void, Never> {
        Task {
            for await result in Transaction.updates {
                // PRO 결제만 여기서 닫는다. 팁은 LeeoTipJar 가 세고 닫는다(기능을 열지 않는다).
                if case .verified(let tx) = result, Self.allIds.contains(tx.productID) {
                    await refreshStatus()
                    await tx.finish()
                }
            }
        }
    }
}

// MARK: - 팁 (LeeoKit)

/// LeeoKit 은 팁 화면에만 쓴다. PRO 결제는 위의 `StoreKitManager` 가 그대로 맡는다.
/// ⚠️ 여기서 bootstrap · 피드백 · 분석을 켜지 않는다 (백업 금고만 App.init 에서 직접 켠다) — 계약을 채우는 값일 뿐 아무것도 돌지 않는다.
enum JuniorDevMistakesSpec: LeeoAppSpec {
    static let appName = "실수100"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.leeo.JuniorDevMistakes"
    )
    static let legal = LeeoLegalConfig(
        privacyURL: URL(string: "https://m1zz.github.io/JuniorDevMistakes/privacy.html")!,
        supportURL: URL(string: "https://m1zz.github.io/JuniorDevMistakes/en/support.html")!
    )
    /// PRO 는 LeeoKit 밖(`StoreKitManager`)에 있다. LeeoKit 이 페이월을 그리지 않게 `.free` 로 둔다.
    static let monetization = LeeoMonetization.free
    /// 이미 PRO 인 사람이 조금 더 내고 싶을 때 내는 곳. 소모성 상품 셋, 작은 것부터.
    /// ⚠️ 기능을 여는 상품이 아니다 — `StoreKitManager.allIds` 에 넣지 않는다.
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.leeo.JuniorDevMistakes.tip.small",
        "com.leeo.JuniorDevMistakes.tip.medium",
        "com.leeo.JuniorDevMistakes.tip.large",
    ]))

    /// 선물 코드 링크에 들어가는 App Store 앱 번호.
    static let appStoreID: String? = "6759643878"

    /// PRO 선물하기. 보내는 사람은 소모성 선물 상품을 사고, App Store 오퍼 코드 링크를 받아 건넨다.
    /// 받는 사람은 링크를 누르거나 설정의 "선물 코드 입력" 에서 코드를 넣으면 평생 이용권이 열린다
    /// (오퍼 코드 결제는 `StoreKitManager` 의 결제 갱신으로 들어와 PRO 가 된다).
    /// ⚠️ 선물 상품은 `StoreKitManager.allIds` 에 넣지 않는다. 넣으면 선물을 산 사람이 PRO 가 된다.
    /// ⚠️ App Store Connect 에 선물 상품이 없으면 보내기 줄은 숨는다(`isAvailable`).
    ///    오퍼 코드 묶음은 FeedbackHub 의 "선물 코드 묶음" 에서 채운다.
    @MainActor static let gift = LeeoGiftStore(config: LeeoGiftConfig(
        productID: "com.leeo.JuniorDevMistakes.gift.pro",
        grantsProductID: StoreKitManager.lifetimeId,
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        sellsGifts: true,
        tierName: "PRO"
    ))
}

/// 팁을 부탁할 만한 순간 — 돌아본(경험했다고 체크한) 실수 수. 실수 하나를 체크할 때마다 는다.
enum JuniorDevMistakesTipMoments {
    /// 체크한 실수 수. 큰 것부터.
    static let checked = [100, 50, 20]

    /// 넘어선 순간, 인상적인 것부터.
    static func reached(checkedCount count: Int) -> [LeeoTipMoment] {
        checked.filter { count >= $0 }.map { threshold in
            LeeoTipMoment(id: "checked.\(threshold)",
                          message: String(localized: "지금까지 실수 \(count)개를 돌아봤어요",
                                          locale: AppLocale.display,
                                          comment: "Tip ask card: how many of the 100 mistakes the person has checked off"))
        }
    }
}
