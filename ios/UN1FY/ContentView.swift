import SwiftUI

struct ContentView: View {
    let store: MemberStore
    @Binding var appearanceMode: AppearanceMode
    @State private var selectedTab: AppTab = .home
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", image: "TabHome", value: .home) {
                NavigationStack {
                    HomeView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }

            Tab("You", image: "TabYou", value: .stats) {
                NavigationStack {
                    StatsView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }

            Tab("Ranks", image: "TabRanks", value: .leaderboard) {
                NavigationStack {
                    LeaderboardView(memberStore: store)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }

            Tab("Badges", image: "TabBadges", value: .achievements) {
                NavigationStack {
                    AchievementsView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }

            Tab("Challenges", image: "TabChallenges", value: .challenges) {
                NavigationStack {
                    ChallengesView(store: store)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }

            Tab("Profile", image: "TabProfile", value: .profile) {
                NavigationStack {
                    ProfileView(store: store, appearanceMode: $appearanceMode)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                HeaderWordmark()
                            }
                        }
                        .toolbarBackground(Theme.background, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                }
            }
        }
        .tint(Theme.cream)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: colorScheme) { _, _ in
            configureTabBarAppearance()
        }
        .task {
            await store.refreshData()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.background)
        appearance.shadowColor = UIColor(Theme.subtleDivider)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Theme.creamTertiary)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Theme.cream)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.creamTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.cream)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

enum AppTab: Hashable {
    case home, stats, leaderboard, achievements, challenges, profile
}

struct HeaderWordmark: View {
    var body: some View {
        Image("UN1FYWordmark")
            .resizable()
            .scaledToFit()
            .frame(height: 15)
            .foregroundStyle(Theme.cream)
            .accessibilityLabel("UN1FY")
    }
}
