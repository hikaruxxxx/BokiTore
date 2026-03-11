import SwiftUI

/// メインのタブナビゲーション
struct ContentView: View {
    var body: some View {
        TabView {
            // ホーム画面
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            // 統計画面
            StatsView()
                .tabItem {
                    Label("統計", systemImage: "chart.bar.fill")
                }

            // 設定画面
            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(Color.appPrimary)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserProgress.self, StudyStreak.self], inMemory: true)
}
