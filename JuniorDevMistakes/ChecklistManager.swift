import Foundation
import SwiftUI

class ChecklistManager: ObservableObject {
    // MARK: - Checklist (experienced mistakes)
    @Published var checkedItems: Set<Int> {
        didSet { saveCheckedItems() }
    }
    
    // MARK: - Retro journal entries
    @Published var retroEntries: [RetroEntry] {
        didSet { saveRetroEntries() }
    }
    
    // MARK: - Bookmarks
    @Published var bookmarkedItems: Set<Int> {
        didSet { saveBookmarks() }
    }
    
    private let checkedKey = "checkedMistakes"
    private let retroKey = "retroEntries"
    private let bookmarkKey = "bookmarkedMistakes"
    
    init() {
        // Load checked items
        if let data = UserDefaults.standard.array(forKey: checkedKey) as? [Int] {
            checkedItems = Set(data)
        } else {
            checkedItems = []
        }
        
        // Load retro entries
        if let data = UserDefaults.standard.data(forKey: retroKey),
           let entries = try? JSONDecoder().decode([RetroEntry].self, from: data) {
            retroEntries = entries
        } else {
            retroEntries = []
        }
        
        // Load bookmarks
        if let data = UserDefaults.standard.array(forKey: bookmarkKey) as? [Int] {
            bookmarkedItems = Set(data)
        } else {
            bookmarkedItems = []
        }
    }
    
    // MARK: - Checklist
    func isChecked(_ id: Int) -> Bool {
        checkedItems.contains(id)
    }
    
    func toggle(_ id: Int) {
        if checkedItems.contains(id) {
            checkedItems.remove(id)
        } else {
            checkedItems.insert(id)
        }
    }
    
    var totalChecked: Int { checkedItems.count }
    var progress: Double { Double(totalChecked) / 100.0 }
    
    func checkedCount(for category: MistakeCategory) -> Int {
        category.items.filter { checkedItems.contains($0.id) }.count
    }
    
    // MARK: - Bookmarks
    func isBookmarked(_ id: Int) -> Bool {
        bookmarkedItems.contains(id)
    }
    
    func toggleBookmark(_ id: Int) {
        if bookmarkedItems.contains(id) {
            bookmarkedItems.remove(id)
        } else {
            bookmarkedItems.insert(id)
        }
    }
    
    // MARK: - Retro
    func entries(for mistakeId: Int) -> [RetroEntry] {
        retroEntries.filter { $0.mistakeId == mistakeId }
    }
    
    func addRetroEntry(mistakeId: Int, questionIndex: Int, answer: String) {
        let entry = RetroEntry(mistakeId: mistakeId, questionIndex: questionIndex, answer: answer)
        retroEntries.append(entry)
    }
    
    func deleteRetroEntry(_ entry: RetroEntry) {
        retroEntries.removeAll { $0.id == entry.id }
    }
    
    func hasRetroEntries(for mistakeId: Int) -> Bool {
        retroEntries.contains { $0.mistakeId == mistakeId }
    }
    
    var totalRetroEntries: Int { retroEntries.count }
    
    var mistakesWithRetro: Int {
        Set(retroEntries.map { $0.mistakeId }).count
    }
    
    // MARK: - Persistence
    private func saveCheckedItems() {
        UserDefaults.standard.set(Array(checkedItems), forKey: checkedKey)
    }
    
    private func saveRetroEntries() {
        if let data = try? JSONEncoder().encode(retroEntries) {
            UserDefaults.standard.set(data, forKey: retroKey)
        }
    }
    
    private func saveBookmarks() {
        UserDefaults.standard.set(Array(bookmarkedItems), forKey: bookmarkKey)
    }
    
    // MARK: - Reset
    func resetAll() {
        checkedItems = []
        retroEntries = []
        bookmarkedItems = []
    }
}
