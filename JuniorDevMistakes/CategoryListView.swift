import SwiftUI

struct CategoryListView: View {
    @EnvironmentObject var manager: ChecklistManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Hero header card
                    headerCard
                        .padding(.top, 8)

                    // Category cards
                    LazyVStack(spacing: 12) {
                        ForEach(allCategories) { category in
                            NavigationLink(value: category) {
                                CategoryCard(category: category)
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
            .navigationDestination(for: MistakeCategory.self) { category in
                MistakeListView(category: category)
            }
        }
    }

    private var headerCard: some View {
        ZStack {
            // Decorative background shapes
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

struct CategoryCard: View {
    let category: MistakeCategory
    @EnvironmentObject var manager: ChecklistManager

    private var checked: Int { manager.checkedCount(for: category) }
    private var total: Int { category.items.count }
    private var progress: Double { Double(checked) / Double(total) }

    private var color: Color {
        AppTheme.categoryColors[category.id % AppTheme.categoryColors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon with gradient background
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                Image(systemName: category.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(color)
            }

            // Title & progress
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("\(category.id + 1).")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(color.opacity(0.7))
                    Text(category.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }

                // Progress bar
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

            // Count
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
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.08), lineWidth: 1)
        )
    }
}
