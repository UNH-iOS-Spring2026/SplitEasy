//
//  CurvedAppHeader.swift
//  Spliteasy
//

import SwiftUI

struct PremiumHeaderShape: Shape {
    var cornerRadius: CGFloat = 34

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let tl: CGFloat = 0
        let tr: CGFloat = 0
        let bl: CGFloat = cornerRadius
        let br: CGFloat = cornerRadius

        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + tr))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - br, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bl),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addLine(to: CGPoint(x: rect.minX + tl, y: rect.minY))

        return path
    }
}

struct CurvedAppHeader<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let height: CGFloat
    let trailing: Trailing

    init(
        title: String,
        subtitle: String? = nil,
        height: CGFloat = 118,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.height = height
        self.trailing = trailing()
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(
                colors: [
                    AppPalette.accentStart,
                    AppPalette.accentEnd
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.12),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)

                        if let subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.90))
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 10)

                    trailing
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
            }
        }
        .frame(height: height)
        .clipShape(PremiumHeaderShape(cornerRadius: 34))
        .shadow(color: AppPalette.accentMid.opacity(0.14), radius: 10, x: 0, y: 6)
    }
}

struct FixedHeaderScrollContainer<Header: View, Content: View>: View {
    let headerHeight: CGFloat
    let onRefresh: (() async -> Void)?
    let header: () -> Header
    let content: () -> Content

    init(
        headerHeight: CGFloat = 118,
        onRefresh: (() async -> Void)? = nil,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.headerHeight = headerHeight
        self.onRefresh = onRefresh
        self.header = header
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [AppPalette.backgroundTop, AppPalette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            header()
                .frame(height: headerHeight)
                .ignoresSafeArea(edges: .top)
                .zIndex(2)

            scrollLayer
                .padding(.top, headerHeight - 58)
                .zIndex(1)
        }
    }

    @ViewBuilder
    private var scrollLayer: some View {
        if let onRefresh {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    content()
                        .padding(.bottom, 140)
                }
            }
            .refreshable {
                await onRefresh()
            }
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    content()
                        .padding(.bottom, 140)
                }
            }
        }
    }
}
