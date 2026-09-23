import SwiftUI

@main
struct UN1FYApp: App {
    private static let DEV_SKIP_ONBOARDING = true

    @State private var hasCompletedOnboarding: Bool = {
        if UN1FYApp.DEV_SKIP_ONBOARDING { return true }
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }()
    @State private var store = MemberStore()
    @State private var appearanceMode: AppearanceMode = {
        let raw = UserDefaults.standard.integer(forKey: "appearanceMode")
        return AppearanceMode(rawValue: raw) ?? .dark
    }()
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                rootContent

                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(1.6))
                withAnimation(.easeInOut(duration: 0.45)) {
                    isShowingSplash = false
                }
            }
        }
    }

    @ViewBuilder
    private var rootContent: some View {
        Group {
            if hasCompletedOnboarding {
                ContentView(store: store, appearanceMode: $appearanceMode)
                    .preferredColorScheme(appearanceMode.colorScheme)
            } else {
                OnboardingView(store: store) {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                }
                .preferredColorScheme(appearanceMode.colorScheme)
            }
        }
    }
}
