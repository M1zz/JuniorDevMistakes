import SwiftUI

struct MistakeDetailView: View {
    /// 지금 보고 있는 실수. "다음 실수"를 누르면 목록으로 돌아가지 않고 이 화면에서 바로 바뀐다.
    @State private var item: MistakeItem
    @EnvironmentObject var manager: ChecklistManager
    @EnvironmentObject var storeManager: StoreKitManager
    @State private var showRetroSheet = false
    @State private var selectedQuestionIndex = 0
    @State private var entryToDelete: RetroEntry?

    init(item: MistakeItem) {
        _item = State(initialValue: item)
    }

    /// 1~100 순서에서 바로 다음 실수. 잠긴 카테고리면 없다.
    private var nextItem: MistakeItem? {
        let all = allCategories.flatMap(\.items)
        guard let index = all.firstIndex(of: item), index + 1 < all.count else { return nil }
        let next = all[index + 1]
        guard let category = allCategories.first(where: { $0.items.contains(next) }),
              !storeManager.isCategoryLocked(category.id) else { return nil }
        return next
    }

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                headerSection
                    .id("top")

                // 4 content sections
                VStack(spacing: 2) {
                    situationSection
                    actionSection
                    growthSection
                    retroSection
                }

                // Existing retro entries
                if !manager.entries(for: item.id).isEmpty {
                    retroEntriesSection
                }

                Spacer(minLength: 24)
            }
        }
        .onChange(of: item.id) { _, _ in
            withAnimation { proxy.scrollTo("top", anchor: .top) }
        }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) { bottomBar }
        .sensoryFeedback(.success, trigger: manager.isChecked(item.id)) { _, checked in checked }
        .confirmationDialog(
            Text("이 회고를 삭제할까요?"),
            isPresented: Binding(get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let entry = entryToDelete { manager.deleteRetroEntry(entry) }
                entryToDelete = nil
            }
            Button("취소", role: .cancel) { entryToDelete = nil }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            manager.toggleBookmark(item.id)
                        }
                    } label: {
                        Image(systemName: manager.isBookmarked(item.id) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(manager.isBookmarked(item.id) ? AppTheme.accent : .secondary)
                            .symbolEffect(.bounce, value: manager.isBookmarked(item.id))
                    }
                    .accessibilityLabel(Text("북마크"))
                    .accessibilityAddTraits(manager.isBookmarked(item.id) ? .isSelected : [])
                }
            }
        }
        .sheet(isPresented: $showRetroSheet) {
            RetroAnswerSheet(
                item: item,
                questionIndex: selectedQuestionIndex
            )
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Background with decorative elements
            ZStack {
                AppTheme.headerGradient

                // Decorative circles
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 180, height: 180)
                    .offset(x: 140, y: -40)
                Circle()
                    .fill(.white.opacity(0.03))
                    .frame(width: 120, height: 120)
                    .offset(x: -60, y: 30)
                Circle()
                    .fill(.white.opacity(0.04))
                    .frame(width: 80, height: 80)
                    .offset(x: 60, y: 50)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(item.numberString)
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())

                    Spacer()

                    if manager.isChecked(item.id) {
                        Label("경험 완료", systemImage: "checkmark.seal.fill")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Text(item.mistake)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .accessibilityAddTraits(.isHeader)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(20)
        }
    }

    // MARK: - Situation
    private var situationSection: some View {
        ContentSection(
            icon: "exclamationmark.triangle.fill",
            title: String(localized: "이런 상황이 벌어집니다"),
            color: AppTheme.situationRed,
            content: item.situation
        )
    }

    // MARK: - Action
    private var actionSection: some View {
        ContentSection(
            icon: "lightbulb.fill",
            title: String(localized: "이렇게 하세요"),
            color: AppTheme.actionGreen,
            content: item.action
        )
    }

    // MARK: - Growth
    private var growthSection: some View {
        ContentSection(
            icon: "arrow.up.right.circle.fill",
            title: String(localized: "이것을 배우며 성장합니다"),
            color: AppTheme.growthBlue,
            content: item.growth
        )
    }

    // MARK: - Retro Questions
    private var retroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.bubble.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.retroAmber)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("회고 질문")
                        .font(.system(.callout, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.retroAmber)
                    Text("실수 후 스스로에게 물어보세요")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, 2)

            ForEach(Array(item.retroQuestions.enumerated()), id: \.offset) { index, question in
                RetroQuestionCard(
                    questionIndex: index,
                    question: question,
                    hasAnswer: manager.entries(for: item.id).contains { $0.questionIndex == index }
                ) {
                    selectedQuestionIndex = index
                    showRetroSheet = true
                }
            }
        }
        .padding(20)
        .background(.background)
        .padding(.top, 2)
    }

    // MARK: - Existing Retro Entries
    private var retroEntriesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppTheme.retroAmber)
                    Text("나의 회고 기록")
                        .font(.system(.callout, design: .rounded, weight: .bold))
                }
                Spacer()
                Text("\(manager.entries(for: item.id).count)개")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.retroAmber)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.retroAmber.opacity(0.1))
                    .clipShape(Capsule())
            }

            ForEach(manager.entries(for: item.id)) { entry in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Q\(entry.questionIndex + 1)")
                            .font(.system(.caption2, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.retroAmber, AppTheme.accent],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())

                        Spacer()

                        Text(entry.date, style: .date)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.tertiary)

                        Button {
                            entryToDelete = entry
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15))
                                .foregroundStyle(.red.opacity(0.6))
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("삭제"))
                    }

                    Text(entry.answer)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(3)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding(20)
        .background(.background)
        .padding(.top, 2)
    }
}

