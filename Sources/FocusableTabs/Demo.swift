import SwiftUI

enum DemoTab: String, CaseIterable, Hashable {
    case params = "Params"
    case headers = "Headers"
    case auth = "Auth"
    case body = "Body"
}

enum Languages: String, CaseIterable, Hashable {
    case swift = "Swift"
    case kotlin = "Kotlin"
    case cpp = "C++"
    case phyton = "Phyton"
    case php = "PHP"
    case pascal = "Pascal"
    case js = "Java Script"
    case java = "Java"
    case asm = "Assembler"
    case basic = "Basic"
}

struct DemoView: View {
    @State private var selection: DemoTab = .params
    @State private var selectionLanguage: Languages = .kotlin

    var body: some View {
        VStack(content: {
            FocusableTabs(
                items: DemoTab.allCases.map { tab in
                    .init(tab) {
                        Text(tab.rawValue)
                            .font(.body)
                            .foregroundStyle(selection == tab ? .white : .secondary)
                    }
                },
                selection: $selection,
                selectedBackground: .indigo,
                focusedBackground: Color.accentColor.opacity(0.2),
                hoveredBackground: Color(NSColor.secondarySystemFill).opacity(0.8),
                selectedOverlayColor: .primary.opacity(0.2),
                overlayColor: .primary.opacity(0.1),
                overlayLineWidth: 1,
                spacing: 6
            )
            FocusableTabs(
                items: Languages.allCases.map { tab in
                    .init(tab) {
                        Text(tab.rawValue)
                            .font(.body)
                            .foregroundStyle(selectionLanguage == tab ? .white : .secondary)
                    }
                },
                selection: $selectionLanguage,
                selectedBackground: .indigo,
                focusedBackground: Color.accentColor.opacity(0.2),
                hoveredBackground: Color(NSColor.secondarySystemFill).opacity(0.8),
                selectedOverlayColor: .primary.opacity(0.2),
                overlayColor: .primary.opacity(0.1),
                overlayLineWidth: 1,
                spacing: 6
            )
        })
        .padding(.vertical)
    }
}

#Preview {
    DemoView()
}
