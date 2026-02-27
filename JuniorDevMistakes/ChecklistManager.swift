import Foundation
import CoreData
import Combine

@MainActor
class ChecklistManager: ObservableObject {
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    @Published var checkedItems: Set<Int> = []
    @Published var retroEntries: [RetroEntry] = []
    @Published var bookmarkedItems: Set<Int> = []

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        migrateFromUserDefaultsIfNeeded()
        loadAll()

        // CloudKit 원격 동기화 감지 → 데이터 리로드
        NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadAll() }
            .store(in: &cancellables)
    }

    // MARK: - Load

    private func loadAll() {
        let checkedReq = NSFetchRequest<CDCheckedMistake>(entityName: "CDCheckedMistake")
        if let results = try? context.fetch(checkedReq) {
            checkedItems = Set(results.map { Int($0.mistakeId) })
        }

        let bookmarkReq = NSFetchRequest<CDBookmarkedMistake>(entityName: "CDBookmarkedMistake")
        if let results = try? context.fetch(bookmarkReq) {
            bookmarkedItems = Set(results.map { Int($0.mistakeId) })
        }

        let retroReq = NSFetchRequest<CDRetroEntry>(entityName: "CDRetroEntry")
        retroReq.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        if let results = try? context.fetch(retroReq) {
            retroEntries = results.map {
                RetroEntry(
                    id: $0.id ?? UUID(),
                    mistakeId: Int($0.mistakeId),
                    questionIndex: Int($0.questionIndex),
                    answer: $0.answer ?? "",
                    date: $0.date ?? Date()
                )
            }
        }
    }

    // MARK: - Checklist

    func isChecked(_ id: Int) -> Bool { checkedItems.contains(id) }

    func toggle(_ id: Int) {
        if checkedItems.contains(id) {
            let req = NSFetchRequest<CDCheckedMistake>(entityName: "CDCheckedMistake")
            req.predicate = NSPredicate(format: "mistakeId == %d", id)
            if let obj = try? context.fetch(req).first { context.delete(obj) }
            checkedItems.remove(id)
        } else {
            let obj = CDCheckedMistake(context: context)
            obj.mistakeId = Int32(id)
            checkedItems.insert(id)
        }
        PersistenceController.shared.save()
    }

    var totalChecked: Int { checkedItems.count }
    var progress: Double { Double(totalChecked) / 100.0 }

    func checkedCount(for category: MistakeCategory) -> Int {
        category.items.filter { checkedItems.contains($0.id) }.count
    }

    // MARK: - Bookmarks

    func isBookmarked(_ id: Int) -> Bool { bookmarkedItems.contains(id) }

    func toggleBookmark(_ id: Int) {
        if bookmarkedItems.contains(id) {
            let req = NSFetchRequest<CDBookmarkedMistake>(entityName: "CDBookmarkedMistake")
            req.predicate = NSPredicate(format: "mistakeId == %d", id)
            if let obj = try? context.fetch(req).first { context.delete(obj) }
            bookmarkedItems.remove(id)
        } else {
            let obj = CDBookmarkedMistake(context: context)
            obj.mistakeId = Int32(id)
            bookmarkedItems.insert(id)
        }
        PersistenceController.shared.save()
    }

    // MARK: - Retro

    func entries(for mistakeId: Int) -> [RetroEntry] {
        retroEntries.filter { $0.mistakeId == mistakeId }
    }

    func addRetroEntry(mistakeId: Int, questionIndex: Int, answer: String) {
        let obj = CDRetroEntry(context: context)
        obj.id = UUID()
        obj.mistakeId = Int32(mistakeId)
        obj.questionIndex = Int32(questionIndex)
        obj.answer = answer
        obj.date = Date()
        PersistenceController.shared.save()
        loadAll()
    }

    func deleteRetroEntry(_ entry: RetroEntry) {
        let req = NSFetchRequest<CDRetroEntry>(entityName: "CDRetroEntry")
        req.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        if let obj = try? context.fetch(req).first { context.delete(obj) }
        PersistenceController.shared.save()
        retroEntries.removeAll { $0.id == entry.id }
    }

    func hasRetroEntries(for mistakeId: Int) -> Bool {
        retroEntries.contains { $0.mistakeId == mistakeId }
    }

    var totalRetroEntries: Int { retroEntries.count }

    var mistakesWithRetro: Int {
        Set(retroEntries.map { $0.mistakeId }).count
    }

    // MARK: - Reset

    func resetAll() {
        for entity in ["CDCheckedMistake", "CDBookmarkedMistake", "CDRetroEntry"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            try? context.execute(NSBatchDeleteRequest(fetchRequest: req))
        }
        context.reset()
        checkedItems = []
        retroEntries = []
        bookmarkedItems = []
    }

    // MARK: - UserDefaults → Core Data 마이그레이션

    private func migrateFromUserDefaultsIfNeeded() {
        let migrationKey = "coreDataMigrationDone_v1"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        // 기존 체크 데이터
        if let ids = UserDefaults.standard.array(forKey: "checkedMistakes") as? [Int] {
            for id in ids {
                let obj = CDCheckedMistake(context: context)
                obj.mistakeId = Int32(id)
            }
        }

        // 기존 북마크 데이터
        if let ids = UserDefaults.standard.array(forKey: "bookmarkedMistakes") as? [Int] {
            for id in ids {
                let obj = CDBookmarkedMistake(context: context)
                obj.mistakeId = Int32(id)
            }
        }

        // 기존 회고 데이터
        if let data = UserDefaults.standard.data(forKey: "retroEntries"),
           let entries = try? JSONDecoder().decode([RetroEntry].self, from: data) {
            for entry in entries {
                let obj = CDRetroEntry(context: context)
                obj.id = entry.id
                obj.mistakeId = Int32(entry.mistakeId)
                obj.questionIndex = Int32(entry.questionIndex)
                obj.answer = entry.answer
                obj.date = entry.date
            }
        }

        PersistenceController.shared.save()
        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
