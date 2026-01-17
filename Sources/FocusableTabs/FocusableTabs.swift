import SwiftUI
import AppKit

public struct FocusableTabs<ID: Hashable, Label: View>: View {

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

    public let items: [Item]
    public let selectedBackground: Color
    public let focusedBackground: Color
    public let focusedOverlay: Color
    public let focusedOverlayLineWidth: CGFloat
    public let overlayColor: Color
    public let overlayLineWidth: CGFloat
    public let hoveredBackground: Color
    public let spacing: CGFloat
    public let cornerRadius: CGFloat
    public let layout: FocusableTabsLayout

    @Binding public var selection: ID

    public init(
        items: [Item],
        selection: Binding<ID>,
        selectedBackground: Color = Color.primary.opacity(0.10),
        focusedBackground: Color = Color.accentColor.opacity(0.12),
        focusedOverlay: Color = Color.accentColor.opacity(0.9),
        focusedOverlayLineWidth: CGFloat = 1.5,
        overlayColor: Color = .clear,
        overlayLineWidth: CGFloat = 1 / 3,
        hoveredBackground: Color = Color.primary.opacity(0.06),
        spacing: CGFloat = 2,
        cornerRadius: CGFloat = 8,
        layout: FocusableTabsLayout = .scroll(horizontalOffset: nil)
    ) {
        self.items = items
        self._selection = selection
        self.selectedBackground = selectedBackground
        self.focusedBackground = focusedBackground
        self.hoveredBackground = hoveredBackground
        self.focusedOverlay = focusedOverlay
        self.focusedOverlayLineWidth = focusedOverlayLineWidth
        self.overlayColor = overlayColor
        self.overlayLineWidth = overlayLineWidth
        self.spacing = spacing
        self.cornerRadius = cornerRadius
        self.layout = layout
    }

    @State private var isKeyHostFocused = false

    @State private var focusedTabID: ID?

    @State private var showsKeyboardFocus = false

    @State private var anchorTabID: ID?

    @State private var clearExternalFocusToken = UUID()

    public var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                switch layout {
                case .scroll(let horizontalOffset):
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: spacing) {
                            ForEach(items) { item in
                                tabCell(for: item)
                                    .id(item.id)
                            }
                        }
                        .padding(.horizontal, horizontalOffset)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                case .wrap(let alignment):
                    WrapLayout(spacing: spacing, alignment: alignment) {
                        ForEach(items) { item in
                            tabCell(for: item)
                                .id(item.id)
                        }
                    }
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
            .onChange(of: focusedTabID) { _, newValue in
                guard let id = newValue else { return }
                withAnimation(.snappy(duration: 0.18)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
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
            focusedOverlayLineWidth: focusedOverlayLineWidth,
            overlayColor: overlayColor,
            overlayLineWidth: overlayLineWidth,
            cornerRadius: cornerRadius,
            onClick: {
                guard item.isEnabled else { return }

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

    private func focusOnEntry(_ direction: TabMoveDirection) -> Bool {
        if isEnabled(selection) {
            focusedTabID = selection
            anchorTabID = selection
            return true
        }

        let fallback: ID? = {
            switch direction {
            case .next: return firstEnabledID()
            case .previous: return lastEnabledID()
            }
        }()

        guard let id = fallback else { return false }
        focusedTabID = id
        anchorTabID = id
        return true
    }


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
