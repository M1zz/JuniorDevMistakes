import Foundation

struct MistakeCategory: Identifiable, Hashable {
    let id: Int
    let title: String
    let icon: String
    let intro: String
    let items: [MistakeItem]
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MistakeCategory, rhs: MistakeCategory) -> Bool { lhs.id == rhs.id }
}

struct MistakeItem: Identifiable, Hashable {
    let id: Int // global 1-100
    let mistake: String
    let situation: String
    let action: String
    let growth: String
    let retroQuestions: [String]
    
    var numberString: String {
        String(format: "#%03d", id)
    }
    
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: MistakeItem, rhs: MistakeItem) -> Bool { lhs.id == rhs.id }
}

struct RetroEntry: Codable, Identifiable {
    let id: UUID
    let mistakeId: Int
    let questionIndex: Int
    let answer: String
    let date: Date
    
    init(mistakeId: Int, questionIndex: Int, answer: String) {
        self.id = UUID()
        self.mistakeId = mistakeId
        self.questionIndex = questionIndex
        self.answer = answer
        self.date = Date()
    }
}
