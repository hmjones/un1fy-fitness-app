import SwiftUI

struct ContentView: View {
    let store: MemberStore
    @Binding var appearanceMode: AppearanceMode
    @State private var selectedTab: AppTab = .home
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                appNavigation {
                    HomeView(store: store, onOpenCommunity: { selectedTab = .community })
                }
            }
            Tab("Progress", systemImage: "chart.bar", value: AppTab.progress) {
                appNavigation { StatsView(store: store) }
            }
            Tab("Community", systemImage: "person.2", value: AppTab.community) {
                appNavigation { CommunityView(store: store) }
            }
            Tab("You", systemImage: "person.crop.circle", value: AppTab.profile) {
                appNavigation { ProfileView(store: store, appearanceMode: $appearanceMode) }
            }
        }
        .tint(Theme.cream)
        .onAppear { configureTabBarAppearance() }
        .onChange(of: colorScheme) { _, _ in configureTabBarAppearance() }
        .task { await store.refreshData() }
    }

    private func appNavigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) { HeaderWordmark() }
                        .un1fyHeaderBackground()
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { selectedTab = .profile } label: {
                            AvatarView(
                                clientId: AvatarStore.shared.ownClientId,
                                initials: profileInitials,
                                size: 36
                            )
                        }
                        .accessibilityLabel("Your profile")
                    }
                    .un1fyHeaderBackground()
                }
                .toolbarBackground(Theme.background, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.cardBackground)
        appearance.shadowColor = UIColor(Theme.subtleDivider)
        for layout in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            layout.normal.iconColor = UIColor(Theme.creamSecondary)
            layout.normal.titleTextAttributes = [.foregroundColor: UIColor(Theme.creamSecondary)]
            layout.selected.iconColor = UIColor(Theme.cream)
            layout.selected.titleTextAttributes = [.foregroundColor: UIColor(Theme.cream)]
        }
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private var profileInitials: String {
        let initials = "\(store.profile.firstName.prefix(1))\(store.profile.lastName.prefix(1))"
        return initials.isEmpty ? "U" : initials.uppercased()
    }
}

private extension ToolbarContent {
    @ToolbarContentBuilder
    func un1fyHeaderBackground() -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            self.sharedBackgroundVisibility(.hidden)
        } else {
            self
        }
    }
}

enum AppTab: Hashable {
    case home, progress, community, profile
}

struct HeaderWordmark: View {
    var body: some View {
        Image("UN1FYWordmark")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 24)
            .foregroundStyle(Theme.cream)
            .accessibilityLabel("UN1FY")
    }
}