// MARK: - Bottom Bar
extension MistakeDetailView {
    /// 경험 체크와 다음 실수를 엄지가 닿는 화면 아래에 둔다.
    var bottomBar: some View {
        let checked = manager.isChecked(item.id)
        return HStack(spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    manager.toggle(item.id)
                }
            } label: {
                Label {
                    Text(checked ? "경험 완료" : "이 실수 경험했어요")
                } icon: {
                    Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
                .foregroundStyle(checked ? AppTheme.actionGreen : .white)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(checked ? AppTheme.actionGreen.opacity(0.15) : AppTheme.brandIndigo)
                )
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(checked ? .isSelected : [])

            if let next = nextItem {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { item = next }
                } label: {
                    Label {
                        Text("다음 실수")
                    } icon: {
                        Image(systemName: "arrow.right")
                    }
                    .labelStyle(.titleAndIcon)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(minHeight: 50)
                    .padding(.horizontal, 16)
                    .foregroundStyle(AppTheme.primary)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(AppTheme.primary.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.bar)
    }
}

// MARK: - Content Section
struct ContentSection: View {
    let icon: String
    let title: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color)
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(color)
                    .accessibilityAddTraits(.isHeader)
            }

            Text(content)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
                .padding(.leading, 40)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .padding(.top, 2)
    }
}

// MARK: - Retro Question Card
struct RetroQuestionCard: View {
    let questionIndex: Int
    let question: String
    let hasAnswer: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Text("Q\(questionIndex + 1)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(
                                hasAnswer
                                    ? LinearGradient(colors: [AppTheme.retroAmber, AppTheme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    : LinearGradient(colors: [Color(.systemGray4), Color(.systemGray3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                    )

                Text(question)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)

                Spacer(minLength: 4)

                Image(systemName: hasAnswer ? "checkmark.circle.fill" : "pencil.circle")
                    .foregroundStyle(hasAnswer ? AppTheme.actionGreen : Color(.systemGray3))
                    .font(.system(size: 20))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(hasAnswer ? AppTheme.retroAmber.opacity(0.06) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(hasAnswer ? AppTheme.retroAmber.opacity(0.15) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Retro Answer Sheet
struct RetroAnswerSheet: View {
    let item: MistakeItem
    let questionIndex: Int
    @EnvironmentObject var manager: ChecklistManager
    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @State private var showDiscardConfirm = false
    @FocusState private var isFocused: Bool

    private var hasDraft: Bool {
        !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
             VStack(alignment: .leading, spacing: 20) {
                // Context card
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.numberString)
                        .font(.system(.caption2, design: .monospaced, weight: .bold))
                        .foregroundStyle(AppTheme.primary.opacity(0.5))

                    Text(item.mistake)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.primary.opacity(0.04))
                )

                // The question
                HStack(alignment: .top, spacing: 10) {
                    Text("Q\(questionIndex + 1)")
                        .font(.system(.footnote, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.retroAmber)
                    Text(item.retroQuestions[questionIndex])
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }

                // Answer input
                TextEditor(text: $answer)
                    .focused($isFocused)
                    .frame(minHeight: 150)
                    .padding(10)
                    .font(.system(.subheadline, design: .rounded))
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(isFocused ? AppTheme.primary.opacity(0.3) : .clear, lineWidth: 1.5)
                    )
                    .overlay(
                        Group {
                            if answer.isEmpty {
                                Text("여기에 답변을 작성하세요...")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 14)
                                    .padding(.top, 18)
                            }
                        },
                        alignment: .topLeading
                    )
                    .animation(.easeInOut(duration: 0.2), value: isFocused)

             }
             .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("회고 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소", systemImage: "xmark") {
                        if hasDraft { showDiscardConfirm = true } else { dismiss() }
                    }
                    .font(.system(.body, design: .rounded))
                    .confirmationDialog(
                        Text("작성 중인 회고를 버릴까요?"),
                        isPresented: $showDiscardConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("버리기", role: .destructive) { dismiss() }
                        Button("계속 쓰기", role: .cancel) {}
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", systemImage: "checkmark") {
                        guard !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        manager.addRetroEntry(
                            mistakeId: item.id,
                            questionIndex: questionIndex,
                            answer: answer.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        dismiss()
                    }
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : AppTheme.primary)
                }
            }
        }
        .interactiveDismissDisabled(hasDraft)
        .onAppear {
            isFocused = true
        }
#if targetEnvironment(macCatalyst)
        .frame(minWidth: 500, minHeight: 400)
#endif
    }
}
