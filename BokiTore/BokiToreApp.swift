import SwiftUI
import SwiftData
import AppTrackingTransparency

/// アプリのエントリポイント
@main
struct BokiToreApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // AdMob SDKを初期化
                    AdManager.shared.configure()
                }
                .task {
                    // ATT（App Tracking Transparency）許可リクエスト
                    // 少し遅延させてからダイアログを表示（UI表示後に行う必要がある）
                    try? await Task.sleep(for: .seconds(1))
                    await requestTrackingPermission()
                }
        }
        // Swift Dataのモデルコンテナを設定
        .modelContainer(for: [UserProgress.self, StudyStreak.self])
    }

    /// ATT許可をリクエストする
    @MainActor
    private func requestTrackingPermission() async {
        let status = ATTrackingManager.trackingAuthorizationStatus
        if status == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }
}
