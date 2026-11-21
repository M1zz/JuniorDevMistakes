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

    init(id: Int, mistake: String, situation: String, action: String, growth: String, retroQuestions: [String]) {
        self.id = id
        self.mistake = BidiText.isolatingCode(mistake)
        self.situation = BidiText.isolatingCode(situation)
        self.action = BidiText.isolatingCode(action)
        self.growth = BidiText.isolatingCode(growth)
        self.retroQuestions = retroQuestions.map(BidiText.isolatingCode)
    }

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

    init(id: UUID, mistakeId: Int, questionIndex: Int, answer: String, date: Date) {
        self.id = id
        self.mistakeId = mistakeId
        self.questionIndex = questionIndex
        self.answer = answer
        self.date = date
    }
}

/// 아랍어처럼 오른쪽에서 왼쪽으로 쓰는 언어의 본문 속 코드(`if (isUserActive && hasPermission)`)는
/// 문장 방향에 섞이면 괄호 · 기호 순서가 뒤집힌다. 코드 덩어리를 왼쪽→오른쪽 고립(LRI … PDI)으로 감싼다.
/// 보이는 글자는 그대로라 검색에도 영향이 없다.
enum BidiText {
    static let isRightToLeft: Bool = {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale.Language(identifier: lang).characterDirection == .rightToLeft
    }()

    /// 라틴 글자 · 여는 괄호로 시작해, 라틴 글자 · 숫자 · 닫는 괄호로 끝나는 코드 덩어리 (사이에 공백 · 기호 허용).
    private static let codeRun = try! Regex(##"[A-Za-z_(\[{@#$][A-Za-z0-9_.\-()\[\]{}&|=<>!+*/:;'"#@$%?, →]*[A-Za-z0-9_)\]}]"##)

    static func isolatingCode(_ text: String) -> String {
        guard isRightToLeft else { return text }
        return text.replacing(codeRun) { match in
            let whole = String(text[match.range])
            var run = Substring(whole), lead = "", trail = ""
            func count(_ c: Character) -> Int { run.filter { $0 == c }.count }
            // 짝이 아랍어 문장 쪽에 있는 바깥 괄호는 문장에 남긴다.
            if run.first == "(", count("(") > count(")") { lead = "("; run = run.dropFirst() }
            if run.last == ")", count(")") > count("(") { trail = ")"; run = run.dropLast() }
            // 그래도 괄호 짝이 안 맞으면 (코드 사이에 아랍어가 낀 경우) 손대지 않는다.
            guard count("(") == count(")"), count("[") == count("]"), count("{") == count("}"), run.count > 1 else { return whole }
            return lead + "\u{2066}" + run + "\u{2069}" + trail
        }
    }
}
