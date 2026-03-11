# 簿記トレ — プロジェクト設定

## プロジェクト概要
日商簿記検定3級の問題演習アプリ（iOS）。広告+サブスク+アフィリエイトのハイブリッド収益モデル。
開発者はプログラミング初心者。Claude Codeが主要な開発ツール。

## 技術スタック
- **言語**: Swift 5.9+
- **UI**: SwiftUI（UIKit不使用）
- **最小対応OS**: iOS 17.0
- **アーキテクチャ**: MVVM + Swift Data（CoreData不使用）
- **パッケージ管理**: Swift Package Manager（CocoaPods/Carthage不使用）
- **広告SDK**: Google AdMob（SPM経由）
- **ビルド**: Xcode 16+

## ディレクトリ構造
```
BokiTore/
├── BokiToreApp.swift          # エントリポイント
├── Models/
│   ├── Question.swift          # 問題データモデル
│   ├── Category.swift          # カテゴリ（仕訳、勘定科目等）
│   ├── StudySession.swift      # 学習セッション記録
│   └── UserProgress.swift      # 進捗・統計データ
├── Views/
│   ├── Home/
│   │   └── HomeView.swift      # ホーム画面
│   ├── Quiz/
│   │   ├── QuizView.swift      # 問題画面
│   │   ├── QuizResultView.swift # 結果画面
│   │   └── ExplanationView.swift # 解説画面
│   ├── Stats/
│   │   └── StatsView.swift     # 統計・分析画面
│   ├── Settings/
│   │   └── SettingsView.swift  # 設定画面
│   └── Components/
│       ├── AdBannerView.swift  # AdMobバナー
│       └── CommonComponents.swift
├── ViewModels/
│   ├── QuizViewModel.swift
│   ├── StatsViewModel.swift
│   └── HomeViewModel.swift
├── Data/
│   ├── QuestionBank.json       # 問題データ（アプリ内バンドル）
│   └── QuestionLoader.swift    # JSON読み込み
├── Services/
│   ├── AdManager.swift         # 広告管理（バナー/インタースティシャル/リワード）
│   ├── StoreManager.swift      # サブスク管理（StoreKit 2）
│   └── ReviewManager.swift     # レビュー誘導（SKStoreReviewController）
├── Utilities/
│   ├── Extensions.swift
│   └── Constants.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── QuestionLoaderTests.swift
    └── QuizViewModelTests.swift
```

## コーディング規約

### 必須ルール
- **SwiftUIのみ使用**。UIKitのUIViewRepresentable使用は広告SDK連携のみ許可
- **Swift Data**を使用。CoreDataは使わない
- **async/await**を使用。Combine/RxSwiftは使わない
- **エラーハンドリング必須**。do-catch で適切にエラーを処理すること
- **日本語コメント**でコードの意図を説明すること（開発者が初心者のため）
- **ハードコードされた認証情報を絶対に含めない**（AdMob ID等はConstants.swiftで管理）
- print文はデバッグ用のみ。リリースビルドではログ出力しない

### 命名規則
- ファイル名: PascalCase（QuizView.swift）
- 変数・関数: camelCase（currentQuestion, loadQuestions()）
- 定数: camelCase（maxRetryCount）
- 型: PascalCase（QuestionCategory）

### SwiftUI固有
- @State, @Binding, @Observable を適切に使い分ける
- Viewは小さく分割する（1ファイル200行以下目安）
- PreviewProviderを全Viewに付ける（開発効率のため）

## 問題データ仕様

### QuestionBank.json のスキーマ
```json
{
  "version": "1.0",
  "questions": [
    {
      "id": "q001",
      "category": "journalEntry",
      "subcategory": "sales",
      "difficulty": 1,
      "questionType": "multipleChoice",
      "questionText": "商品100,000円を掛けで売り上げた。正しい仕訳はどれか。",
      "choices": [
        {"id": "a", "debit": "売掛金 100,000", "credit": "売上 100,000"},
        {"id": "b", "debit": "売上 100,000", "credit": "売掛金 100,000"},
        {"id": "c", "debit": "買掛金 100,000", "credit": "売上 100,000"},
        {"id": "d", "debit": "売掛金 100,000", "credit": "仕入 100,000"}
      ],
      "correctAnswer": "a",
      "explanation": "掛けでの売上は、借方に売掛金（資産の増加）、貸方に売上（収益の発生）を記入します。",
      "tags": ["売掛金", "売上", "掛取引"]
    }
  ]
}
```

### カテゴリ一覧
- journalEntry: 仕訳問題
- accountTitle: 勘定科目の分類
- trialBalance: 試算表
- financialStatements: 財務諸表（貸借対照表・損益計算書）
- vocabulary: 簿記用語

### 難易度
- 1: 基本（初学者向け）
- 2: 標準（合格レベル）
- 3: 応用（高得点狙い）

## 広告設計

### AdMob設定
- バナー広告: 問題一覧画面の下部に常時表示
- インタースティシャル広告: 10問解答ごとに1回表示
- リワード動画広告: 「ヒントを見る」ボタンで任意視聴
- **テスト用広告IDを開発中は必ず使用すること**

### サブスク（StoreKit 2）
- 月額480円: 広告非表示 + AI分析機能
- Apple Small Business Program適用（手数料15%）

## セキュリティ要件
- AdMob App IDはInfo.plistで管理（コードにハードコードしない）
- 広告ユニットIDはConstants.swiftで環境変数的に管理
- ユーザーデータはデバイスローカルのみ（外部送信しない）
- ATT（App Tracking Transparency）対応必須

## テスト方針
- ViewModelの単体テストを最優先
- QuestionLoaderのJSONパース正常系・異常系テスト
- UIテストは後回し（MVP段階では不要）

## App Store審査対策
- プライバシーポリシーURL必須（LP上に設置）
- App Privacy Questionnaire: 広告ID収集のみ申告
- 教育カテゴリで申請
- スクリーンショットは実機で撮影（シミュレータNG）
- アプリ説明文に「日商簿記」は含めない。「簿記®検定対応」と記載
