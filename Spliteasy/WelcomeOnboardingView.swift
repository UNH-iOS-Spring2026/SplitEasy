//
//  WelcomeOnboardingView.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 4/5/26.
//

import SwiftUI

struct WelcomeOnboardingView: View {
    let onGetStarted: () -> Void
    let onLogin: () -> Void
    let onSkip: () -> Void

    @State private var currentPage = 0

    private let pages: [OnboardingPageItem] = [
        OnboardingPageItem(
            imageName: "welcome1",
            title: "Bills Made Simple",
            subtitle: "Add expenses, split fairly, and settle up in seconds."
        ),
        OnboardingPageItem(
            imageName: "welcome2",
            title: "No More Awkward Money Talks",
            subtitle: "Keep everything clear, fair, and hassle-free with friends and groups."
        ),
        OnboardingPageItem(
            imageName: "welcome3",
            title: "Split Smartly",
            subtitle: "Know exactly who pays what with a clean and friendly experience."
        )
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppPalette.backgroundTop,
                    AppPalette.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Spacer(minLength: 10)

                onboardingPager
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                pageIndicator
                    .padding(.top, 16)

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                if currentPage == pages.count - 1 {
                    loginRow
                        .padding(.top, 18)
                } else {
                    Spacer()
                        .frame(height: 26)
                        .padding(.top, 18)
                }

                Spacer(minLength: 22)
            }
        }
    }

    @ViewBuilder
    private var onboardingPager: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                onboardingPage(page)
                    .tag(index)
            }
        }
        #if os(iOS)
        .tabViewStyle(.page(indexDisplayMode: .never))
        #endif
    }

    private var topBar: some View {
        HStack {
            Spacer()

            Button {
                onSkip()
            } label: {
                Text("Skip")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.88))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func onboardingPage(_ page: OnboardingPageItem) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 4)

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.04),
                                Color.white.opacity(0.01)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 26, x: 0, y: 14)

                Image(page.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.08),
                                Color.black.opacity(0.18),
                                Color.black.opacity(0.62)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    )

                VStack(alignment: .leading, spacing: 10) {
                    Text(page.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(page.subtitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.82))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.trailing, 18)
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppPalette.accentMid : Color.white.opacity(0.12))
                    .frame(width: index == currentPage ? 26 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private var bottomButton: some View {
        Button {
            if currentPage < pages.count - 1 {
                withAnimation(.easeInOut(duration: 0.25)) {
                    currentPage += 1
                }
            } else {
                onGetStarted()
            }
        } label: {
            Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [AppPalette.accentStart, AppPalette.accentEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: AppPalette.accentMid.opacity(0.22), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var loginRow: some View {
        HStack(spacing: 6) {
            Text("Already have an account?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppPalette.secondaryText)

            Button {
                onLogin()
            } label: {
                Text("Log In")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
            }
            .buttonStyle(.plain)
        }
    }
}

private struct OnboardingPageItem {
    let imageName: String
    let title: String
    let subtitle: String
}
