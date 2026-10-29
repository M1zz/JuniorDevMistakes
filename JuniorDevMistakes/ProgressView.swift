import SwiftUI
import LeeoKit

struct OverallProgressView: View {
    @EnvironmentObject var manager: ChecklistManager
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Main progress ring
                    mainProgressCard
                        .padding(.top, 4)

                    // 돌아본 실수가 쌓였을 때, 이미 PRO 인 사람에게만 드물게 응원을 부탁한다.
                    // 아직 PRO 가 아닌 사람에게는 페이월이 맞는 길이다.
                    if storeManager.isPremium {
                        LeeoTipAskSlot<JuniorDevMistakesSpec>(tipJar: JuniorDevMistakesSpec.tipJar,
                                                              reached: JuniorDevMistakesTipMoments.reached(checkedCount: manager.totalChecked))
                    }

                    // Stats grid
                    statsGrid

                    // 100-cell progress map
                    progressGrid

                    // Reset button
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        Label("전체 초기화", systemImage: "arrow.counterclockwise")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
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
                        .font(.system(.callout, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            // 큰 숫자는 고리 안 장식이라 고정 크기. VoiceOver 는 "N / 100" 으로 읽는다
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(manager.totalChecked) / 100"))

            Text(progressMessage)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
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
        case 0: return String(localized: "아직 시작하지 않았습니다.\n첫 번째 실수를 경험해보세요!")
        case 1...10: return String(localized: "여정을 시작했습니다!\n모든 시니어도 여기서 시작했어요")
        case 11...30: return String(localized: "꾸준히 성장하고 있습니다!\n실수가 쌓일수록 실력도 쌓입니다")
        case 31...50: return String(localized: "절반에 가까워지고 있습니다!\n이 속도면 금방 시니어가 되겠네요")
        case 51...70: return String(localized: "절반을 넘었습니다!\n이제 중급 개발자의 시야가 보이기 시작합니다")
        case 71...90: return String(localized: "거의 다 왔습니다!\n이 정도면 이미 많은 것을 배웠을 거예요")
        case 91...99: return String(localized: "마지막 몇 개만 남았습니다!\n완주가 코앞입니다")
        case 100: return String(localized: "축하합니다! 모든 실수를 경험했습니다!\n이제 시니어의 길이 열렸습니다!")
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
                label: String(localized: "경험한 실수")
            )
            StatCard(
                icon: "text.book.closed.fill",
                color: AppTheme.retroAmber,
                value: "\(manager.totalRetroEntries)",
                label: String(localized: "회고 기록")
            )
            StatCard(
                icon: "brain.head.profile",
                color: AppTheme.primaryLight,
                value: "\(manager.mistakesWithRetro)",
                label: String(localized: "회고한 항목")
            )
            StatCard(
                icon: "bookmark.fill",
                color: AppTheme.growthBlue,
                value: "\(manager.bookmarkedItems.count)",
                label: String(localized: "북마크")
            )
        }
    }

    // MARK: - 100-Cell Progress Grid
    private var progressGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("나의 실수 100")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(manager.totalChecked) / 100")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10),
                spacing: 6
            ) {
                ForEach(1...100, id: \.self) { id in
                    let checked = manager.isChecked(id)
                    let color = AppTheme.categoryColors[((id - 1) / 10) % AppTheme.categoryColors.count]
                    RoundedRectangle(cornerRadius: 4)
                        .fill(checked ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.1)))
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(color.opacity(checked ? 0 : 0.15), lineWidth: 1)
                        )
                        .animation(.spring(response: 0.4), value: checked)
                }
            }
            .accessibilityHidden(true)  // 칸 100개 대신 위의 "N / 100" 을 읽는다
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
            .accessibilityHidden(true)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .accessibilityElement(children: .combine)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        )
    }
}
