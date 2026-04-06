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
            title: "Split expenses\neasily",
            subtitle: "Track shared expenses with friends, roommates, and groups effortlessly.",
            illustration: .peopleAndBills
        ),
        OnboardingPageItem(
            title: "No awkward money\nconversations",
            subtitle: "Always know who owes what. Everything is calculated automatically.",
            illustration: .chatAndBalances
        ),
        OnboardingPageItem(
            title: "Settle up in seconds",
            subtitle: "Record payments via cash or transfer and keep your balances clear.",
            illustration: .walletAndMoney
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                Spacer(minLength: 8)

                onboardingPager

                pageIndicator
                    .padding(.top, 18)

                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

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
                    .foregroundColor(AppPalette.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(AppPalette.card)
                            .overlay(
                                Capsule()
                                    .stroke(AppPalette.border, lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func onboardingPage(_ page: OnboardingPageItem) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 10)

            VStack(spacing: 0) {
                Text(page.title)
                    .font(.system(size: 30, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppPalette.primaryText)
                    .padding(.horizontal, 28)

                Text(page.subtitle)
                    .font(.system(size: 17, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppPalette.secondaryText)
                    .lineSpacing(4)
                    .padding(.horizontal, 30)
                    .padding(.top, 16)
            }

            page.illustration.view
                .padding(.horizontal, 24)
                .padding(.top, 30)

            Spacer()
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? AppPalette.accentMid : AppPalette.border)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
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
                .font(.system(size: 19, weight: .bold))
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
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: AppPalette.accentMid.opacity(0.20), radius: 10, x: 0, y: 5)
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
    let title: String
    let subtitle: String
    let illustration: OnboardingIllustration
}

private enum OnboardingIllustration {
    case peopleAndBills
    case chatAndBalances
    case walletAndMoney

    @ViewBuilder
    var view: some View {
        switch self {
        case .peopleAndBills:
            PeopleBillsIllustration()
        case .chatAndBalances:
            ChatBalancesIllustration()
        case .walletAndMoney:
            WalletMoneyIllustration()
        }
    }
}

private struct IllustrationContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)

            content
                .padding(.horizontal, 18)
                .padding(.vertical, 24)
        }
        .frame(height: 330)
    }
}

private struct PeopleBillsIllustration: View {
    var body: some View {
        IllustrationContainer {
            ZStack {
                Circle()
                    .fill(AppPalette.accentMid.opacity(0.08))
                    .frame(width: 210, height: 210)
                    .offset(y: 26)

                floatingPaper(
                    x: -88,
                    y: -68,
                    rotation: -14,
                    icon: "dollarsign",
                    tint: AppPalette.accentStart
                )

                floatingPaper(
                    x: 0,
                    y: -86,
                    rotation: 8,
                    icon: "list.bullet.clipboard",
                    tint: .green
                )

                floatingPaper(
                    x: 92,
                    y: -58,
                    rotation: 12,
                    icon: "creditcard.fill",
                    tint: AppPalette.accentEnd
                )

                HStack(spacing: 22) {
                    person(
                        circleColor: AppPalette.accentMid,
                        cardColor: AppPalette.accentMid,
                        accessory: "cup.and.saucer.fill"
                    )

                    person(
                        circleColor: .orange,
                        cardColor: .orange,
                        accessory: "calculator"
                    )
                }
                .offset(y: 34)
            }
        }
    }

    private func floatingPaper(
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        icon: String,
        tint: Color
    ) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppPalette.softCard)
            .frame(width: 72, height: 56)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(tint)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppPalette.border, lineWidth: 1)
            )
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }

    private func person(
        circleColor: Color,
        cardColor: Color,
        accessory: String
    ) -> some View {
        VStack(spacing: 10) {
            Circle()
                .fill(circleColor.opacity(0.18))
                .frame(width: 76, height: 76)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(circleColor)
                )

            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardColor.opacity(0.14))
                .frame(width: 96, height: 66)
                .overlay(
                    Image(systemName: accessory)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(cardColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
        }
    }
}

private struct ChatBalancesIllustration: View {
    var body: some View {
        IllustrationContainer {
            ZStack {
                HStack(spacing: 22) {
                    Circle()
                        .fill(AppPalette.accentStart.opacity(0.18))
                        .frame(width: 82, height: 82)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppPalette.accentStart)
                        )

                    Circle()
                        .fill(.orange.opacity(0.18))
                        .frame(width: 82, height: 82)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.orange)
                        )
                }
                .offset(y: 42)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppPalette.card)
                    .frame(width: 200, height: 166)
                    .overlay(
                        VStack(spacing: 10) {
                            balanceRow(name: "Andrew", amount: "$28.76")
                            balanceRow(name: "Sarah", amount: "$22.55")
                            balanceRow(name: "You owe", amount: "$91.25")
                        }
                        .padding(.horizontal, 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppPalette.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
                    .offset(y: -10)
            }
        }
    }

    private func balanceRow(name: String, amount: String) -> some View {
        HStack {
            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppPalette.primaryText)

            Spacer()

            Text(amount)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppPalette.secondaryText)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppPalette.softCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
        )
    }
}

private struct WalletMoneyIllustration: View {
    var body: some View {
        IllustrationContainer {
            ZStack {
                Circle()
                    .fill(.green.opacity(0.16))
                    .frame(width: 62, height: 62)
                    .overlay(
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.green)
                    )
                    .offset(x: 100, y: -18)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.orange.opacity(0.18))
                    .frame(width: 124, height: 70)
                    .rotationEffect(.degrees(-12))
                    .offset(x: 42, y: -50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppPalette.border, lineWidth: 1)
                            .rotationEffect(.degrees(-12))
                            .offset(x: 42, y: -50)
                    )

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppPalette.accentStart.opacity(0.85), AppPalette.accentEnd.opacity(0.95)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 190, height: 122)
                    .overlay(
                        HStack {
                            Spacer()

                            Circle()
                                .fill(Color.white.opacity(0.38))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle()
                                        .fill(Color.white.opacity(0.72))
                                        .frame(width: 14, height: 14)
                                )
                                .padding(.trailing, 22)
                        }
                    )
                    .shadow(color: AppPalette.accentMid.opacity(0.12), radius: 8, x: 0, y: 4)

                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
                    .offset(x: -92, y: 10)
            }
        }
    }
}
