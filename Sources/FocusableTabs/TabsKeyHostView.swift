// TabsKeyHostView.swift
import AppKit

final class TabsKeyHostView: NSView {

    var onMove: ((TabMoveDirection, Bool) -> Bool)?
    var onActivate: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onKeyboardInteraction: (() -> Void)?
    var onTabTraversalIn: ((TabMoveDirection) -> Void)?
    var lastClearToken = UUID()

    private var keyDownMonitorToken: Any?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.recalculateKeyViewLoop()

        if window != nil {
            installKeyDownMonitorIfNeeded()
        } else {
            removeKeyDownMonitorIfNeeded()
        }
    }

    deinit {
        removeKeyDownMonitorIfNeeded()
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        guard ok else { return false }

        onFocusChange?(true)

        // Entry logic ONLY for plain Tab traversal (NOT ctrl+tab).
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

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {

        case 48: // Tab
            onKeyboardInteraction?()

            // Plain Tab / Shift+Tab -> leave the control via key-view loop.
            // Ctrl+Tab is handled by the local event monitor (reliable).
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains(.control) {
                // If it still arrives here (rare), keep cyclic behavior.
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

        case 123: // Left (NO wrap) + activate
            onKeyboardInteraction?()
            let moved = onMove?(.previous, false) ?? false
            if moved { onActivate?() }

        case 124: // Right (NO wrap) + activate
            onKeyboardInteraction?()
            let moved = onMove?(.next, false) ?? false
            if moved { onActivate?() }

        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Reliable Ctrl+Tab interception (per-instance)

    private func installKeyDownMonitorIfNeeded() {
        guard keyDownMonitorToken == nil else { return }

        keyDownMonitorToken = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            guard let window = self.window, event.window === window else { return event }
            guard window.firstResponder === self else { return event }

            // Ctrl+Tab / Ctrl+Shift+Tab -> cyclic navigation (like you want)
            if event.keyCode == 48 {
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                if flags.contains(.control) && !flags.contains(.command) && !flags.contains(.option) {
                    self.onKeyboardInteraction?()
                    let direction: TabMoveDirection = flags.contains(.shift) ? .previous : .next
                    _ = self.onMove?(direction, true) // wrapping=true (cyclic)
                    return nil // swallow event so menu/key-equivalent won't steal it
                }
            }

            return event
        }
    }

    private func removeKeyDownMonitorIfNeeded() {
        guard let token = keyDownMonitorToken else { return }
        NSEvent.removeMonitor(token)
        keyDownMonitorToken = nil
    }
}
