import SwiftUI
import LeeoKit

@main
struct JuniorDevMistakesApp: App {
    @StateObject private var checklistManager: ChecklistManager = {
        let manager = ChecklistManager()
        if ScreenshotScene.current != nil { manager.seedForScreenshots() }
        return manager
    }()
    @StateObject private var storeManager = StoreKitManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checklistManager)
                .environmentObject(storeManager)
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (LeeoStore 없이 혼자)
                .task { await JuniorDevMistakesSpec.tipJar.startStandalone() }
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView { hasSeenOnboarding = true }
                        .foldConfined()
                }
                // 창 크기로 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다 (LeeoKit Fold).
                .foldAware()
#if targetEnvironment(macCatalyst)
                .frame(minWidth: 900, minHeight: 600)
#endif
        }
#if targetEnvironment(macCatalyst)
        .windowResizability(.contentMinSize)
        .commands {
            // 사이드바 토글 단축키 제거 (탭 기반 앱)
            CommandGroup(replacing: .sidebar) {}
            // 앱 정보 메뉴
            CommandGroup(replacing: .appInfo) {
                Button("주니어 개발자의 실수 100 정보") {}
            }
        }
#endif
    }
}

// MARK: - App Store 스크린샷 장면

/// `-screenshotScene home|list|detail|retro|progress` 로 실행하면 그 화면을 데이터가 찬 채로 연다.
/// 디버그 빌드에서만 켜진다. 찍는 법은 scripts/capture_screenshots.sh.
enum ScreenshotScene: String {
    case home, list, detail, retro, progress

    static let current: ScreenshotScene? = {
#if DEBUG
        UserDefaults.standard.string(forKey: "screenshotScene").flatMap(ScreenshotScene.init)
#else
        nil
#endif
    }()

    static var initialTab: Int {
        switch current {
        case .retro: 2
        case .progress: 1
        default: 0
        }
    }

    static var initialPath: NavigationPath {
        var path = NavigationPath()
        switch current {
        case .list:
            path.append(allCategories[0])
        case .detail:
            path.append(allCategories[0])
            path.append(allCategories[0].items[0])
        default:
            break
        }
        return path
    }
}

extension ChecklistManager {
    /// 진행 중인 사용자처럼 체크·북마크·회고를 채운다 (회고 답은 기기 언어로).
    func seedForScreenshots() {
        resetAll()
        for id in [1, 2, 3, 5, 6, 7, 9, 11, 12, 13, 14, 16, 18, 21, 22, 23, 25, 27, 31, 32, 34, 41, 43] {
            toggle(id)
        }
        for id in [2, 11] { toggleBookmark(id) }
        let answers = ScreenshotScene.sampleAnswers
        for (mistakeId, answer) in zip([21, 11, 1], answers.reversed()) {
            addRetroEntry(mistakeId: mistakeId, questionIndex: 0, answer: answer)
        }
    }
}

extension ScreenshotScene {
    /// 회고 일지에 보일 답. 사용자가 쓴 글이라 앱 번역 카탈로그가 아니라 여기 둔다.
    /// 순서: #001 변수명 · #011 디버깅 · #021 커밋 메시지.
    static var sampleAnswers: [String] {
        let lang = Bundle.main.preferredLocalizations.first ?? "en"
        return answersByLanguage[lang] ?? answersByLanguage[String(lang.prefix(2))] ?? answersByLanguage["en"]!
    }

