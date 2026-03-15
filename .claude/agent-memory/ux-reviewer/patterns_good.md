---
name: 良いUXパターン（BokiTore）
description: 学習アプリとして優れた実装パターン。次回レビューで継続確認する。
type: project
---

# 良いUXパターン

## 差分学習の原則
- ExplanationView: 不正解時に UserAnswerSection + CorrectAnswerSection を縦並びで比較表示
- ExplanationView: 不正解時は isDetailExpanded = true でデフォルト解説展開

## 内部ID隠蔽
- blankLabel() 関数で "blank_1" → "空欄①" に変換し全コンポーネントで共通使用
- Extensions.swift:161-168 に定義

## ゲーミフィケーション
- コンボは「3の倍数」のみ追加フィードバック（過剰演出を避けつつモチベーション刺激）
- QuizViewModel.swift:198-200

## アクセシビリティ
- UIAccessibility.post(notification: .announcement) で正誤を VoiceOver に通知
- WCAG AA準拠カラーパレット（appPrimary/appSecondary/appError/appOrange）
- 標準の .orange を使わず appOrange を独自定義

## 空入力防止
- allBlanksAnswered / allAnswered が全フォーマットで実装済み
- 未入力時はボタンを .disabled(true) にして視覚的にもグレーアウト

## 適応型出題
- AdaptiveQuestionSelector で弱点・未挑戦・復習・得意をバランス選出
- ExamSectionView の「おすすめ10問」に適用
