# FocusableTabs

Keyboard-focusable flat tabs for **macOS SwiftUI**.

- Works with Tab / Shift+Tab
- Supports Left/Right arrows
- Space / Return activates the focused tab
- If tabs overflow, they scroll automatically to keep focused/selected tab visible
- Mouse click selects a tab but does not “force” keyboard focus highlight
- Can clear focus from external controls (e.g. `TextField`) when you click tabs/strip

![selected](screenshots/selected.png)

![focused](screenshots/focused.png)

![hovered](screenshots/hovered.png)

## Installation (Swift Package Manager)

Add package in Xcode:

File → Add Packages Dependencies… → https://github.com/Eugene-Kugut/FocusableTabs.git

# Usage

```swift
import SwiftUI
import FocusableTabs

enum DemoTab: String, CaseIterable, Hashable {
    case params, headers, auth, body
}

struct DemoView: View {
    @State private var selection: DemoTab = .params

    var body: some View {
        FocusableTabs(
            items: DemoTab.allCases.map { tab in
                .init(tab) {
                    Text(tab.rawValue)
                        .font(.body)
                        .foregroundStyle(selection == tab ? .primary : .secondary)
                }
            },
            selection: $selection
        )
    }
}
