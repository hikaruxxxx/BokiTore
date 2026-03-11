# Firebase Analytics セットアップ手順

## 1. Firebase プロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを追加」をクリック
3. プロジェクト名: `BokiTore`（任意）
4. Google Analytics を有効にする → 続行
5. Analytics のアカウントを選択（または新規作成）→ プロジェクト作成

## 2. iOS アプリの登録

1. Firebase Console でプロジェクトを開く
2. 「iOS+」アイコンをクリック
3. バンドルID: `com.bokitore.BokiTore`
4. アプリのニックネーム: `簿記トレ`（任意）
5. 「アプリを登録」をクリック

## 3. GoogleService-Info.plist の配置

1. Firebase Console から `GoogleService-Info.plist` をダウンロード
2. Xcode でプロジェクトを開く
3. `BokiTore/` フォルダにドラッグ＆ドロップ
   - 「Copy items if needed」にチェック
   - 「Add to targets: BokiTore」にチェック
4. ファイルがプロジェクトツリーに表示されることを確認

> **重要**: `GoogleService-Info.plist` は `.gitignore` に含まれているため、Gitにはコミットされません。
> 新しい開発環境では必ずFirebase Consoleから再ダウンロードしてください。

## 4. 動作確認

1. アプリをビルド＆実行
2. Xcode のコンソールに以下が表示されれば成功:
   ```
   ✅ Analytics: Firebase を初期化しました
   ```
3. GoogleService-Info.plist が無い場合は以下が表示される（クラッシュしない）:
   ```
   ⚠️ Analytics: GoogleService-Info.plist が見つかりません。Firebase Analyticsは無効です。
   ```

## 5. Firebase Console でデータ確認

- イベント送信後、Firebase Console の「Analytics > イベント」で確認可能
- データ反映に最大24時間かかる場合がある
- リアルタイムデータは「Analytics > リアルタイム」で確認可能

## カスタムイベント一覧

| イベント名 | 送信タイミング | パラメータ |
|-----------|-------------|----------|
| `question_answered` | 問題回答時 | question_id, category, subcategory, is_correct, time_spent_sec |
| `session_completed` | セッション完了時 | total_questions, correct_count, accuracy_percent, session_duration_sec |
| `level_up` | マイルストーン達成時 | milestone_days, rank |
| `subscription_tapped` | 購入ボタンタップ時 | screen_name |
| `affiliate_tapped` | アフィリエイトリンクタップ時 | promo_id, source_screen |

## User Properties

| プロパティ名 | 説明 |
|------------|------|
| `target_exam_date` | 試験日（設定時のみ） |
| `study_streak_days` | 連続学習日数 |
| `total_questions_answered` | 累計回答数 |
