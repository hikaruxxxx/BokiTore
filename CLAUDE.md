# 簿記トレ — プロジェクト設定

## 概要
日商簿記検定3級の問題演習アプリ（iOS）。広告+サブスク+アフィリエイトのハイブリッド収益モデル。

**重要: 日本語アプリであることが絶対条件。**
- UIテキスト・ボタン・ラベルはすべて日本語が基本
- 多言語対応（en/ko/zh-Hans）はLocalizable.stringsで管理するが、デフォルト言語は日本語

## 広告・課金
- Google AdMob（SPM経由）— バナー/インタースティシャル/リワード
- StoreKit 2 — 月額480円（広告非表示+AI分析）
- AdMob App ID → Info.plist / 広告ユニットID → Constants.swift
- ATT（App Tracking Transparency）対応必須
- テスト用広告IDを開発中は必ず使用

## ディレクトリ構造
→ MVP_SPEC.md 参照

## 問題データ仕様
→ MVP_SPEC.md 参照

## 評価目標スコア（簿記トレ固有）
- A群（品質系）: accessibility / performance / code-quality → 4.00+/5.00
- B群（収益系）: ad-optimization / onboarding / aso → 3.50+/5.00

## 定期UXレビュー
- 機能追加・UI変更が完了したら `ux-reviewer` でレビュー
- スコア 4.5/5 以上を維持

## App Store 審査
- 教育カテゴリ / プライバシーポリシーURL必須
- アプリ説明文に「日商簿記」は含めない → 「簿記®検定対応」と記載
