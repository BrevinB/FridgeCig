import SwiftUI

struct AppearanceSection: View {
    var body: some View {
        Section {
            AppThemePicker()
        } header: {
            Text("Appearance")
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List { AppearanceSection() }
    }
    .withPreviewEnvironment()
}
#endif
