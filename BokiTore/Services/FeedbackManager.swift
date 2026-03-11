import UIKit
import AudioToolbox

/// ハプティクス＆サウンドフィードバック管理
/// 正解・不正解・コンボなどの触覚・音響フィードバックを一元管理する
/// 設定画面のToggleと連動（UserDefaults経由）
enum FeedbackManager {

    // MARK: - 設定読み取り

    /// サウンドが有効かどうか（デフォルト: ON）
    static var isSoundEnabled: Bool {
        UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true
    }

    /// ハプティクスが有効かどうか（デフォルト: ON）
    static var isHapticEnabled: Bool {
        UserDefaults.standard.object(forKey: "isHapticEnabled") as? Bool ?? true
    }

    // MARK: - フィードバック

    /// 正解フィードバック（成功振動 + 正解音）
    static func correct() {
        if isHapticEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        if isSoundEnabled {
            // システムサウンド: Tink（将来カスタム音声ファイルに置き換え可能）
            AudioServicesPlaySystemSound(1057)
        }
    }

    /// 不正解フィードバック（エラー振動 + ミス音）
    static func incorrect() {
        if isHapticEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
        if isSoundEnabled {
            AudioServicesPlaySystemSound(1053)
        }
    }

    /// コンボ達成フィードバック（中程度のインパクト振動）
    static func combo() {
        if isHapticEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// セッション完了フィードバック（成功振動）
    static func sessionComplete() {
        if isHapticEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
