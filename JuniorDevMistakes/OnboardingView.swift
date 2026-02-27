import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var currentPage = 0

    private struct Page {
        let icon: String
        let iconColor: Color
        let title: String
        let description: String
    }

    private let pages: [Page] = [
        Page(
            icon: "chevron.left.forwardslash.chevron.right",
            iconColor: AppTheme.primaryLight,
            title: "주니어 개발자의\n실수 100",
            description: "현직 개발자들이 가장 많이 하는\n실수를 미리 알고 더 빨리 성장하세요"
        ),
        Page(
            icon: "checkmark.circle.fill",
            iconColor: AppTheme.actionGreen,
            title: "100가지 실수\n체크리스트",
            description: "10개 카테고리, 100가지 실수\n직접 경험하기 전에 미리 배우세요"
        ),
        Page(
            icon: "book.closed.fill",
            iconColor: AppTheme.retroAmber,
            title: "회고로 진짜\n성장을 경험하세요",
            description: "각 실수마다 회고 질문에 답하며\n같은 실수를 두 번 하지 않게 됩니다"
        ),
        Page(
            icon: "icloud.fill",
            iconColor: AppTheme.growthBlue,
            title: "모든 기기에서\n자동으로 동기화",
            description: "iPhone, iPad, Mac에서\niCloud로 데이터가 항상 이어집니다"
        ),
    ]

    var isLastPage: Bool { currentPage == pages.count - 1 }

    var body: some View {
        ZStack {
            AppTheme.headerGradient.ignoresSafeArea()

            // 배경 장식 원
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 300, height: 300)
                .offset(x: 120, y: -200)
            Circle()
                .fill(.white.opacity(0.03))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: 250)

            VStack(spacing: 0) {
                // 건너뛰기
                HStack {
                    Spacer()
                    if !isLastPage {
                        Button("건너뛰기") { onFinish() }
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }
                }

                // 페이지 슬라이더
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // 하단 컨트롤
                VStack(spacing: 28) {
                    // 도트 인디케이터
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(.white.opacity(index == currentPage ? 1 : 0.3))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    // 버튼
                    Button {
                        if isLastPage {
                            onFinish()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        }
                    } label: {
                        Text(isLastPage ? "시작하기" : "다음")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // 아이콘
            ZStack {
                Circle()
                    .fill(.white.opacity(0.1))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(.white.opacity(0.08))
                    .frame(width: 110, height: 110)
                Image(systemName: page.icon)
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(page.iconColor)
                    .symbolRenderingMode(.hierarchical)
            }

            // 텍스트
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text(page.description)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
