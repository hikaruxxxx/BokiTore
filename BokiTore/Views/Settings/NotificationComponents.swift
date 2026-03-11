import SwiftUI

/// 通知スロットの1行（mikan式）
struct NotificationSlotRow: View {
    @Binding var slot: NotificationSlot
    let onChanged: () -> Void

    /// スロットの色
    private var slotColor: Color {
        switch slot.icon {
        case "sun.max.fill": return .orange
        case "bus.fill": return .appPrimary
        case "cup.and.saucer.fill": return .brown
        case "moon.fill": return .purple
        default: return .appPrimary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // アイコン（丸背景）
            Image(systemName: slot.icon)
                .font(.caption)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(slotColor)
                .clipShape(Circle())

            // ラベル + 時間
            VStack(alignment: .leading, spacing: 1) {
                Text(slot.label)
                    .font(.subheadline)
                Text(String(format: "%d:%02d", slot.hour, slot.minute))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // ON/OFFトグル
            Toggle("", isOn: $slot.isEnabled)
                .labelsHidden()
                .onChange(of: slot.isEnabled) { _, _ in
                    onChanged()
                }
        }
        .padding(.vertical, 2)
    }
}

/// 通知スロット追加シート
struct AddNotificationSlotSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var selectedTime = Calendar.current.date(from: DateComponents(hour: 12, minute: 0)) ?? Date()
    @State private var selectedIcon = "bell.fill"
    let onAdd: (NotificationSlot) -> Void

    /// 選択可能なアイコン
    private let iconOptions = [
        ("bell.fill", "ベル"),
        ("sun.max.fill", "朝"),
        ("bus.fill", "通勤"),
        ("cup.and.saucer.fill", "休憩"),
        ("moon.fill", "夜"),
        ("book.fill", "学習")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("通知名") {
                    TextField("例: 帰宅後", text: $label)
                }

                Section("時間") {
                    DatePicker("通知時間", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }

                Section("アイコン") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(iconOptions, id: \.0) { icon, name in
                            Button {
                                selectedIcon = icon
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? Color.appPrimary.opacity(0.2) : Color(.systemFill))
                                        .clipShape(Circle())
                                    Text(name)
                                        .font(.caption2)
                                }
                            }
                            .foregroundStyle(selectedIcon == icon ? Color.appPrimary : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("通知時間を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        let hour = Calendar.current.component(.hour, from: selectedTime)
                        let minute = Calendar.current.component(.minute, from: selectedTime)
                        let newSlot = NotificationSlot(
                            id: UUID(),
                            label: label.isEmpty ? "カスタム" : label,
                            hour: hour,
                            minute: minute,
                            isEnabled: true,
                            icon: selectedIcon
                        )
                        onAdd(newSlot)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// スマート通知の説明行
struct SmartNotificationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Color.appPrimary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
