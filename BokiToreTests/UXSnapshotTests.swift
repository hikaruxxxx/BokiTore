import XCTest
import SwiftUI
@testable import BokiTore

/// UXレビュー用のスナップショットを `/tmp/ux-snapshots/` に生成するテスト
/// ux-reviewer エージェントが Read ツールで画像を視覚分析する
///
/// 使い方:
/// ```
/// xcodebuild test -scheme BokiTore \
///   -destination 'platform=iOS Simulator,name=iPhone 16' \
///   -only-testing:BokiToreTests/UXSnapshotTests \
///   -quiet
/// ```
/// 生成画像: /tmp/ux-snapshots/*.png
@MainActor
final class UXSnapshotTests: XCTestCase {

    // スナップショット保存先
    private let outputDir = "/tmp/ux-snapshots"

    override func setUp() {
        super.setUp()
        try? FileManager.default.createDirectory(
            atPath: outputDir,
            withIntermediateDirectories: true
        )
    }

    // MARK: - ヘルパー

    /// SwiftUI View を PNG 画像として保存する
    private func snapshot<V: View>(
        _ view: V,
        name: String,
        width: CGFloat = 393,
        height: CGFloat = 852
    ) throws {
        let hosted = view
            .frame(width: width, height: height)
            .background(Color(.systemBackground)) // システム背景フォールバック
        let renderer = ImageRenderer(content: hosted)
        renderer.scale = 3.0

        guard let cgImage = renderer.cgImage else {
            XCTFail("\(name) のレンダリングに失敗")
            return
        }

        let data = UIImage(cgImage: cgImage).pngData()
        let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
        try data?.write(to: url)
    }

    /// コンパクトなコンポーネント用のスナップショット
    private func snapshotComponent<V: View>(
        _ view: V,
        name: String,
        width: CGFloat = 393,
        height: CGFloat = 300
    ) throws {
        try snapshot(view, name: name, width: width, height: height)
    }

    // MARK: - HomeHeroSection（ホームヒーロー）

    /// ホームヒーロー: 学習開始前（0問回答）
    func testHomeHero_noProgress() throws {
        let view = HomeHeroSection(
            todayAnswered: 0,
            dailyGoal: 20,
            streakDays: 0
        )
        .padding()

        try snapshotComponent(view, name: "home_hero_no_progress", height: 250)
    }

    /// ホームヒーロー: 途中経過（10問回答、ストリーク3日）
    func testHomeHero_inProgress() throws {
        let view = HomeHeroSection(
            todayAnswered: 10,
            dailyGoal: 20,
            streakDays: 3
        )
        .padding()

        try snapshotComponent(view, name: "home_hero_in_progress", height: 250)
    }

    /// ホームヒーロー: 目標達成（20問回答、ストリーク7日）
    func testHomeHero_goalReached() throws {
        let view = HomeHeroSection(
            todayAnswered: 20,
            dailyGoal: 20,
            streakDays: 7
        )
        .padding()

        try snapshotComponent(view, name: "home_hero_goal_reached", height: 250)
    }

    /// ホームヒーロー: 受験日カウントダウン付き
    func testHomeHero_withExamDate() throws {
        let examDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        let view = HomeHeroSection(
            todayAnswered: 5,
            dailyGoal: 20,
            streakDays: 14,
            examDate: examDate
        )
        .padding()

        try snapshotComponent(view, name: "home_hero_with_exam", height: 250)
    }

    // MARK: - CompactMenuCard（メニューカード）

    /// メニューカードの一覧
    func testMenuCards() throws {
        let view = LazyVGrid(columns: [
            GridItem(.flexible()), GridItem(.flexible())
        ], spacing: 12) {
            CompactMenuCard(icon: "book.fill", title: "問題演習", color: .appPrimary)
            CompactMenuCard(icon: "chart.bar.fill", title: "学習統計", color: .purple)
            CompactMenuCard(icon: "arrow.counterclockwise", title: "復習", color: .orange)
            CompactMenuCard(icon: "bookmark.fill", title: "ブックマーク", color: .pink)
        }
        .padding()

        try snapshotComponent(view, name: "menu_cards", height: 250)
    }

    // MARK: - NextReviewIndicator（復習予定）

    /// 復習予定インジケーター
    func testNextReviewIndicator() throws {
        let view = NextReviewIndicator(
            date: Date(),
            count: 5
        )
        .padding()

        try snapshotComponent(view, name: "next_review_indicator", height: 80)
    }

    // MARK: - 組み合わせスナップショット

    /// ホーム画面風コンポジット
    func testHomeComposite() throws {
        let view = VStack(spacing: 16) {
            // ヒーローセクション
            HomeHeroSection(
                todayAnswered: 12,
                dailyGoal: 20,
                streakDays: 5
            )

            // メニューカード
            LazyVGrid(columns: [
                GridItem(.flexible()), GridItem(.flexible())
            ], spacing: 12) {
                CompactMenuCard(icon: "book.fill", title: "問題演習", color: .appPrimary)
                CompactMenuCard(icon: "chart.bar.fill", title: "学習統計", color: .purple)
                CompactMenuCard(icon: "arrow.counterclockwise", title: "復習", color: .orange)
                CompactMenuCard(icon: "bookmark.fill", title: "ブックマーク", color: .pink)
            }

            // 復習予定
            NextReviewIndicator(date: Date(), count: 8)
        }
        .padding()

        try snapshot(view, name: "home_composite")
    }
}
