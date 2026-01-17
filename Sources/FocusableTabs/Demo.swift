import SwiftUI

enum DemoTab1: String, CaseIterable, Hashable {
    case params, headers, auth, body
}

enum DemoTab2: String, CaseIterable, Hashable {
    case params, headers, auth, body
}

struct DemoView: View {
    @State private var selection1: DemoTab1 = .params
    @State private var selection2: DemoTab2 = .params

    var body: some View {
        VStack(spacing: 16, content: {
            FocusableTabs(
                items: DemoTab1.allCases.map { tab in
                    .init(tab) {
                        Text(tab.rawValue)
                            .font(.body)
                            .foregroundStyle(selection1 == tab ? .primary : .secondary)
                    }
                },
                selection: $selection1
            )
            FocusableTabs(
                items: DemoTab2.allCases.map { tab in
                    .init(tab) {
                        Text(tab.rawValue)
                            .font(.body)
                            .foregroundStyle(selection2 == tab ? .primary : .secondary)
                    }
                },
                selection: $selection2
            )
        })
        .padding()
    }
}

#Preview {
    DemoView()
}
