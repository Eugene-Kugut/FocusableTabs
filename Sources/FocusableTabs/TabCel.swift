import SwiftUI

struct TabCell<Label: View>: View {
    let label: () -> Label

    let isEnabled: Bool
    let isSelected: Bool
    let isFocused: Bool

    let selectedBackground: Color
    let focusedBackground: Color
    let hoveredBackground: Color

//    let backgroundColor: (_ isSelected: Bool, _ isFocused: Bool, _ isHovered: Bool) -> Color
    let focusedOverlay: Color
    let focusedOverlayLineWidth: CGFloat
    let selectedOverlayColor: Color
    let overlayColor: Color
    let overlayLineWidth: CGFloat
    let cornerRadius: CGFloat
    let onClick: () -> Void

    @State private var isHovered = false

    var body: some View {
        label()
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
//            .background {
//                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                    .fill(backgroundColor(isSelected, isFocused, isHovered))
//            }
//            .overlay {
//                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                    .strokeBorder(
//                        isFocused ? focusedOverlay : (isSelected ? selectedOverlayColor : overlayColor),
//                        lineWidth: isFocused ? focusedOverlayLineWidth : overlayLineWidth
//                    )
//            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isFocused ? focusedBackground : .clear)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? hoveredBackground : .clear)
            }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isSelected ? selectedBackground : .clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? focusedOverlay : (isSelected ? selectedOverlayColor : overlayColor),
                        lineWidth: isFocused ? focusedOverlayLineWidth : overlayLineWidth
                    )
            }
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.45)
            .onTapGesture {
                guard isEnabled else { return }
                onClick()
            }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
    }
}
