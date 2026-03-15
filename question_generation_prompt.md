# 簿記3級 問題生成プロンプト（Claude Code用）

## 目的
`boki3_pattern_db.json` と `account_master.json` を参照し、アプリ同梱用の500問をJSON形式で生成する。

## 入力ファイル
1. `boki3_pattern_db.json` — 出題パターン・カテゴリ・頻度ランク・ひっかけポイント
2. `account_master.json` — 勘定科目マスタ・紛らわしいペア・補助簿リスト・理論トピック
3. `claude_code_boki3_mvp.md` — JSONフォーマット定義（Phase 6参照）

## 出力ファイル（6つ）

| ファイル名 | 問題数 | 内容 |
|-----------|--------|------|
| `questions_dai1_shiwake.json` | 300問 | 第1問: CBT仕訳入力 |
| `questions_dai2_kanjou.json` | 100問 | 第2問⑴: T勘定空欄補充 |
| `questions_dai2_hojo.json` | 50問 | 第2問⑵-A: 補助簿選択 |
| `questions_dai2_riron.json` | 50問 | 第2問⑵-B: 理論穴埋め |
| `diagnosis_questions.json` | 20問 | 実力診断用固定セット |
| `difficulty_stats.json` | — | 初期値（全問difficulty通りの値を設定） |

---

## 生成ルール

### 共通ルール
1. **全問オリジナル**: 市販問題集・過去問の文面をそのままコピーしない。パターンと構造を参考にし、独自の取引内容・金額・勘定科目の組み合わせで作成すること
2. **金額のリアリティ**: 1,000円〜10,000,000円の範囲。端数は原則なし（千円単位）。消費税計算が絡む場合は税込=本体×1.1で割り切れる金額にする
3. **IDの命名規則**: `dai1_shiwake_001`〜`dai1_shiwake_300`, `dai2_kanjou_001`〜`dai2_kanjou_100`, `dai2_hojo_001`〜`dai2_hojo_050`, `dai2_riron_001`〜`dai2_riron_050`
4. **解説は2パートで構成**:
   - `explanation`（解説本文）: ひっかけポイント・間違えやすい点・計算過程を含む。「なぜその仕訳になるのか」を初学者にも分かるように説明
   - `termDefinitions`（用語説明配列）: 正解で使う主要勘定科目（2〜4個）を以下の構造で説明
     ```json
     {
       "term": "勘定科目名",
       "category": "資産/負債/純資産/収益/費用",
       "definition": "簿記的な定義（1〜2文）",
       "realWorldExample": "日常生活やビジネスに置き換えた具体例（初学者向け）"
     }
     ```
   - **realWorldExampleのルール**: 「米屋が米を買うこと」「月末に届く電気代の請求書」のような、誰でもイメージできる身近な例にする。抽象的な説明は不可
5. **frequencyRank**: pattern_db.jsonのカテゴリ頻度（A/B/C）をそのまま付与
6. **tags**: 使用する主要勘定科目名 + 論点キーワード（2〜5個）

### 第1問: CBT仕訳入力（300問）

**フォーマット**: `cbt_journal_entry`

```json
{
  "id": "dai1_shiwake_XXX",
  "examSection": "第1問",
  "category": "《pattern_dbのカテゴリ名》",
  "subcategory": "《pattern_dbのpattern description》",
  "difficulty": 1〜3,
  "format": "cbt_journal_entry",
  "questionText": "《取引文》",
  "questionData": {
    "type": "journalEntry",
    "accountCandidates": ["《正解で使う勘定科目》", "《ダミー勘定科目》", ...],
    "correctEntries": [
      { "side": "debit", "account": "XXX", "amount": 99999 },
      { "side": "credit", "account": "YYY", "amount": 99999 }
    ]
  },
  "explanation": "《解説文: ひっかけポイント・計算過程・判断理由》",
  "termDefinitions": [
    {
      "term": "《勘定科目名》",
      "category": "費用",
      "definition": "《簿記的な定義》",
      "realWorldExample": "《日常生活の具体例》"
    }
  ],
  "tags": ["tag1", "tag2"],
  "frequencyRank": "A/B/C"
}
```

**accountCandidates生成ルール:**
- 正解で使う勘定科目（2〜4個）+ ダミー（2〜4個）= 合計6個
- ダミーは `account_master.json` の `confusing_pairs` を優先的に使用
- 全く無関係なダミーは最大1個

