import SwiftUI

struct MistakeListView: View {
    let category: MistakeCategory
    @EnvironmentObject var manager: ChecklistManager

    private var color: Color {
        AppTheme.categoryColors[category.id % AppTheme.categoryColors.count]
    }

    var body: some View {
        List {
            // Category intro
            Section {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 3)

                    Text(category.intro)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineSpacing(3)
                        .padding(.vertical, 4)
                }
                .padding(.vertical, 4)
            }

            // Items
            Section {
                ForEach(category.items) { item in
                    NavigationLink(value: item) {
                        MistakeRow(item: item)
                    }
                }
            } header: {
                HStack {
                    Text("\(category.items.count)개 항목")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.actionGreen)
                        Text("\(manager.checkedCount(for: category))개 완료")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.actionGreen)
                    }
                }
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: MistakeItem.self) { item in
            MistakeDetailView(item: item)
        }
    }
}

struct MistakeRow: View {
    let item: MistakeItem
    @EnvironmentObject var manager: ChecklistManager

    private var isChecked: Bool { manager.isChecked(item.id) }

    var body: some View {
        HStack(spacing: 14) {
            // Check circle with animation
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    manager.toggle(item.id)
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(isChecked ? AppTheme.actionGreen : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 26, height: 26)
                    if isChecked {
                        Circle()
                            .fill(AppTheme.actionGreen)
                            .frame(width: 26, height: 26)
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 5) {
                Text(item.numberString)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.primary.opacity(0.5))

                Text(item.mistake)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(isChecked ? .secondary : .primary)
                    .strikethrough(isChecked, color: .secondary.opacity(0.5))
                    .lineLimit(2)

                // Status badges
                HStack(spacing: 6) {
                    if manager.hasRetroEntries(for: item.id) {
                        HStack(spacing: 3) {
                            Image(systemName: "text.badge.checkmark")
                                .font(.system(size: 9))
                            Text("회고 완료")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.retroAmber)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.retroAmber.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    if manager.isBookmarked(item.id) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(AppTheme.growthBlue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
