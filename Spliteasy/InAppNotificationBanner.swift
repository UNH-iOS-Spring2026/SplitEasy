//
//  InAppNotificationBanner.swift
//  Spliteasy
//
//  Created by SIDHARTHA JAVVADI on 4/14/26.
//

import SwiftUI
import Combine

final class InAppNotificationManager: ObservableObject {
    static let shared = InAppNotificationManager()

    @Published var currentBanner: InAppBannerItem?

    private var dismissWorkItem: DispatchWorkItem?
    private var queue: [InAppBannerItem] = []
    private var isShowing = false
    private var currentDuration: TimeInterval = 3.0

    private init() {}

    func show(
        title: String,
        message: String,
        systemImage: String = "bell.fill",
        duration: TimeInterval = 3.0
    ) {
        let item = InAppBannerItem(
            title: title,
            message: message,
            systemImage: systemImage,
            timeText: "Now"
        )

        DispatchQueue.main.async {
            self.queue.append(item)
            self.currentDuration = duration
            self.showNextIfNeeded()
        }
    }

    private func showNextIfNeeded() {
        guard !isShowing, !queue.isEmpty else { return }

        isShowing = true
        let next = queue.removeFirst()

        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        currentBanner = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                self.currentBanner = next
            }

            let workItem = DispatchWorkItem { [weak self] in
                self?.hideAndContinue()
            }

            self.dismissWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + self.currentDuration, execute: workItem)
        }
    }

    func hide() {
        DispatchQueue.main.async {
            self.dismissWorkItem?.cancel()
            self.dismissWorkItem = nil

            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                self.currentBanner = nil
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                self.isShowing = false
                self.showNextIfNeeded()
            }
        }
    }

    private func hideAndContinue() {
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
                self.currentBanner = nil
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                self.isShowing = false
                self.showNextIfNeeded()
            }
        }
    }
}

struct InAppBannerItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let systemImage: String
    let timeText: String
}

struct InAppNotificationOverlay: View {
    @ObservedObject private var manager = InAppNotificationManager.shared
    let onTap: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                if let banner = manager.currentBanner {
                    Button {
                        onTap?()
                        manager.hide()
                    } label: {
                        InAppNotificationCard(item: banner) {
                            manager.hide()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, geo.safeAreaInsets.top + 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: manager.currentBanner)
        }
    }
}

struct InAppNotificationCard: View {
    let item: InAppBannerItem
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppPalette.accentMid.opacity(0.16))
                    .frame(width: 46, height: 46)

                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppPalette.primaryText)
                    .lineLimit(1)

                Text(item.message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppPalette.secondaryText)
                    .lineLimit(2)

                Text(item.timeText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppPalette.accentMid)
            }

            Spacer(minLength: 8)

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppPalette.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(AppPalette.card.opacity(0.85))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AppPalette.border, lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 8)
        )
    }
}