**難易度配分（300問）:**
- difficulty 1（基礎）: 90問（30%）— 単純な1行仕訳、教科書の典型例
- difficulty 2（標準）: 150問（50%）— 複合仕訳、付随費用、手付金相殺
- difficulty 3（応用）: 60問（20%）— ひっかけ、複数論点の組み合わせ

**カテゴリ配分（300問）:**
- 頻度A（10カテゴリ）: 各18問 = 180問
- 頻度B（6カテゴリ）: 各15問 = 90問
- 頻度C（3カテゴリ）: 各10問 = 30問

**ひっかけパターンの組み込み:**
pattern_db.json の各カテゴリにある `trap_patterns` を必ず問題に反映する。例:
- 「切手=通信費、印紙=租税公課の区別」→ 切手と印紙を同時に購入する問題
- 「引取運賃は仕入原価に含める」→ 引取運賃と発送費を混同させる問題
- 「前期分→貸倒引当金充当、当期分→貸倒損失」→ 前期と当期の売掛金が混在する問題

### 第2問⑴: T勘定空欄補充（100問）

**フォーマット**: `t_account_fill`

```json
{
  "id": "dai2_kanjou_XXX",
  "examSection": "第2問⑴",
  "category": "勘定記入",
  "subcategory": "《pattern_dbの第2問サブパターン》",
  "difficulty": 2〜3,
  "format": "t_account_fill",
  "questionText": "《資料と指示》",
  "questionData": {
    "type": "tAccountFill",
    "accountName": "《勘定科目名》",
    "prefilledEntries": [
      { "side": "debit", "description": "前期繰越", "amount": 300000, "date": "4/1" }
    ],
    "blanks": [
      { "id": "blank_1", "side": "credit", "position": 1, "answerType": "description", "correctAnswer": "次期繰越" },
      { "id": "blank_2", "side": "credit", "position": 1, "answerType": "amount", "correctAnswer": "300000" }
    ]
  },
  "explanation": "《解説》",
  "termDefinitions": [
    {
      "term": "《勘定科目名》",
      "category": "《分類》",
      "definition": "《定義》",
      "realWorldExample": "《具体例》"
    }
  ],
  "tags": [...],
  "frequencyRank": "A"
}
```

**サブパターン配分（100問）:**
- 損益勘定・繰越利益剰余金: 25問
- 固定資産台帳→勘定記入: 30問
- 商品売買3分法の勘定記入: 25問
- 前払・前受の勘定記入: 20問

**空欄の設計ルール:**
- 1問あたりの空欄数: 3〜6個
- answerType の混在: "account"（勘定科目プルダウン）+ "amount"（金額入力）+ "description"（摘要プルダウン）を組み合わせる
- 事前記入済みエントリは最低2個（ヒントとして機能）

### 第2問⑵-A: 補助簿選択（50問）

**フォーマット**: `subledger_select`

```json
{
  "id": "dai2_hojo_XXX",
  "examSection": "第2問⑵",
  "category": "補助簿選択",
  "subcategory": "補助簿",
  "difficulty": 1〜2,
  "format": "subledger_select",
  "questionText": "次の各取引について、記入される補助簿をすべて選びなさい。",
  "questionData": {
    "type": "subledgerSelect",
    "transactions": [
      {
        "id": "tx_1",
        "description": "A商店から商品¥50,000を掛けで仕入れた",
        "correctSubledgers": ["仕入帳", "買掛金元帳", "商品有高帳"]
      },
      ...（1問につき取引5〜8個）
    ],
    "subledgerOptions": ["現金出納帳", "当座預金出納帳", "仕入帳", "売上帳", "受取手形記入帳", "支払手形記入帳", "売掛金元帳", "買掛金元帳", "商品有高帳"]
  },
  "explanation": "《各取引ごとの補助簿対応の解説》",
  "termDefinitions": [
    {
      "term": "《補助簿名》",
      "category": "補助簿",
      "definition": "《記録する内容》",
      "realWorldExample": "《具体例》"
    }
  ],
  "tags": [...],
  "frequencyRank": "B"
}
```

**取引パターンの網羅:**
- 現金取引、当座預金取引、掛取引、手形取引、商品売買を均等にカバー
- 1つの取引が複数の補助簿に記入されるケースを重視
- 「商品有高帳」の対象/非対象の判断が問われるパターンを多めに

### 第2問⑵-B: 理論穴埋め（50問）

**フォーマット**: `theory_fill`

