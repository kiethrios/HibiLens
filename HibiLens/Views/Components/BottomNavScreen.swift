import SwiftData
import SwiftUI

struct BottomNavScreen<Content: View>: View {
    private let theme = AppTheme()

    @Binding var activeDestination: NavDestination
    let onSelect: (NavDestination) -> Void
    @ViewBuilder let content: Content

    init(
        activeDestination: Binding<NavDestination>,
        onSelect: @escaping (NavDestination) -> Void,
        @ViewBuilder content: () -> Content
    ) {
        _activeDestination = activeDestination
        self.onSelect = onSelect
        self.content = content()
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            content
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomNavBar(activeDestination: $activeDestination, onSelect: onSelect)
        }
    }
}

#Preview {
    @Previewable @State var activeDestination: NavDestination = .home

    BottomNavScreen(activeDestination: $activeDestination, onSelect: { destination in
        activeDestination = destination
    }) {
        HomeView(onCapture: { }, onSeeAll: { activeDestination = .review })
    }
    .modelContainer(PreviewModelContainer.shared)
}
