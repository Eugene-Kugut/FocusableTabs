// TabsKeyHostView.swift
import AppKit

final class TabsKeyHostView: NSView {

    var onMove: ((TabMoveDirection, Bool) -> Bool)?
    var onActivate: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onKeyboardInteraction: (() -> Void)?
    var onTabTraversalIn: ((TabMoveDirection) -> Void)?
    var lastClearToken = UUID()

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.recalculateKeyViewLoop()
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        guard ok else { return false }

        onFocusChange?(true)

        // If became firstResponder because of Tab traversal -> run entry logic.
        if let event = NSApp.currentEvent,
           event.type == .keyDown,
           event.keyCode == 48 {
            let direction: TabMoveDirection = event.modifierFlags.contains(.shift) ? .previous : .next
            onTabTraversalIn?(direction)
        }

        return true
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { onFocusChange?(false) }
        return ok
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {

        case 48: // Tab
            onKeyboardInteraction?()

            guard let window else { return }
            let isBackward = event.modifierFlags.contains(.shift)

            // IMPORTANT:
            // Tab / Shift+Tab should NOT move between tabs.
            // It should leave the control (standard key-view loop behavior).
            if isBackward {
                window.selectPreviousKeyView(self)
            } else {
                window.selectNextKeyView(self)
            }

            // If focus didn't leave (e.g. no other key views) — do nothing.
            // (No wrapping inside tabs on Tab.)

        case 49 /* Space */, 36 /* Return */, 76 /* Enter */:
            onKeyboardInteraction?()
            onActivate?()

        case 123: // Left
            onKeyboardInteraction?()
            _ = onMove?(.previous, true)

        case 124: // Right
            onKeyboardInteraction?()
            _ = onMove?(.next, true)

        default:
            super.keyDown(with: event)
        }
    }
}
