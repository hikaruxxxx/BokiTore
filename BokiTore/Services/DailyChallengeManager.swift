import Foundation
import SwiftData

/// デイリーチャレンジの生成・進捗管理
class DailyChallengeManager {
    static let shared = DailyChallengeManager()
    private init() {}

    // MARK: - ミッション生成

    /// 今日のミッションが存在しなければ生成する
    /// HomeView.onAppearから呼ぶ
    func ensureTodaysMissions(modelContext: ModelContext) {
        let today = Calendar.current.startOfDay(for: .now)

        do {
            let descriptor = FetchDescriptor<DailyMission>(
                predicate: #Predicate { $0.date == today }
            )
            let existing = try modelContext.fetch(descriptor)

            if existing.isEmpty {
                // 古いミッションを削除（7日以前）
                cleanupOldMissions(modelContext: modelContext)
                // 新しいミッション3つを生成
                generateMissions(for: today, modelContext: modelContext)
            }
        } catch {
            #if DEBUG
            print("DailyMission確認エラー: \(error)")
            #endif
        }
    }

    /// ミッション3つを生成
    private func generateMissions(for date: Date, modelContext: ModelContext) {
        var missions: [DailyMission] = []

        // ミッション1: 問題をX問解く（必ず含める）
        let solveCount = [5, 8, 10].randomElement() ?? 10
        missions.append(DailyMission(
            date: date,
            missionTypeRaw: DailyMissionType.solveCount.rawValue,
            descriptionText: "問題を\(solveCount)問解こう",
            targetValue: solveCount,
            orderIndex: 0
        ))

        // ミッション2: 特定カテゴリの問題を解く
        let subcategories = JournalEntrySubcategory.allCases
        if let randomSub = subcategories.randomElement() {
            let catCount = [2, 3].randomElement() ?? 3
            missions.append(DailyMission(
                date: date,
                missionTypeRaw: DailyMissionType.solveCategory.rawValue,
                descriptionText: "\(randomSub.displayName)の問題を\(catCount)問解こう",
                targetValue: catCount,
                filterKey: randomSub.rawValue,
                orderIndex: 1
            ))
        }

        // ミッション3: 連続正解
        let streak = [3, 5].randomElement() ?? 3
        missions.append(DailyMission(
            date: date,
            missionTypeRaw: DailyMissionType.consecutiveCorrect.rawValue,
            descriptionText: "\(streak)問連続で正解しよう",
            targetValue: streak,
            orderIndex: 2
        ))

        for mission in missions {
            modelContext.insert(mission)
        }
    }

    /// 7日以前の古いミッションを削除
    private func cleanupOldMissions(modelContext: ModelContext) {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) else { return }
        let cutoffDate = Calendar.current.startOfDay(for: cutoff)

        do {
            let descriptor = FetchDescriptor<DailyMission>(
                predicate: #Predicate { $0.date < cutoffDate }
            )
            let old = try modelContext.fetch(descriptor)
            for mission in old {
                modelContext.delete(mission)
            }
        } catch {
            #if DEBUG
            print("古いDailyMission削除エラー: \(error)")
            #endif
        }
    }

    // MARK: - ミッション進捗更新

    /// 問題を解答した際にミッション進捗を更新する
    /// QuizViewModel.nextQuestion() から呼ばれる
    func updateMissionProgress(
        modelContext: ModelContext,
        question: Question,
        isCorrect: Bool,
        consecutiveCorrectRun: Int
    ) {
        let today = Calendar.current.startOfDay(for: .now)

        do {
            let descriptor = FetchDescriptor<DailyMission>(
                predicate: #Predicate { $0.date == today && !$0.isCompleted }
            )
            let missions = try modelContext.fetch(descriptor)

            var allCompleted = true

            for mission in missions {
                switch mission.missionType {
                case .solveCount:
                    // どの問題でもカウント
                    mission.currentValue += 1

                case .solveCategory:
                    // 指定カテゴリの問題のみカウント
                    if question.subcategory == mission.filterKey {
                        mission.currentValue += 1
                    }

                case .consecutiveCorrect:
                    // 連続正解の最大値を更新
                    if isCorrect {
                        mission.currentValue = max(mission.currentValue, consecutiveCorrectRun)
                    }
                }

                // 達成チェック
                if mission.currentValue >= mission.targetValue {
                    mission.isCompleted = true
                } else {
                    allCompleted = false
                }
            }

            // 今日の未完了ミッションがなければ全達成をチェック
            if allCompleted && !missions.isEmpty {
                checkAndAwardBadge(modelContext: modelContext, date: today)
            }
        } catch {
            #if DEBUG
            print("DailyMission進捗更新エラー: \(error)")
            #endif
        }
    }

    /// 全ミッション達成時にバッジを付与
    private func checkAndAwardBadge(modelContext: ModelContext, date: Date) {
        do {
            // 今日の全ミッションが完了しているか確認
            let allDescriptor = FetchDescriptor<DailyMission>(
                predicate: #Predicate { $0.date == date }
            )
            let allMissions = try modelContext.fetch(allDescriptor)
            let allDone = allMissions.allSatisfy { $0.isCompleted }

            // バッジが未付与なら付与
            if allDone {
                let badgeDescriptor = FetchDescriptor<DailyChallengeBadge>(
                    predicate: #Predicate { $0.date == date }
                )
                let existingBadge = try modelContext.fetch(badgeDescriptor)
                if existingBadge.isEmpty {
                    let badge = DailyChallengeBadge(date: date)
                    modelContext.insert(badge)
                }
            }
        } catch {
            #if DEBUG
            print("DailyChallengeBadge確認エラー: \(error)")
            #endif
        }
    }
}
