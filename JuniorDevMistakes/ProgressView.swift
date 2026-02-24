import SwiftUI

struct OverallProgressView: View {
    @EnvironmentObject var manager: ChecklistManager
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Main progress ring
                    mainProgressCard
                        .padding(.top, 4)

                    // Stats grid
                    statsGrid

                    // Category breakdown
                    categoryBreakdown

                    // Reset button
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("전체 초기화", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.red.opacity(0.6))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(.red.opacity(0.06))
                            )
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("진행률")
            .alert("전체 초기화", isPresented: $showResetAlert) {
                Button("취소", role: .cancel) { }
                Button("초기화", role: .destructive) {
                    withAnimation { manager.resetAll() }
                }
            } message: {
                Text("체크리스트, 회고 기록, 북마크가 모두 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }

    // MARK: - Main Progress
    private var mainProgressCard: some View {
        VStack(spacing: 24) {
            ZStack {
                // Background track
                Circle()
                    .stroke(AppTheme.primary.opacity(0.08), lineWidth: 14)
                    .frame(width: 170, height: 170)

                // Progress arc
                Circle()
                    .trim(from: 0, to: manager.progress)
                    .stroke(
                        AngularGradient(
                            colors: [AppTheme.accent, AppTheme.primaryLight, AppTheme.primary, AppTheme.accent],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .frame(width: 170, height: 170)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: manager.progress)

                // Center content
                VStack(spacing: 4) {
                    Text("\(manager.totalChecked)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primary)
                    Text("/ 100")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Text(progressMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }

    private var progressMessage: String {
        switch manager.totalChecked {
        case 0: return "아직 시작하지 않았습니다.\n첫 번째 실수를 경험해보세요!"
        case 1...10: return "여정을 시작했습니다!\n모든 시니어도 여기서 시작했어요"
        case 11...30: return "꾸준히 성장하고 있습니다!\n실수가 쌓일수록 실력도 쌓입니다"
        case 31...50: return "절반에 가까워지고 있습니다!\n이 속도면 금방 시니어가 되겠네요"
        case 51...70: return "절반을 넘었습니다!\n이제 중급 개발자의 시야가 보이기 시작합니다"
        case 71...90: return "거의 다 왔습니다!\n이 정도면 이미 많은 것을 배웠을 거예요"
        case 91...99: return "마지막 몇 개만 남았습니다!\n완주가 코앞입니다"
        case 100: return "축하합니다! 모든 실수를 경험했습니다!\n이제 시니어의 길이 열렸습니다!"
        default: return ""
        }
    }

    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            StatCard(
                icon: "checkmark.circle.fill",
                color: AppTheme.actionGreen,
                value: "\(manager.totalChecked)",
                label: "경험한 실수"
            )
            StatCard(
                icon: "text.book.closed.fill",
                color: AppTheme.retroAmber,
                value: "\(manager.totalRetroEntries)",
                label: "회고 기록"
            )
            StatCard(
                icon: "brain.head.profile",
                color: AppTheme.primaryLight,
                value: "\(manager.mistakesWithRetro)",
                label: "회고한 항목"
            )
            StatCard(
                icon: "bookmark.fill",
                color: AppTheme.growthBlue,
                value: "\(manager.bookmarkedItems.count)",
                label: "북마크"
            )
        }
    }

    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("카테고리별 진행률")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .padding(.top, 4)

            ForEach(allCategories) { category in
                let checked = manager.checkedCount(for: category)
                let total = category.items.count
                let ratio = Double(checked) / Double(total)
                let color = AppTheme.categoryColors[category.id % AppTheme.categoryColors.count]

                HStack(spacing: 10) {
                    Image(systemName: category.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(color)
                        .frame(width: 22)

                    Text(category.title)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .frame(width: 100, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.1))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: ratio == 1.0 ? [AppTheme.actionGreen, AppTheme.actionGreen.opacity(0.8)] : [color, color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * ratio), height: 8)
                                .animation(.spring(response: 0.5), value: ratio)
                        }
                    }
                    .frame(height: 8)

                    Text("\(checked)/\(total)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }
}

struct StatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
    }
}
