import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var manager: ChecklistManager
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var selectedCategory: MistakeCategory?
    @State private var showPaywall = false

    private var lockedCount: Int {
        allCategories.count - StoreKitManager.freeCategoryLimit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                        .padding(.top, 8)

                    if !storeManager.isPremium {
                        proBanner
                    }

                    LazyVStack(spacing: 12) {
                        ForEach(allCategories) { category in
                            let isLocked = storeManager.isCategoryLocked(category.id)
                            Button {
                                if isLocked {
                                    showPaywall = true
                                } else {
                                    selectedCategory = category
                                }
                            } label: {
                                CategoryCard(category: category, isLocked: isLocked)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("주니어 개발자의 실수 100")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedCategory) { category in
                MistakeListView(category: category)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - PRO 배너

    private var proBanner: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(AppTheme.retroAmber)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(lockedCount)개 카테고리가 잠겨 있습니다")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("PRO로 업그레이드하여 전체 학습하기")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppTheme.retroAmber.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(AppTheme.retroAmber.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 헤더 카드

    private var headerCard: some View {
        ZStack {
            AppTheme.headerGradient
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 200, height: 200)
                .offset(x: 100, y: -60)
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 140, height: 140)
                .offset(x: -80, y: 50)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("나의 성장 여정")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(manager.totalChecked) / 100 경험 완료")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 5)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: manager.progress)
                        .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: manager.progress)
                    Text("\(Int(manager.progress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 6)
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let category: MistakeCategory
    let isLocked: Bool
    @EnvironmentObject var manager: ChecklistManager

    private var checked: Int { manager.checkedCount(for: category) }
    private var total: Int { category.items.count }
    private var progress: Double { Double(checked) / Double(total) }
    private var color: Color { AppTheme.categoryColors[category.id % AppTheme.categoryColors.count] }

    var body: some View {
        HStack(spacing: 14) {
            // 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(isLocked ? 0.12 : 0.2), color.opacity(isLocked ? 0.06 : 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isLocked ? color.opacity(0.35) : color)
            }
            .overlay(alignment: .bottomTrailing) {
                if isLocked {
                    ZStack {
                        Circle()
                            .fill(Color(.systemBackground))
                            .frame(width: 18, height: 18)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(AppTheme.primary)
                    }
                    .offset(x: 5, y: 5)
                }
            }

            // 타이틀 & 내용
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(category.id + 1).")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(color.opacity(0.7))
                    Text(category.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(isLocked ? .secondary : .primary)
                    if isLocked {
                        Text("PRO")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary)
                            .clipShape(Capsule())
                    }
                }

                if isLocked {
                    Text("구독하여 잠금 해제")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.tertiary)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(color.opacity(0.12))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * progress), height: 6)
                                .animation(.spring(response: 0.5), value: progress)
                        }
                    }
                    .frame(height: 6)
                }
            }

            if isLocked {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.quaternary)
            } else {
                Text("\(checked)/\(total)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLocked ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: .black.opacity(isLocked ? 0.03 : 0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(isLocked ? 0.04 : 0.08), lineWidth: 1)
        )
    }
}
