import SwiftUI

struct OnboardingView: View {
    let completion: () -> Void
    @State private var page = 0

    private let pages = [
        OnboardingPage(
            title: "Your life on stage.",
            message: "A private home for every performance you've seen.",
            symbol: "sparkles.rectangle.stack"
        ),
        OnboardingPage(
            title: "Scan your Playbill",
            message: "Start with a Playbill, ticket, poster, or a photo you already love.",
            symbol: "viewfinder"
        ),
        OnboardingPage(
            title: "Permissions",
            message: "Camera and photo access are requested only when you choose to use them.",
            symbol: "lock.shield"
        )
    ]

    var body: some View {
        VStack(spacing: 24) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 28) {
                        Spacer()
                        Image(systemName: item.symbol)
                            .font(.system(size: 64, weight: .ultraLight))
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 160, height: 160)
                            .background(
                                RadialGradient(
                                    colors: [StageTheme.spotlight.opacity(0.7), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .accessibilityHidden(true)

                        VStack(spacing: 12) {
                            Text(item.title)
                                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                                .multilineTextAlignment(.center)
                            Text(item.message)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                        }
                        Spacer()
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == pages.count - 1 ? "Enter StageLight" : "Continue") {
                if page == pages.count - 1 {
                    completion()
                } else {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        page += 1
                    }
                }
            }
            .buttonStyle(StagePrimaryButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(StageTheme.background.ignoresSafeArea())
    }
}

private struct OnboardingPage {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let symbol: String
}
