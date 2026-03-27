
import SwiftUI

// MARK: - Background

struct PremiumBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color(white: 0.08), Color(white: 0.04)]
                    : [Color(white: 0.97), Color.white],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.04)
                          : Color.black.opacity(0.04))
                    .frame(width: 300)
                    .offset(x: geo.size.width * 0.6, y: -40)
                    .blur(radius: 50)
                Circle()
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.03)
                          : Color.black.opacity(0.03))
                    .frame(width: 220)
                    .offset(x: -40, y: geo.size.height * 0.65)
                    .blur(radius: 40)
            }
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Field Card

struct PremiumField<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let isFocused: Bool
    @ViewBuilder let content: () -> Content

    private var accentColor: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            content()
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(white: 0.14) : Color.white)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.06),
                        radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Primary Button

struct PremiumButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var isLoading: Bool = false
    let action: () -> Void

    private var fg: Color { colorScheme == .dark ? .black : .white }
    private var bg: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(fg)
                } else {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(fg)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: bg.opacity(0.25), radius: 14, x: 0, y: 6)
        }
        .disabled(isLoading)
    }
}

// MARK: - Outline Button

struct PremiumOutlineButton: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    private var color: Color {
        isDestructive ? .red : (colorScheme == .dark ? .white : .black)
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(color.opacity(0.3), lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Section Card

struct PremiumCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05),
                            radius: 12, x: 0, y: 3)
            )
    }
}

// MARK: - Section Label

struct PremiumSectionLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(1.2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Delete Confirmation Overlay

struct DeleteConfirmationOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(LocalizationManager.self) private var loc
    let title: String
    let message: String
    var isLoading: Bool = false
    let onDelete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { if !isLoading { onCancel() } }

            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 68, height: 68)
                    Image(systemName: "trash")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.primary)
                }

                // Texts
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button(action: onDelete) {
                        ZStack {
                            if isLoading {
                                ProgressView().tint(Color.adaptiveFg(colorScheme))
                            } else {
                                Text(loc.t("common.delete"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.adaptiveFg(colorScheme))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.adaptiveBg(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: Color.adaptiveBg(colorScheme).opacity(0.25), radius: 14, y: 6)
                    }
                    .disabled(isLoading)

                    Button(action: onCancel) {
                        Text(loc.t("common.cancel"))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(colorScheme == .dark ? Color(white: 0.13) : Color.white)
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 30, y: 10)
            )
            .padding(.horizontal, 28)
        }
    }
}

// MARK: - Helpers

extension Color {
    static func adaptiveFg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .black : .white
    }
    static func adaptiveBg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? .white : .black
    }
}
