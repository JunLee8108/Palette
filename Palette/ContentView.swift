import SwiftUI

struct ContentView: View {
    @AppStorage("palette.hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var showLaunch: Bool = true

    var body: some View {
        ZStack {
            if hasCompletedOnboarding {
                TodayView()
                    .transition(.opacity)
            } else {
                OnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.opacity)
            }

            if showLaunch {
                LaunchView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLaunch = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
    }
}

#Preview("First launch") {
    ContentView()
}
