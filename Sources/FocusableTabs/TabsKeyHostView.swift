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

        if let event = NSApp.currentEvent,
           event.type == .keyDown,
           event.keyCode == 48,
           !event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.control) {
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

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown else {
            return super.performKeyEquivalent(with: event)
        }

        if event.keyCode == 48 {
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.control) && !flags.contains(.command) && !flags.contains(.option) {
                onKeyboardInteraction?()

                let direction: TabMoveDirection = flags.contains(.shift) ? .previous : .next
                _ = onMove?(direction, true)
                return true
            }
        }

        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {

        case 48: // Tab
            onKeyboardInteraction?()

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.control) {
                let direction: TabMoveDirection = flags.contains(.shift) ? .previous : .next
                _ = onMove?(direction, true)
                return
            }

            guard let window else { return }
            if flags.contains(.shift) {
                window.selectPreviousKeyView(self)
            } else {
                window.selectNextKeyView(self)
            }

        case 49 /* Space */, 36 /* Return */, 76 /* Enter */:
            onKeyboardInteraction?()
            onActivate?()

        case 123: // Left
            onKeyboardInteraction?()
            let moved = onMove?(.previous, false) ?? false
            if moved { onActivate?() }

        case 124: // Right
            onKeyboardInteraction?()
            let moved = onMove?(.next, false) ?? false
            if moved { onActivate?() }

        default:
            super.keyDown(with: event)
        }
    }
}
