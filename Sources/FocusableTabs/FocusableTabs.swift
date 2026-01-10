import SwiftUI
import AppKit

/// Keyboard-focusable horizontal tabs (macOS).
public struct FocusableTabs<ID: Hashable, Label: View>: View {

    // MARK: - Item

    public struct Item: Identifiable {
        public var id: ID
        public var isEnabled: Bool
        public var label: () -> Label

        public init(
            _ id: ID,
            isEnabled: Bool = true,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.id = id
            self.isEnabled = isEnabled
            self.label = label
        }
    }

    // MARK: - Public API

    public let items: [Item]
    public let selectedBackground: Color
    public let focusedBackground: Color
    public let focusedOverlay: Color
    public let hoveredBackground: Color
    public let spacing: CGFloat
    public let cornerRadius: CGFloat

    @Binding public var selection: ID

    public init(
        items: [Item],
        selection: Binding<ID>,
        selectedBackground: Color = Color.primary.opacity(0.10),
        focusedBackground: Color = Color.accentColor.opacity(0.12),
        focusedOverlay: Color = Color.accentColor.opacity(0.9),
        hoveredBackground: Color = Color.primary.opacity(0.06),
        spacing: CGFloat = 2,
        cornerRadius: CGFloat = 8
    ) {
        self.items = items
        self._selection = selection
        self.selectedBackground = selectedBackground
        self.focusedBackground = focusedBackground
        self.hoveredBackground = hoveredBackground
        self.focusedOverlay = focusedOverlay
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }

    // MARK: - Focus state (internal)

    /// True when the key-host NSView is firstResponder.
    @State private var isKeyHostFocused = false

    /// Focus highlight for tab navigation (our own visual focus).
    @State private var focusedTabID: ID?

    /// Show focus highlight only after keyboard interaction.
    @State private var showsKeyboardFocus = false

    /// Anchor tab used when user re-enters by Tab traversal.
    @State private var anchorTabID: ID?

    /// Trigger to clear external firstResponder (TextField, etc.).
    @State private var clearExternalFocusToken = UUID()

