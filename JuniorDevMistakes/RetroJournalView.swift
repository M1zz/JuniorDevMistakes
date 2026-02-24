import SwiftUI

struct RetroJournalView: View {
    @EnvironmentObject var manager: ChecklistManager
    @State private var filterCategory: Int? = nil

    private var filteredEntries: [RetroEntry] {
        let sorted = manager.retroEntries.sorted { $0.date > $1.date }
        guard let catId = filterCategory else { return sorted }
        let itemRange = (catId * 10 + 1)...(catId * 10 + 10)
        return sorted.filter { itemRange.contains($0.mistakeId) }
    }

    private func mistakeForEntry(_ entry: RetroEntry) -> MistakeItem? {
        allCategories.flatMap { $0.items }.first { $0.id == entry.mistakeId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if manager.retroEntries.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        // Filter
                        filterBar

                        // Entries
                        List {
                            ForEach(filteredEntries) { entry in
                                if let mistake = mistakeForEntry(entry) {
                                    RetroEntryCard(entry: entry, mistake: mistake)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                manager.deleteRetroEntry(entry)
                                            } label: {
                                                Label("삭제", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("회고 일지")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppTheme.retroAmber.opacity(0.06))
                    .frame(width: 140, height: 140)
                Circle()
                    .fill(AppTheme.retroAmber.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "book.closed")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(AppTheme.retroAmber.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("회고 기록이 없습니다")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                Text("각 실수 항목의 회고 질문에\n답변을 작성해보세요")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding()
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "전체", isSelected: filterCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        filterCategory = nil
                    }
                }

                ForEach(allCategories) { category in
                    FilterChip(
                        title: category.title,
                        isSelected: filterCategory == category.id
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            filterCategory = filterCategory == category.id ? nil : category.id
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected
                              ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.primaryLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                              : AnyShapeStyle(Color(.systemGray6))
                        )
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? .clear : Color(.systemGray5), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

struct RetroEntryCard: View {
    let entry: RetroEntry
    let mistake: MistakeItem

    private var categoryIndex: Int {
        (entry.mistakeId - 1) / 10
    }

    private var categoryColor: Color {
        AppTheme.categoryColors[categoryIndex % AppTheme.categoryColors.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Color accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(mistake.numberString)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.primaryLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )

                    Text("Q\(entry.questionIndex + 1)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.retroAmber)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(AppTheme.retroAmber.opacity(0.12))
                        .clipShape(Capsule())

                    Spacer()

                    Text(entry.date, style: .date)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.tertiary)
                }

                // Mistake title
                Text(mistake.mistake)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Question
                if entry.questionIndex < mistake.retroQuestions.count {
                    Text(mistake.retroQuestions[entry.questionIndex])
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.retroAmber)
                        .lineLimit(2)
                        .lineSpacing(1)
                }

                // Answer
                Text(entry.answer)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}
