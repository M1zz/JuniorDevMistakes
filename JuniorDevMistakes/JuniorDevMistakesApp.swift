import SwiftUI

@main
struct JuniorDevMistakesApp: App {
    @StateObject private var checklistManager = ChecklistManager()
    @StateObject private var storeManager = StoreKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checklistManager)
                .environmentObject(storeManager)
        }
    }
}
