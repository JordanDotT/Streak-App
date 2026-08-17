import SwiftUI

/// A single Tinder-style reflection card. Drag past a threshold in either direction
/// to dismiss it; `onSwiped` advances the deck. Fresh implementation (Energy Calendar
/// is reference only — §0).
struct SwipeCard: View {
    let text: String
    let isTop: Bool
    let onSwiped: () -> Void

    @State private var offset: CGSize = .zero

    private let swipeThreshold: CGFloat = 120

    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.background)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.quaternary, lineWidth: 1)
            )
            .overlay(
                Text(text)
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(28)
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(isTop ? dragGesture : nil)
            .animation(.spring(duration: 0.35), value: offset)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { offset = $0.translation }
            .onEnded { value in
                if abs(value.translation.width) > swipeThreshold {
                    // Fling the card off-screen, then advance.
                    let direction: CGFloat = value.translation.width > 0 ? 1 : -1
                    offset = CGSize(width: direction * 1000, height: value.translation.height)
                    onSwiped()
                } else {
                    offset = .zero
                }
            }
    }
}
