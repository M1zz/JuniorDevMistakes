import SwiftUI

// MARK: - Design System
enum AppTheme {
    // Primary palette
    static let primary = Color(red: 0.25, green: 0.22, blue: 0.52)        // Deep indigo
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
        colors: [primary, Color(red: 0.35, green: 0.28, blue: 0.62), Color(red: 0.50, green: 0.35, blue: 0.72)],
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

    var body: some View {
        TabView {
            CategoryListView()
                .tabItem {
                    Label("실수 100", systemImage: "rectangle.grid.1x2.fill")
                }

            OverallProgressView()
                .tabItem {
                    Label("진행률", systemImage: "chart.bar.fill")
                }

            RetroJournalView()
                .tabItem {
                    Label("회고 일지", systemImage: "book.closed.fill")
                }

            BookmarkListView()
                .tabItem {
                    Label("북마크", systemImage: "bookmark.fill")
                }

            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primary)
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

                        VStack(spacing: 8) {
                            Text("북마크한 항목이 없습니다")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("상세 화면에서 북마크 버튼을 눌러\n나중에 볼 항목을 저장하세요")
                                .font(.system(size: 14, design: .rounded))
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
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                Text("100개 실수 전체 이용 가능")
                                    .font(.system(size: 12, design: .rounded))
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
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("나머지 70개 실수를 잠금 해제하세요")
                                        .font(.system(size: 12, design: .rounded))
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
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.primary)
                            Spacer()
                            if storeManager.isLoading {
                                ProgressView().scaleEffect(0.85)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // 데이터 섹션
                Section {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("모든 데이터 초기화", systemImage: "trash")
                            .font(.system(size: 15, design: .rounded))
                    }
                } header: {
                    Text("데이터")
                } footer: {
                    Text("체크리스트, 회고 기록, 북마크가 모두 삭제됩니다.")
                        .font(.system(size: 11, design: .rounded))
                }

                // 정보 섹션
                Section {
                    HStack {
                        Text("버전")
                            .font(.system(size: 15, design: .rounded))
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .font(.system(size: 15, design: .rounded))
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