```json
{
  "id": "dai2_riron_XXX",
  "examSection": "第2問⑵",
  "category": "理論穴埋め",
  "subcategory": "《account_master.jsonのtheory_topicsのtitle》",
  "difficulty": 1〜2,
  "format": "theory_fill",
  "questionText": "次の文章の空欄に当てはまる語句を語群から選びなさい。",
  "questionData": {
    "type": "theoryFill",
    "passage": "帳簿は主要簿と[blank_1]に分けられる。主要簿は仕訳帳と[blank_2]から構成される。",
    "blanks": [
      { "id": "blank_1", "options": ["補助簿", "総勘定元帳", "試算表", "補助記入帳", "補助元帳", "仕訳帳"], "correctAnswer": "補助簿" },
      { "id": "blank_2", "options": ["補助簿", "総勘定元帳", "試算表", "補助記入帳", "補助元帳", "仕訳帳"], "correctAnswer": "総勘定元帳" }
    ]
  },
  "explanation": "《概念の解説》",
  "termDefinitions": [
    {
      "term": "《用語》",
      "category": "《分類》",
      "definition": "《定義》",
      "realWorldExample": "《具体例》"
    }
  ],
  "tags": [...],
  "frequencyRank": "B"
}
```

**トピック配分（50問）:**
- 帳簿組織: 10問
- 試算表: 8問
- 財務諸表: 8問
- 減価償却: 8問
- 商品売買: 6問
- 経過勘定: 6問
- 会計原則: 4問

**穴埋め設計ルール:**
- 1問あたりの空欄数: 2〜4個
- 語群は6〜8個（正解+紛らわしいダミー）
- 同じ語句が複数の空欄の正解になることもある

---

## 実力診断用問題セット（20問）

`diagnosis_questions.json` は上記4ファイルから選抜して構成。

**選抜基準:**
- 各カテゴリの difficulty: 2（標準）を1問ずつ選ぶ
- 頻度A: 10問、頻度B: 7問、頻度C: 3問
- 第1問形式: 14問、第2問⑴形式: 3問、第2問⑵-A形式: 2問、第2問⑵-B形式: 1問

```json
{
  "version": "1.0",
  "description": "実力診断テスト用20問セット",
  "questions": [
    "dai1_shiwake_005",
    "dai1_shiwake_023",
    ...（IDの参照リスト）
  ]
}
```

---

## 品質チェックリスト

各問題について以下を検証すること:

### 会計的正確性
- [ ] 借方合計 = 貸方合計が成立するか
- [ ] 勘定科目の使い方は簿記3級の範囲内か（2級以上の科目を使っていないか）
- [ ] 消費税計算は税込÷1.1で整数になるか
- [ ] 利息計算の月数は正しいか（両端入れ/片落とし等）
- [ ] 減価償却の月割計算は正しいか

### 問題設計
- [ ] accountCandidates に正解の勘定科目が全て含まれているか
- [ ] accountCandidates は6個（多すぎず少なすぎず）か
- [ ] ダミーの勘定科目は紛らわしいが不自然ではないか
- [ ] 問題文だけで仕訳が一意に確定するか（情報不足がないか）
- [ ] 解説文は初学者が読んで理解できる内容か
- [ ] termDefinitionsに正解で使う主要勘定科目が2〜4個含まれているか
- [ ] 各termのcategoryがaccount_master.jsonの分類と一致しているか
- [ ] realWorldExampleが抽象的でなく、具体的な日常例になっているか

### T勘定（第2問⑴）
- [ ] 借方合計 = 貸方合計になるか（勘定の締切が正しいか）
- [ ] 空欄の正解を埋めると整合するか
- [ ] prefilledEntries だけでは正解が確定しないか（考えさせる設計か）

### JSON構造
- [ ] 全フィールドが `claude_code_boki3_mvp.md` Phase 6 のスキーマに準拠しているか
- [ ] IDが連番で重複していないか
- [ ] JSONとしてパース可能か（構文エラーなし）

---

## 生成の進め方

### ステップ1: まず10問ずつ生成してレビュー
- 第1問: 10問（頻度Aから各カテゴリ1問）
- 第2問⑴: 3問（固定資産・商品売買・前払費用）
- 第2問⑵-A: 2問
- 第2問⑵-B: 2問
→ 合計17問をhikaruがレビュー

### ステップ2: レビューフィードバック反映
- 問題の難易度感覚を調整
- 解説の粒度を調整
- 金額のリアリティを調整

### ステップ3: 残り全問を一括生成
- レビュー済みの17問をテンプレートとして残りを生成
- 生成後にJSONバリデーション（パース+借方貸方一致チェック）

### ステップ4: diagnosis_questions.json 選抜
- 500問から20問を品質・バランス基準で選抜