    public var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: spacing) {
                        ForEach(items) { item in
                            tabCell(for: item)
                                .id(item.id)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }

                TabsKeyHost(
                    isFocused: $isKeyHostFocused,
                    clearExternalFocusToken: clearExternalFocusToken,
                    onKeyboardInteraction: {
                        showsKeyboardFocus = true
                    },
                    onMove: { direction, wrapping in
                        moveFocus(direction, wrapping: wrapping)
                    },
                    onActivate: activateFocused,
                    onFocusInByTabTraversal: { direction in
                        showsKeyboardFocus = true
                        return focusOnEntry(direction)
                    },
                    onFocusOut: {
                        focusedTabID = nil
                        showsKeyboardFocus = false
                        anchorTabID = nil
                    }
                )
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .background(
                OutsideClickMonitor {
                    anchorTabID = nil
                    focusedTabID = nil
                    showsKeyboardFocus = false
                    isKeyHostFocused = false
                }
                .allowsHitTesting(false)
            )
            .onTapGesture {
                // Click on the strip (not on a tab):
                focusedTabID = nil
                anchorTabID = nil
                showsKeyboardFocus = false
                isKeyHostFocused = true
                clearExternalFocusToken = UUID()
            }
            .onAppear {
                focusedTabID = nil
                anchorTabID = nil
                showsKeyboardFocus = false
            }
            // Auto-scroll to focused tab when navigating by keyboard
            .onChange(of: focusedTabID) { _, newValue in
                guard let id = newValue else { return }
                withAnimation(.snappy(duration: 0.18)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            // Auto-scroll to selected tab (mouse click / external selection change)
            .onChange(of: selection) { _, newValue in
                withAnimation(.snappy(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }

                if isKeyHostFocused && showsKeyboardFocus {
                    focusedTabID = newValue
                    anchorTabID = newValue
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - UI

    private func tabCell(for item: Item) -> some View {
        let isSelected = item.id == selection
        let isFocused = showsKeyboardFocus && isKeyHostFocused && item.id == focusedTabID

        return TabCell(
            label: item.label,
            isEnabled: item.isEnabled,
            isSelected: isSelected,
            isFocused: isFocused,
            backgroundColor: tabBackgroundColor(isSelected:isFocused:isHovered:),
            focusedOverlay: focusedOverlay,
            cornerRadius: cornerRadius,
            onClick: {
                guard item.isEnabled else { return }

                // Mouse:
                selection = item.id
                anchorTabID = item.id

                focusedTabID = nil
                showsKeyboardFocus = false

                isKeyHostFocused = true
                clearExternalFocusToken = UUID()
            }
        )
    }

    private func tabBackgroundColor(isSelected: Bool, isFocused: Bool, isHovered: Bool) -> Color {
        if isSelected { return selectedBackground }
        if isFocused { return focusedBackground }
        if isHovered { return hoveredBackground }
        return .clear
    }

    // MARK: - Focus helpers

    private func isEnabled(_ id: ID) -> Bool {
        items.first(where: { $0.id == id })?.isEnabled == true
    }

    private func firstEnabledID() -> ID? {
        items.first(where: { $0.isEnabled })?.id
    }

    private func lastEnabledID() -> ID? {
        items.last(where: { $0.isEnabled })?.id
    }

    private func nextEnabled(after id: ID) -> ID? {
        let ids = items.map(\.id)
        guard let index = ids.firstIndex(of: id) else { return nil }
        guard index + 1 < ids.count else { return nil }

        for index in (index + 1)..<ids.count {
            let candidate = ids[index]
            if isEnabled(candidate) { return candidate }
        }
        return nil
    }

    private func previousEnabled(before id: ID) -> ID? {
        let ids = items.map(\.id)
        guard let index = ids.firstIndex(of: id) else { return nil }
        guard index - 1 >= 0 else { return nil }

        for index in stride(from: index - 1, through: 0, by: -1) {
            let candidate = ids[index]
            if isEnabled(candidate) { return candidate }
        }
        return nil
    }

    /// Enter focus into tabs ONLY via Tab traversal.
    private func focusOnEntry(_ direction: TabMoveDirection) -> Bool {
        if let anchor = anchorTabID, !isEnabled(anchor) {
            anchorTabID = nil
        }

        let targetID: ID? = {
            if let anchor = anchorTabID {
                switch direction {
                case .next:
                    return nextEnabled(after: anchor) ?? firstEnabledID()
                case .previous:
                    return previousEnabled(before: anchor) ?? lastEnabledID()
                }
            } else {
                switch direction {
                case .next: return firstEnabledID()
                case .previous: return lastEnabledID()
                }
            }
        }()

        guard let id = targetID else { return false }
        focusedTabID = id
        anchorTabID = id
        return true
    }

    // MARK: - Move / Activate

    /// wrapping=true  — cyclic (arrows)
    /// wrapping=false — no wrap (Tab/Shift+Tab to allow leaving control)
    @discardableResult
    private func moveFocus(_ direction: TabMoveDirection, wrapping: Bool) -> Bool {
        guard !items.isEmpty else { return false }

        let ids = items.map(\.id)
        let currentID = focusedTabID ?? anchorTabID ?? selection

        guard let currentIndex = ids.firstIndex(of: currentID) else {
            if let first = firstEnabledID() {
                focusedTabID = first
                anchorTabID = first
                return true
            }
            return false
        }

        if wrapping {
            func nextIndex(_ index: Int) -> Int {
                switch direction {
                case .next:
                    return (index + 1) % ids.count
                case .previous:
                    return (index - 1 + ids.count) % ids.count
                }
            }

            var newIndex = nextIndex(currentIndex)
            for _ in 0..<ids.count {
                let candidate = ids[newIndex]
                if isEnabled(candidate) {
                    focusedTabID = candidate
                    anchorTabID = candidate
                    return true
                }
                newIndex = nextIndex(newIndex)
            }
            return false
        }

        switch direction {
        case .next:
            guard currentIndex + 1 < ids.count else { return false }
            for index in (currentIndex + 1)..<ids.count {
                let candidate = ids[index]
                if isEnabled(candidate) {
                    focusedTabID = candidate
                    anchorTabID = candidate
                    return true
                }
            }
            return false

        case .previous:
            guard currentIndex - 1 >= 0 else { return false }
            for index in stride(from: currentIndex - 1, through: 0, by: -1) {
                let candidate = ids[index]
                if isEnabled(candidate) {
                    focusedTabID = candidate
                    anchorTabID = candidate
                    return true
                }
            }
            return false
        }
    }

    private func activateFocused() {
        let id = focusedTabID ?? anchorTabID ?? selection
        guard isEnabled(id) else { return }

        selection = id
        focusedTabID = id
        anchorTabID = id

        showsKeyboardFocus = true
        isKeyHostFocused = true
    }
}
