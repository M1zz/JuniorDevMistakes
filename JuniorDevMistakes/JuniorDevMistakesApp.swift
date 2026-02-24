import SwiftUI

@main
struct JuniorDevMistakesApp: App {
    @StateObject private var checklistManager = ChecklistManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(checklistManager)
        }
    }
}
