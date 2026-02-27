import SwiftUI

@main
struct JuniorDevMistakesApp: App {
    @StateObject private var checklistManager = ChecklistManager()
    @StateObject private var storeManager = StoreKitManager()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checklistManager)
                .environmentObject(storeManager)
                .fullScreenCover(isPresented: Binding(
                    get: { !hasSeenOnboarding },
                    set: { _ in }
                )) {
                    OnboardingView { hasSeenOnboarding = true }
                }
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
