---
name: 問題UXパターン（BokiTore）
description: 再発防止すべき問題パターン。次回レビューで同じ問題が起きていないか確認する。
type: project
---

# 問題UXパターン（再発防止）

## 選択肢が正解を含まない可能性（最高リスク）
- TAccountFillComponents.swift の account 型: prefilledEntries + blanks の correctAnswer から生成
- TAccountFillComponents.swift の description 型: ハードコードリスト固定
- 次回確認: 新しい問題フォーマット追加時、Picker の選択肢に correctAnswer が含まれることをテストで保証しているか

## 解答後の UI 空白問題
- TheoryFillView: 解答ボタンを `if !viewModel.showResult` で完全削除している
- 対策: ボタンを消すのではなく「解答済み」状態に変えて連続性を保つ
- 次回確認: 新しいフォーマット追加時、解答後に UI が消えて空白にならないか

## numberPad のキーボード閉じる手段なし
- TAccountFillComponents: 金額入力に numberPad を使うがキーボードを閉じる UI がない
- 対策: .toolbar { ToolbarItemGroup(placement: .keyboard) { ... } } で「完了」ボタン追加
- 次回確認: numberPad を使う TextField が追加されたときに必ずキーボード解除手段があるか

## .caption2 フォントの多用
- DifficultyBadge、T勘定日付で使用
- 対策: .caption 以上を基本とする

## ハードコードされた日本語文字列
- DailyChallengeSection:60-61: CelebrationOverlay の subtitle "今日のチャレンジ達成 🎉" がハードコード（title の "コンプリート!" は Localizable.strings に "home.complete" として登録済みだが、コード側は String(localized:) を使っていない。subtitle は keys 自体未登録）
- QuizResultView:32: rankInfo の fallback "挑戦者"/"復習して強くなろう！" がハードコード（実害は限定的だが修正すべき）
- 対策: String(localized:) を使う。subtitle 用のキーを Localizable.strings に追加する。

## オンボーディング中の2重ペイウォール
- StudyPlanOnboardingView: ステップ4と7の2箇所にペイウォールを挿入している
- ユーザーはコアアクション体験前に2度の購入要求を受ける（Day 0離脱リスク最大）
- 対策: ペイウォールを1箇所に絞るか、コアアクション体験後に1度だけ表示する

## 通知文の感情訴求弱さ
- SmartReminderManager: 通知タイトルがすべて「簿記トレ」固定（差別化なし）
- 文体が「今日の目標: X問に挑戦しましょう!」「N日連続の記録が途切れそうです!」と指示型
- 対策: パーソナライズされた励ましコピーを複数バリエーション用意し、ランダム選択する
