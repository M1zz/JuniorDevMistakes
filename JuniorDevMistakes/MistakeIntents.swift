//
//  MistakeIntents.swift
//  JuniorDevMistakes
//
//  "실수 100, 오늘의 실수 하나" — 출근길에 실수 하나와 대신 할 일을 Siri 가 읽어 준다.
//  무료로 열린 카테고리 안에서만 고른다(앱의 잠금과 같은 기준).
//
//  - Spotlight · Siri: 회고 일지에 쓴 답을 싣는다. 누르면 그 답을 쓴 실수 화면이 열린다.
//

import AppIntents
import CoreData
import CoreSpotlight
import Foundation

struct DailyMistakeIntent: AppIntent {
    static let title = LocalizedStringResource("오늘의 실수", comment: "Siri: read one junior developer mistake")
    static let description = IntentDescription(
        LocalizedStringResource("실수 하나와 대신 해 볼 일을 읽어 줍니다.", comment: "Siri: daily mistake description")
    )

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // 날마다 같은 실수가 나오게 날짜로 고른다. 하루 동안 여러 번 물어도 같은 것을 다시 읽어 준다.
        let open = allCategories.prefix(StoreKitManager.freeCategoryLimit).flatMap(\.items)
        guard !open.isEmpty else { return .result(dialog: "") }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let item = open[day % open.count]
        return .result(dialog: IntentDialog(LocalizedStringResource("\(item.numberString) \(item.mistake)\n대신 이렇게: \(item.action)", comment: "Siri: a mistake and what to do instead. Arguments: number, mistake, action")))
    }
}

// MARK: - 회고 일지

/// Siri · Spotlight 가 연 회고를 앱 화면으로 넘긴다. CategoryListView 가 그 실수 화면을 열고 비운다.
@MainActor @Observable
final class MistakeRouter {
    static let shared = MistakeRouter()
    var mistakeID: Int?
}

struct RetroEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("회고", comment: "Siri/Spotlight: one answer written in the retro journal")
    )
    static let defaultQuery = RetroQuery()

    let id: String
    let mistakeID: Int
    let answer: String
    let mistakeTitle: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(String(answer.prefix(80)))", subtitle: "\(mistakeTitle)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let set = defaultAttributeSet
        set.textContent = answer
        set.keywords = [mistakeTitle]
        return set
    }

    init?(_ entry: CDRetroEntry) {
        guard let id = entry.id, let answer = entry.answer, !answer.isEmpty else { return nil }
        let mistake = allCategories.lazy.flatMap(\.items).first { $0.id == Int(entry.mistakeId) }
        self.id = id.uuidString
        mistakeID = Int(entry.mistakeId)
        self.answer = answer
        mistakeTitle = mistake.map { "\($0.numberString) \($0.mistake)" } ?? ""
    }
}

struct RetroQuery: EntityStringQuery {
    func entities(for identifiers: [String]) async throws -> [RetroEntity] {
        let wanted = Set(identifiers)
        return RetroLibrary.entries().filter { wanted.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [RetroEntity] {
        RetroLibrary.entries().filter {
            $0.answer.localizedStandardContains(string) || $0.mistakeTitle.localizedStandardContains(string)
        }
    }

    func suggestedEntities() async throws -> [RetroEntity] {
        Array(RetroLibrary.entries().prefix(20))
    }
}

/// 회고를 연다. Spotlight · Siri 결과를 누르면 여기로 온다.
struct OpenRetroIntent: OpenIntent {
    static let title = LocalizedStringResource("회고 열기", comment: "Siri/Spotlight: open a retro journal answer")
    static let description = IntentDescription(
        LocalizedStringResource("회고 일지에 쓴 답과 그 실수 화면을 엽니다.", comment: "Siri: open retro description")
    )

    @Parameter(title: LocalizedStringResource("회고", comment: "Siri: retro parameter"),
               description: LocalizedStringResource("열어 볼 회고 일지의 답", comment: "Siri: retro parameter description"))
    var target: RetroEntity

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        MistakeRouter.shared.mistakeID = target.mistakeID
        return .result()
    }
}

enum RetroLibrary {
    /// 최근에 쓴 회고부터.
    static func entries() -> [RetroEntity] {
        let context = PersistenceController.shared.container.newBackgroundContext()
        return context.performAndWait {
            let request = NSFetchRequest<CDRetroEntry>(entityName: "CDRetroEntry")
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return ((try? context.fetch(request)) ?? []).compactMap(RetroEntity.init)
        }
    }

    /// Spotlight 에 싣는 회고를 지금 것에 맞춘다. 앱을 열 때와 뒤로 보낼 때 부른다.
    static func reindex() async {
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: RetroEntity.self)
        try? await index.indexAppEntities(entries())
    }
}

// MARK: - Siri 문구

struct JuniorDevMistakesShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: DailyMistakeIntent(),
            phrases: ["Today’s mistake in \(.applicationName)", "Read me a mistake from \(.applicationName)"],
            shortTitle: "Today’s Mistake",
            systemImageName: "lightbulb"
        )
    }
}
