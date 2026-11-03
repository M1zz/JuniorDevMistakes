//
//  MistakeIntents.swift
//  JuniorDevMistakes
//
//  "실수 100, 오늘의 실수 하나" — 출근길에 실수 하나와 대신 할 일을 Siri 가 읽어 준다.
//  무료로 열린 카테고리 안에서만 고른다(앱의 잠금과 같은 기준).
//

import AppIntents
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
