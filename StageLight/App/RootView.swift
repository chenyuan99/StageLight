import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var skipsOnboarding: Bool {
        ProcessInfo.processInfo.arguments.contains("-skip-onboarding")
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding || skipsOnboarding {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasCompletedOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .background(StageTheme.background.ignoresSafeArea())
    }
}
