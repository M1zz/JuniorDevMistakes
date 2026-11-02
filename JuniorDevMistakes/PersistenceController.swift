import CoreData
import SwiftUI

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    /// 저장소를 열지 못해 이번 실행은 메모리에서 열었는가 (→ storeFallbackNotice)
    private(set) var isFallback = false

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "JuniorDevMistakes")

        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        container.persistentStoreDescriptions = [description]
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
        }

        // CloudKit 원격 변경 알림 활성화
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        var loadError: Error?
        container.loadPersistentStores { _, error in
            if let error { loadError = error }
        }
        if let loadError {
            // 예전에는 여기서 죽었다 — 그러면 켤 때마다 죽고 기기에 있는 기록도 못 본다.
            // 디스크의 기록은 그대로 두고 이번 실행만 메모리에서 열고, 사용자에게 알린다.
            print("⚠️ 저장소를 열지 못해 이번 실행은 메모리에서 엽니다: \(loadError)")
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: URL(fileURLWithPath: "/dev/null"))]
            container.loadPersistentStores { _, error in
                // 메모리 저장소마저 안 되는 건 모델 자체가 잘못된 것 — 개발 중에 바로 드러난다
                if let error { fatalError("메모리 저장소도 열지 못함: \(error)") }
            }
            isFallback = true
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        try? context.save()
    }
}

// MARK: - 저장소를 못 연 날의 안내

extension View {
    /// 임시 저장소로 열렸으면 한 번 알린다. 앱의 맨 바깥 화면에 붙인다.
    func storeFallbackNotice() -> some View {
        modifier(StoreFallbackNotice())
    }
}

private struct StoreFallbackNotice: ViewModifier {
    @State private var isPresented = PersistenceController.shared.isFallback

    func body(content: Content) -> some View {
        content.alert("기록을 열지 못했어요", isPresented: $isPresented) {
        } message: {
            Text("저장된 기록은 지워지지 않았어요. 다만 지금 적는 내용은 저장되지 않으니, 앱을 껐다 켜 보세요.")
        }
    }
}
