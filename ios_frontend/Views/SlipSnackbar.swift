import SwiftUI

/// Bottom snackbar shown while a slip can still be undone (§5.4). No confirmation
/// modal — the friction is the undo window, not an alert.
struct SlipSnackbarModifier: ViewModifier {
    @ObservedObject var controller: SlipController

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if controller.pending != nil {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Streak reset to 0")
                            .font(.subheadline)
                        Spacer(minLength: 8)
                        Button("Undo") { controller.undo() }
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.regularMaterial, in: Capsule())
                    .shadow(radius: 8, y: 2)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: controller.pending != nil)
    }
}

extension View {
    func slipSnackbar(_ controller: SlipController) -> some View {
        modifier(SlipSnackbarModifier(controller: controller))
    }
}
