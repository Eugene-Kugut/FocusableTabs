import SwiftUI
import AppKit

struct TabsKeyHost: NSViewRepresentable {
    @Binding var isFocused: Bool

    let clearExternalFocusToken: UUID
    let onKeyboardInteraction: () -> Void

    let onMove: (TabMoveDirection, _ wrapping: Bool) -> Bool
    let onActivate: () -> Void

    /// Called ONLY when focus enters via Tab traversal (Tab / Shift+Tab).
    let onFocusInByTabTraversal: (TabMoveDirection) -> Bool

    let onFocusOut: () -> Void

    func makeNSView(context: Context) -> TabsKeyHostView {
        let view = TabsKeyHostView()
        view.focusRingType = .none

        applyCallbacks(to: view)
        view.lastClearToken = clearExternalFocusToken

        return view
    }

    func updateNSView(_ nsView: TabsKeyHostView, context: Context) {
        applyCallbacks(to: nsView)

        // 1) Clear external firstResponder when token changed
        if nsView.lastClearToken != clearExternalFocusToken {
            nsView.lastClearToken = clearExternalFocusToken
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                if window.firstResponder !== nsView {
                    window.makeFirstResponder(nil)
                }
            }
        }

        // 2) Host focus management
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }

            if isFocused {
                if window.firstResponder !== nsView {
                    window.makeFirstResponder(nsView)
                }
            } else {
                if window.firstResponder === nsView {
                    window.makeFirstResponder(nil)
                }
            }
        }
    }

    private func applyCallbacks(to view: TabsKeyHostView) {
        view.onMove = onMove
        view.onActivate = onActivate
        view.onKeyboardInteraction = onKeyboardInteraction

        view.onFocusChange = { focused in
            DispatchQueue.main.async {
                self.isFocused = focused
                if focused == false { onFocusOut() }
            }
        }

        view.onTabTraversalIn = { direction in
            DispatchQueue.main.async {
                _ = onFocusInByTabTraversal(direction)
            }
        }
    }
}
