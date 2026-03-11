import SwiftUI

/// 紙吹雪パーティクル
struct ConfettiParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let color: Color
    let size: CGFloat
    var rotation: Double
    let speed: Double
}

/// お祝いオーバーレイ（紙吹雪 + メッセージ表示）
/// デイリー完了・マイルストーン達成・クイズ結果で共通使用
struct CelebrationOverlay: View {
    @Binding var isShowing: Bool
    /// メインタイトル（例: "完璧", "7日達成!", "コンプリート!"）
    let title: String
    /// サブタイトル（例: "すべて正解！", "Bronze ストリーク"）
    let subtitle: String

    /// 紙吹雪パーティクル
    @State private var particles: [ConfettiParticle] = []
    /// フェードアウト制御
    @State private var opacity: Double = 1.0
    /// タイトルスケール
    @State private var titleScale: Double = 0.3

    /// 紙吹雪の色パレット
    private let colors: [Color] = [
        .appPrimary, .appSecondary, .orange, .purple, .yellow
    ]

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.15)
                .ignoresSafeArea()

            // 紙吹雪パーティクル
            ForEach(particles) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.6)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
            }

            // メッセージ
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)

                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .scaleEffect(titleScale)
        }
        .opacity(opacity)
        .onAppear {
            startAnimation()
        }
        .allowsHitTesting(true)
        .onTapGesture {
            dismissOverlay()
        }
    }

    /// アニメーション開始
    private func startAnimation() {
        // パーティクル生成
        let screenWidth = UIScreen.main.bounds.width
        particles = (0..<40).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -50...(-10)),
                color: colors.randomElement() ?? .orange,
                size: CGFloat.random(in: 6...12),
                rotation: Double.random(in: 0...360),
                speed: Double.random(in: 2...5)
            )
        }

        // タイトル登場アニメーション
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            titleScale = 1.0
        }

        // 紙吹雪を落下させる
        animateParticles()

        // 2.5秒後にフェードアウト
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            dismissOverlay()
        }
    }

    /// 紙吹雪の落下アニメーション
    private func animateParticles() {
        let screenHeight = UIScreen.main.bounds.height
        withAnimation(.easeIn(duration: 2.0)) {
            for index in particles.indices {
                particles[index].y = screenHeight + 50
                particles[index].x += CGFloat.random(in: -80...80)
                particles[index].rotation += Double.random(in: 180...720)
            }
        }
    }

    /// オーバーレイを消す
    private func dismissOverlay() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isShowing = false
        }
    }
}

#Preview {
    @Previewable @State var showing = true
    ZStack {
        Color(.systemBackground)
        Text("背景コンテンツ")
        if showing {
            CelebrationOverlay(
                isShowing: $showing,
                title: "完璧",
                subtitle: "すべて正解！"
            )
        }
    }
}
