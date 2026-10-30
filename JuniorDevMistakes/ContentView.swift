import SwiftUI
import StoreKit
import LeeoKit

// MARK: - Design System
enum AppTheme {
    // Primary palette
    static let brandIndigo = Color(red: 0.25, green: 0.22, blue: 0.52)    // Deep indigo (그라데이션·흰 배경용 고정색)
    /// 글자·강조색. 다크 모드에서는 어두운 배경에서 읽히도록 밝은 남색
    static let primary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.51, blue: 0.90, alpha: 1)
            : UIColor(red: 0.25, green: 0.22, blue: 0.52, alpha: 1)
    })
    static let primaryLight = Color(red: 0.38, green: 0.35, blue: 0.68)   // Light indigo
    static let accent = Color(red: 0.94, green: 0.42, blue: 0.42)         // Warm coral
    static let accentSoft = Color(red: 1.0, green: 0.62, blue: 0.48)      // Soft peach

    // Semantic colors
    static let situationRed = Color(red: 0.92, green: 0.34, blue: 0.34)
    static let actionGreen = Color(red: 0.22, green: 0.78, blue: 0.55)
    static let growthBlue = Color(red: 0.30, green: 0.55, blue: 0.92)
    static let retroAmber = Color(red: 0.95, green: 0.70, blue: 0.20)

    // Category colors - more vibrant pastels
    static let categoryColors: [Color] = [
        Color(red: 0.94, green: 0.38, blue: 0.38),   // Coral Red
        Color(red: 0.96, green: 0.62, blue: 0.28),   // Warm Orange
        Color(red: 0.68, green: 0.52, blue: 0.88),   // Soft Purple
        Color(red: 0.34, green: 0.68, blue: 0.94),   // Sky Blue
        Color(red: 0.30, green: 0.82, blue: 0.62),   // Mint Green
        Color(red: 0.98, green: 0.74, blue: 0.22),   // Golden Yellow
        Color(red: 0.62, green: 0.48, blue: 0.84),   // Lavender
        Color(red: 0.40, green: 0.75, blue: 0.82),   // Teal
        Color(red: 0.90, green: 0.42, blue: 0.56),   // Rose Pink
        Color(red: 0.52, green: 0.78, blue: 0.48),   // Leaf Green
    ]

    // Gradient presets
    static let headerGradient = LinearGradient(
        colors: [brandIndigo, Color(red: 0.35, green: 0.28, blue: 0.62), Color(red: 0.50, green: 0.35, blue: 0.72)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let progressGradient = LinearGradient(
        colors: [accent, Color(red: 0.68, green: 0.38, blue: 0.88)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Shadows
    static func cardShadow(_ color: Color = .black) -> some View {
        EmptyView()
    }
}

struct ContentView: View {
    @EnvironmentObject var manager: ChecklistManager
    @EnvironmentObject var storeManager: StoreKitManager
    @Environment(\.requestReview) private var requestReview
    @State private var tab = ScreenshotScene.initialTab

    var body: some View {
        // 아이폰 듀오를 펴면 고르는 쪽(가로면 왼쪽, 세로면 아래)에 고른 탭, 결과 쪽(오른쪽, 위)에 진행률.
        // 접혀 있거나 보통 아이폰이면 `FoldTab` 은 그 탭만 그린다 — 지금 화면 그대로.
        TabView(selection: $tab) {
            Tab("실수 100", systemImage: "rectangle.grid.1x2.fill", value: 0) {
                FoldTab { CategoryListView() }
            }
            Tab("진행률", systemImage: "chart.bar.fill", value: 1) {
                OverallProgressView()
            }
            Tab("회고 일지", systemImage: "book.closed.fill", value: 2) {
                FoldTab { RetroJournalView() }
            }
            Tab("북마크", systemImage: "bookmark.fill", value: 3) {
                FoldTab { BookmarkListView() }
            }
            Tab("설정", systemImage: "gearshape.fill", value: 4) {
                FoldTab { SettingsView() }
            }
        }
        .tint(AppTheme.primary)
        // 펴면 시스템 탭바 대신 고르는 쪽 판 바닥에 막대가 선다. 진행률은 늘 결과 쪽 판에 있어 빠진다.
        .foldTabBar(items: FoldTab<EmptyView>.items, selected: tab == 1 ? 0 : tab) { tab = $0 }
        .modifier(FoldProgressTabRedirect(tab: $tab))
#if targetEnvironment(macCatalyst)
        .tabViewStyle(.sidebarAdaptable)
#endif
        .onChange(of: manager.totalChecked) { _, count in
            if count == 5 || count == 20 || count == 50 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    requestReview()
                }
            }
        }
    }
}

// MARK: - 아이폰 듀오

/// 펼친 화면의 탭 한 장: 고르는 쪽에 그 탭 | 결과 쪽에 진행률. 접혀 있으면 그 탭만.
/// 왼쪽에서 실수를 체크하면 오른쪽 진행률이 바로 차오른다.
struct FoldTab<Choose: View>: View {
    @ViewBuilder let choose: () -> Choose

    var body: some View {
        FoldSplitView {
            choose()
        } result: {
            OverallProgressView()
                // 결과 쪽 판 안에서는 접히지 않은 화면처럼 선다.
                .environment(\.foldLayout, .single)
        }
        .foldTabBarRoom()
    }

    /// 펼쳤을 때 고르는 쪽 판 바닥에 서는 칸. 진행률(1)은 늘 결과 쪽 판에 있으므로 빠진다.
    static var items: [FoldTabBar<Int>.Item] {
        [
            .init(value: 0, title: String(localized: "실수 100"), symbol: "rectangle.grid.1x2.fill"),
            .init(value: 2, title: String(localized: "회고 일지"), symbol: "book.closed.fill"),
            .init(value: 3, title: String(localized: "북마크"), symbol: "bookmark.fill"),
            .init(value: 4, title: String(localized: "설정"), symbol: "gearshape.fill"),
        ]
    }
}

/// 펼쳤을 때 진행률 탭에 있었다면 실수 100 으로 옮긴다. 진행률은 결과 쪽 판에 그대로 서 있다.
private struct FoldProgressTabRedirect: ViewModifier {
    @Environment(\.foldLayout) private var fold
    @Binding var tab: Int

    func body(content: Content) -> some View {
        content.onChange(of: fold.isUnfolded, initial: true) { _, unfolded in
            if unfolded, tab == 1 { tab = 0 }
        }
    }
}

// MARK: - Bookmark List
struct BookmarkListView: View {
    @EnvironmentObject var manager: ChecklistManager

    var bookmarkedMistakes: [MistakeItem] {
        allCategories.flatMap { $0.items }.filter { manager.isBookmarked($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if bookmarkedMistakes.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.06))
                                .frame(width: 120, height: 120)
                            Circle()
                                .fill(AppTheme.primary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bookmark")
                                .font(.system(size: 36, weight: .light))
                                .foregroundStyle(AppTheme.primary.opacity(0.4))
                        }
                        .accessibilityHidden(true)

                        VStack(spacing: 8) {
                            Text("북마크한 항목이 없습니다")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text("상세 화면에서 북마크 버튼을 눌러\n나중에 볼 항목을 저장하세요")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .padding()
                } else {
                    List(bookmarkedMistakes) { item in
                        NavigationLink(value: item) {
                            MistakeRow(item: item)
                        }
                    }
                    .navigationDestination(for: MistakeItem.self) { item in
                        MistakeDetailView(item: item)
                    }
                }
            }
            .navigationTitle("북마크")
        }
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var manager: ChecklistManager
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var showPaywall = false
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            List {
                // 구독 섹션
                Section {
                    if storeManager.isPremium {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(AppTheme.retroAmber.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(AppTheme.retroAmber)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("PRO 이용 중")
                                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                                Text("100개 실수 전체 이용 가능")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.primary.opacity(0.1))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(AppTheme.primary)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("PRO로 업그레이드")
                                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                                        .foregroundStyle(.primary)
                                    Text("나머지 70개 실수를 잠금 해제하세요")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.quaternary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("구독")
                }

                // 복원 섹션
                Section {
                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        HStack {
                            Label("구매 복원하기", systemImage: "arrow.clockwise")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                            if storeManager.isLoading {
                                ProgressView().scaleEffect(0.85)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // 개발자 응원하기 — 판매 중인 팁이 있어야 선다.
                Section {
                    LeeoTipJarLink<JuniorDevMistakesSpec>(tipJar: JuniorDevMistakesSpec.tipJar)
                        .font(.system(.subheadline, design: .rounded))
                }

                // 데이터 섹션
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                            .font(.system(.subheadline, design: .rounded))
                    }
                } header: {
                    Text("데이터")
                } footer: {
                    Text("체크리스트, 회고 기록, 북마크가 모두 삭제됩니다.")
                        .font(.system(.caption2, design: .rounded))
                }

                // 정보 섹션
                Section {
                    HStack {
                        Text("버전")
                            .font(.system(.subheadline, design: .rounded))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("정보")
                }
            }
            .navigationTitle("설정")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("초기화 확인", isPresented: $showResetAlert) {
                Button("취소", role: .cancel) {}
                Button("초기화", role: .destructive) { manager.resetAll() }
            } message: {
                Text("모든 진행 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }
}
