import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var storeManager: StoreKitManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedId = StoreKitManager.yearlyId

    // App Review 3.1.2: 자동 갱신 구독 앱은 이용약관/개인정보처리방침 링크 필수
    private let termsURL = URL(string: "https://m1zz.github.io/JuniorDevMistakes/terms.html")!
    private let privacyURL = URL(string: "https://m1zz.github.io/JuniorDevMistakes/privacy.html")!

    private var selectedProduct: Product? {
        storeManager.products.first { $0.id == selectedId }
    }

    /// App Review 3.1.2: 선택된 상품의 제목·기간·가격·갱신 조건을 결제 버튼 근처에 명시
    private var selectedTermsLine: String? {
        guard let p = selectedProduct else { return nil }
        switch p.id {
        case StoreKitManager.monthlyId:
            return "월간 구독 · \(p.displayPrice)/월 · 매월 자동 갱신"
        case StoreKitManager.yearlyId:
            return "연간 구독 · \(p.displayPrice)/년 · 매년 자동 갱신"
        case StoreKitManager.lifetimeId:
            return "평생 이용권 · \(p.displayPrice) · 1회 결제, 자동 갱신 없음"
        default:
            return "\(p.displayName) · \(p.displayPrice)"
        }
    }

    private let featureItems: [(String, String)] = [
        ("lock.open.fill",          "카테고리 4-10 완전 잠금 해제"),
        ("number.circle.fill",      "실수 #031-100 전체 학습"),
        ("questionmark.bubble.fill","280개 추가 회고 질문"),
        ("chart.bar.fill",          "100개 완전한 성장 추적"),
        ("sparkles",                "향후 모든 콘텐츠 업데이트"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerView
                    featuresView
                    plansView
                    footerView
                }
                .padding(.bottom, 48)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color(.systemGray3))
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
        }
        .task {
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
        }
        .onChange(of: storeManager.isPremium) { _, newValue in
            if newValue { dismiss() }
        }
        .alert("오류", isPresented: Binding(
            get: { storeManager.purchaseError != nil },
            set: { if !$0 { storeManager.purchaseError = nil } }
        )) {
            Button("확인") { storeManager.purchaseError = nil }
        } message: {
            Text(storeManager.purchaseError ?? "")
        }
        .alert("안내", isPresented: Binding(
            get: { storeManager.infoMessage != nil },
            set: { if !$0 { storeManager.infoMessage = nil } }
        )) {
            Button("확인") { storeManager.infoMessage = nil }
        } message: {
            Text(storeManager.infoMessage ?? "")
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack {
            AppTheme.headerGradient
            Circle().fill(.white.opacity(0.06)).frame(width: 200, height: 200).offset(x: 100, y: -60)
            Circle().fill(.white.opacity(0.04)).frame(width: 140, height: 140).offset(x: -80, y: 50)

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(AppTheme.retroAmber)
                }

                VStack(spacing: 8) {
                    Text("PRO로 업그레이드")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("실수 70개가 더 기다리고 있어요\n지금 잠금을 해제하세요")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Features

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PRO 플랜 포함 내용")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                ForEach(Array(featureItems.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 34, height: 34)
                            Image(systemName: item.0)
                                .font(.system(size: 15))
                                .foregroundStyle(AppTheme.primary)
                        }
                        Text(item.1)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.actionGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)

                    if index < featureItems.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Plans

    private var plansView: some View {
        VStack(spacing: 12) {
            Text("플랜 선택")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 4)

            if storeManager.products.isEmpty {
                if storeManager.loadFailed {
                    VStack(spacing: 12) {
                        Text("상품 정보를 불러오지 못했습니다.\n네트워크 연결을 확인해 주세요.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                        Button {
                            Task { await storeManager.loadProducts() }
                        } label: {
                            Text("다시 시도")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.primary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                } else {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("상품 정보를 불러오는 중...")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(storeManager.products, id: \.id) { product in
                        ProductOptionCard(
                            product: product,
                            isSelected: selectedId == product.id,
                            isBestValue: product.id == StoreKitManager.yearlyId
                        ) {
                            withAnimation(.spring(response: 0.2)) {
                                selectedId = product.id
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            Button {
                guard let p = selectedProduct else { return }
                Task { await storeManager.purchase(p) }
            } label: {
                ZStack {
                    if storeManager.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("지금 시작하기")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    storeManager.products.isEmpty
                        ? AnyShapeStyle(Color(.systemGray4))
                        : AnyShapeStyle(AppTheme.headerGradient)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(storeManager.isLoading || storeManager.products.isEmpty)
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if let terms = selectedTermsLine {
                Text(terms)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        VStack(spacing: 10) {
            Button {
                Task { await storeManager.restorePurchases() }
            } label: {
                HStack(spacing: 6) {
                    if storeManager.isLoading {
                        ProgressView().scaleEffect(0.8)
                    }
                    Text("구매 복원하기")
                        .font(.system(size: 14, design: .rounded))
                }
                .foregroundStyle(AppTheme.primary)
            }

            Text("월간·연간 구독은 자동으로 갱신되며, 현재 기간 종료 24시간 전까지 취소하지 않으면 결제됩니다. 구독은 Apple ID 설정에서 언제든지 관리·취소할 수 있습니다.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)

            HStack(spacing: 8) {
                Link(destination: termsURL) {
                    Text("이용약관(EULA)").underline()
                }
                Text("·").foregroundStyle(.tertiary)
                Link(destination: privacyURL) {
                    Text("개인정보처리방침").underline()
                }
            }
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .tint(AppTheme.primary)
            .padding(.top, 6)
        }
        .padding(.top, 20)
    }
}

// MARK: - Product Option Card

struct ProductOptionCard: View {
    let product: Product
    let isSelected: Bool
    let isBestValue: Bool
    let onTap: () -> Void

    private var periodLabel: String {
        guard let sub = product.subscription else { return "" }
        switch sub.subscriptionPeriod.unit {
        case .month: return "/월"
        case .year:  return "/년"
        case .week:  return "/주"
        case .day:   return "/일"
        @unknown default: return ""
        }
    }

    private var titleLabel: String {
        switch product.id {
        case StoreKitManager.monthlyId:  return "월간 구독"
        case StoreKitManager.yearlyId:   return "연간 구독"
        case StoreKitManager.lifetimeId: return "평생 이용권"
        default: return product.displayName
        }
    }

    private var subtitleLabel: String? {
        switch product.id {
        case StoreKitManager.yearlyId:   return "월간 대비 최대 50% 절약"
        case StoreKitManager.lifetimeId: return "한 번 결제로 영구 이용"
        default: return nil
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppTheme.primary : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(titleLabel)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                        if isBestValue {
                            Text("인기")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    if let subtitle = subtitleLabel {
                        Text(subtitle)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(product.id == StoreKitManager.yearlyId ? AppTheme.actionGreen : .secondary)
                    }
                }

                Spacer()

                HStack(alignment: .lastTextBaseline, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? AppTheme.primary : .primary)
                    Text(periodLabel)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? AppTheme.primary.opacity(0.04) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                isSelected ? AppTheme.primary : Color(.systemGray5),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