    private static let answersByLanguage: [String: [String]] = [
        "ko": ["어제 쓴 코드에 data, temp가 있었다. userList, formattedDate로 바꿨다.",
               "print만 열 번 넘게 찍었다. 다음엔 브레이크포인트부터 걸어 본다.",
               "'fix'만 세 번 썼다. 이제는 무엇을 왜 고쳤는지 한 줄로 남긴다."],
        "en": ["Yesterday's code had data and temp. Renamed them to userList and formattedDate.",
               "I added over ten print calls. Next time I'll start with a breakpoint.",
               "Three commits just said 'fix'. Now I write what changed and why."],
        "zh-Hans": ["昨天的代码里有 data 和 temp，已改成 userList 和 formattedDate。",
                    "加了十几个 print。下次先打断点再说。",
                    "连着三次提交只写了 fix。现在会写清改了什么、为什么改。"],
        "zh-Hant": ["昨天的程式碼裡有 data 和 temp，已改成 userList 和 formattedDate。",
                    "加了十幾個 print。下次先下中斷點再說。",
                    "連續三次 commit 只寫 fix。現在會寫清楚改了什麼、為什麼改。"],
        "ja": ["昨日のコードに data と temp があった。userList と formattedDate に直した。",
               "print を10回以上仕込んだ。次はまずブレークポイントを置く。",
               "コミットが3回とも「fix」だけ。今は何をなぜ直したか一行で書く。"],
        "ru": ["Во вчерашнем коде были data и temp. Переименовал в userList и formattedDate.",
               "Вставил больше десяти print. В следующий раз начну с точки останова.",
               "Три коммита подряд с текстом «fix». Теперь пишу, что и зачем поменял."],
        "es": ["Mi código de ayer tenía data y temp. Los renombré a userList y formattedDate.",
               "Metí más de diez print. La próxima vez empiezo con un breakpoint.",
               "Tres commits solo decían «fix». Ahora escribo qué cambié y por qué."],
        "de": ["Im Code von gestern standen data und temp. Jetzt heißen sie userList und formattedDate.",
               "Über zehn print-Aufrufe eingebaut. Nächstes Mal setze ich zuerst einen Breakpoint.",
               "Drei Commits hießen nur „fix“. Jetzt schreibe ich, was sich warum geändert hat."],
        "fr": ["Mon code d'hier contenait data et temp. Renommés en userList et formattedDate.",
               "J'ai ajouté plus de dix print. La prochaine fois, je pose d'abord un point d'arrêt.",
               "Trois commits disaient juste « fix ». Maintenant, j'écris ce qui change et pourquoi."],
        "it": ["Nel codice di ieri c'erano data e temp. Li ho rinominati in userList e formattedDate.",
               "Ho messo più di dieci print. La prossima volta parto da un breakpoint.",
               "Tre commit con scritto solo «fix». Ora scrivo cosa ho cambiato e perché."],
        "pt-BR": ["O código de ontem tinha data e temp. Renomeei para userList e formattedDate.",
                  "Coloquei mais de dez print. Da próxima vez começo com um breakpoint.",
                  "Três commits diziam só \"fix\". Agora escrevo o que mudou e por quê."],
        "th": ["โค้ดเมื่อวานมี data กับ temp เปลี่ยนเป็น userList และ formattedDate แล้ว",
               "ใส่ print ไปกว่าสิบจุด ครั้งหน้าจะเริ่มจากตั้ง breakpoint ก่อน",
               "คอมมิตสามครั้งเขียนแค่ fix ตอนนี้เขียนว่าแก้อะไรและแก้ทำไม"],
        "vi": ["Code hôm qua có biến data và temp. Mình đã đổi thành userList và formattedDate.",
               "Mình chèn hơn mười lệnh print. Lần sau sẽ đặt breakpoint trước.",
               "Ba commit liền chỉ ghi \"fix\". Giờ mình ghi rõ sửa gì và vì sao."],
        "cs": ["Ve včerejším kódu byly proměnné data a temp. Přejmenoval jsem je na userList a formattedDate.",
               "Přidal jsem přes deset výpisů print. Příště začnu breakpointem.",
               "Tři commity měly jen „fix“. Teď píšu, co a proč se změnilo."],
        "da": ["Gårsdagens kode havde data og temp. Jeg omdøbte dem til userList og formattedDate.",
               "Jeg satte over ti print ind. Næste gang starter jeg med et breakpoint.",
               "Tre commits hed bare \"fix\". Nu skriver jeg, hvad jeg ændrede og hvorfor."],
        "el": ["Ο χθεσινός κώδικας είχε data και temp. Τα μετονόμασα σε userList και formattedDate.",
               "Έβαλα πάνω από δέκα print. Την επόμενη φορά ξεκινάω με breakpoint.",
               "Τρία commit έγραφαν μόνο «fix». Τώρα γράφω τι άλλαξα και γιατί."],
        "fi": ["Eilisessä koodissa oli data ja temp. Nimesin ne uudelleen: userList ja formattedDate.",
               "Lisäsin yli kymmenen print-kutsua. Ensi kerralla aloitan keskeytyskohdasta.",
               "Kolme committia, joissa luki vain \"fix\". Nyt kirjoitan, mitä muutin ja miksi."],
        "id": ["Kode kemarin masih pakai data dan temp. Sudah kuganti jadi userList dan formattedDate.",
               "Aku menaruh lebih dari sepuluh print. Lain kali mulai dari breakpoint.",
               "Tiga commit cuma bertuliskan \"fix\". Sekarang kutulis apa yang diubah dan kenapa."],
        "nb": ["Koden fra i går hadde data og temp. Jeg ga dem nye navn: userList og formattedDate.",
               "Jeg la inn over ti print. Neste gang starter jeg med et stoppunkt.",
               "Tre commits het bare «fix». Nå skriver jeg hva jeg endret og hvorfor."],
        "nl": ["In mijn code van gisteren stonden data en temp. Hernoemd naar userList en formattedDate.",
               "Ik had meer dan tien prints toegevoegd. Volgende keer begin ik met een breakpoint.",
               "Drie commits met alleen ‘fix’. Nu schrijf ik wat er veranderde en waarom."],
        "pl": ["We wczorajszym kodzie były data i temp. Zmieniłem nazwy na userList i formattedDate.",
               "Dodałem ponad dziesięć printów. Następnym razem zacznę od breakpointu.",
               "Trzy commity z opisem „fix”. Teraz piszę, co zmieniłem i dlaczego."],
        "sv": ["Gårdagens kod hade data och temp. Jag döpte om dem till userList och formattedDate.",
               "Jag lade in över tio print. Nästa gång börjar jag med en brytpunkt.",
               "Tre commits hette bara ”fix”. Nu skriver jag vad jag ändrade och varför."],
        "tr": ["Dünkü kodda data ve temp vardı. Adlarını userList ve formattedDate yaptım.",
               "On taneden fazla print ekledim. Bir dahaki sefere önce breakpoint koyacağım.",
               "Üç commit'te sadece \"fix\" yazıyordu. Artık neyi neden değiştirdiğimi yazıyorum."],
    ]
}
