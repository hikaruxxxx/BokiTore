import SwiftData

#if DEBUG
/// プレビュー用のインメモリモデルコンテナ
/// 全SwiftDataモデルを登録済み
extension ModelContainer {
    static var preview: ModelContainer {
        do {
            return try ModelContainer(
                for: UserProgress.self, StudyStreak.self,
                     DailyMission.self, DailyChallengeBadge.self,
                     ReviewItem.self, TimeAttackRecord.self, StudyPlan.self,
                     StreakMilestone.self,
                     Bookmark.self, DiagnosisResult.self, StudyRoadmap.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("プレビュー用ModelContainerの作成に失敗しました: \(error)")
        }
    }
}
#endif
