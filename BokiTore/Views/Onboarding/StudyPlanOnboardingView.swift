import SwiftUI
import SwiftData

/// 学習計画オンボーディング画面（初回起動時にモーダル表示）
/// 5ステップ: 学習目的 → 興味資格 → 試験日 → 目標問題数 → 学習時間
struct StudyPlanOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// 現在のステップ（0〜4）
    @State private var currentStep = 0
    /// 学習目的（ProfileOnboardingStepsで選択）
    @State private var studyPurpose: String = ""
    /// 興味のある資格（ProfileOnboardingStepsで選択）
    @State private var selectedCerts: Set<String> = []
    /// 試験日（未設定ならnil）
    @State private var examDate: Date = Calendar.current.date(byAdding: .month, value: 2, to: .now) ?? .now
    @State private var hasExamDate = false
    /// 1日の目標問題数
    @State private var dailyGoal = 10
    /// 通知スロット（mikan式の複数時間帯選択）
    @State private var notificationSlots: [NotificationSlot] = NotificationSlot.defaults
    /// 通知スロット追加シート表示
    @State private var showAddSlot = false

    /// 編集モード（設定画面から開いた場合）
    var isEditMode = false
    /// 編集対象の既存プラン
    var existingPlan: StudyPlan?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // ステップインジケーター（5ステップ）
                HStack(spacing: 8) {
                    ForEach(0..<5) { step in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(step <= currentStep ? Color.appPrimary : Color(.systemFill))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // ステップごとの内容
                ScrollView {
                    switch currentStep {
                    case 0:
                        StudyPurposeStep(selectedPurpose: $studyPurpose)
                    case 1:
                        InterestedCertsStep(selectedCerts: $selectedCerts)
                    case 2:
                        examDateStep
                    case 3:
                        dailyGoalStep
                    default:
                        studyTimeStep
                    }
                }

                Spacer()

                // ナビゲーションボタン
                VStack(spacing: 12) {
                    Button {
                        if currentStep < 4 {
                            withAnimation { currentStep += 1 }
                        } else {
                            savePlan()
                        }
                    } label: {
                        Text(currentStep < 4 ? "次へ" : "始める")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appPrimary)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if currentStep > 0 {
                        Button("戻る") {
                            withAnimation { currentStep -= 1 }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
            .navigationTitle(isEditMode ? "学習計画の編集" : "学習計画")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("スキップ") {
                            skipOnboarding()
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .onAppear {
                loadExistingPlan()
            }
        }
    }

    // MARK: - ステップ1: 試験日

    private var examDateStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(Color.appPrimary)

            Text("試験日はいつですか？")
                .font(.title2)
                .fontWeight(.bold)

            Text("目標に合わせた学習プランを作ります")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle("試験日を設定する", isOn: $hasExamDate)
                .padding(.horizontal, 40)

            if hasExamDate {
                DatePicker("試験日", selection: $examDate, in: Date.now..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - ステップ2: 目標問題数（mikan式の楽しい名前つき）

    /// 目標オプション（問題数, 名前, 説明）
    private var goalOptions: [(goal: Int, name: String, description: String)] {
        [
            (5,  "コツコツ型",      "5問 — まずは習慣づけから"),
            (10, "1歩ずつ前に進む", "10問 — 無理なく続けられる"),
            (15, "頑張る",         "15問 — しっかり実力アップ"),
            (20, "圧倒的に頑張る",  "20問 — 本気で合格を目指す")
        ]
    }

    private var dailyGoalStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(Color.appSecondary)

            Text("1日の目標は？")
                .font(.title2)
                .fontWeight(.bold)

            Text("無理のないペースで続けましょう")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // 目標問題数の選択（mikan式カードUI）
            VStack(spacing: 12) {
                ForEach(goalOptions, id: \.goal) { option in
                    let isSelected = dailyGoal == option.goal
                    let isRecommended = option.goal == 10
                    Button {
                        dailyGoal = option.goal
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(option.name)
                                        .font(.headline)
                                    if isRecommended {
                                        Text("おすすめ")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.appPrimary)
                            }
                        }
                        .padding()
                        .background(isSelected ? Color.appPrimary.opacity(0.1) : Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.appPrimary : Color(.separator), lineWidth: isSelected ? 2 : 1)
                        )
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - ステップ3: 学習時間（mikan式の複数スロット選択）

    /// スロットアイコンの色を返す
    private func slotColor(for icon: String) -> Color {
        switch icon {
        case "sun.max.fill": return .orange
        case "bus.fill": return .appPrimary
        case "cup.and.saucer.fill": return .pink
        case "moon.fill": return .blue.opacity(0.7)
        default: return .appPrimary
        }
    }

    private var studyTimeStep: some View {
        VStack(spacing: 16) {
            // ソーシャルプルーフ（mikan式）
            Text("1ヶ月以上続いている人の\n77%が時間を決めているよ")
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

            // 通知スロット一覧（mikan式カード）
            VStack(spacing: 0) {
                ForEach(Array(notificationSlots.enumerated()), id: \.element.id) { index, slot in
                    HStack(spacing: 12) {
                        // アイコン（丸背景）
                        Image(systemName: slot.icon)
                            .font(.caption)
                            .foregroundStyle(slotColor(for: slot.icon).opacity(0.8))
                            .frame(width: 40, height: 40)
                            .background(slotColor(for: slot.icon).opacity(0.15))
                            .clipShape(Circle())

                        // ラベル + 時間
                        VStack(alignment: .leading, spacing: 2) {
                            Text(slot.label)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(String(format: "%d:%02d", slot.hour, slot.minute))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // ON/OFFトグル
                        Toggle("", isOn: $notificationSlots[index].isEnabled)
                            .labelsHidden()
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)

                    if index < notificationSlots.count - 1 {
                        Divider()
                            .padding(.leading, 68)
                    }
                }

                Divider()
                    .padding(.leading, 68)

                // 追加ボタン
                Button {
                    showAddSlot = true
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.subheadline)
                        Text("追加")
                            .font(.subheadline)
                    }
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showAddSlot) {
            AddNotificationSlotSheet { newSlot in
                notificationSlots.append(newSlot)
            }
        }
    }

    // MARK: - ヘルパー

    /// 既存プランの読み込み（編集モード用）
    private func loadExistingPlan() {
        guard let plan = existingPlan else { return }
        // プロフィール情報
        studyPurpose = plan.studyPurpose
        selectedCerts = Set(plan.getInterestedCerts())
        // 試験日
        if let date = plan.examDate {
            examDate = date
            hasExamDate = true
        }
        dailyGoal = plan.dailyGoal
        notificationSlots = plan.getNotificationSlots()
    }

    /// 学習計画を保存してモーダルを閉じる
    private func savePlan() {
        // 最初の有効スロットの時間をpreferredHour/Minuteに使う
        let firstEnabled = notificationSlots.first(where: { $0.isEnabled })
        let hour = firstEnabled?.hour ?? 20
        let minute = firstEnabled?.minute ?? 0

        if let existing = existingPlan {
            // 既存プランを更新
            existing.studyPurpose = studyPurpose
            existing.setInterestedCerts(Array(selectedCerts))
            existing.examDate = hasExamDate ? examDate : nil
            existing.dailyGoal = dailyGoal
            existing.preferredHour = hour
            existing.preferredMinute = minute
            existing.isOnboardingCompleted = true
            existing.setNotificationSlots(notificationSlots)
        } else {
            // 新規プランを作成
            let plan = StudyPlan(
                examDate: hasExamDate ? examDate : nil,
                dailyGoal: dailyGoal,
                preferredHour: hour,
                preferredMinute: minute,
                isOnboardingCompleted: true,
                studyPurpose: studyPurpose
            )
            plan.setInterestedCerts(Array(selectedCerts))
            plan.setNotificationSlots(notificationSlots)
            modelContext.insert(plan)
        }

        dismiss()
    }

    /// オンボーディングをスキップ
    private func skipOnboarding() {
        // デフォルト値で学習計画を作成
        let plan = StudyPlan(
            dailyGoal: 10,
            preferredHour: 20,
            preferredMinute: 0,
            isOnboardingCompleted: true
        )
        modelContext.insert(plan)
        dismiss()
    }
}

#Preview {
    StudyPlanOnboardingView()
        .modelContainer(.preview)
}
