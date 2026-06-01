// EmberColors.swift
import SwiftUI

struct EmberColors {
    private static var currentTheme: EmberTheme { EmberPreferences.currentTheme }

    // MARK: - Studio Shell
    static var studioBackground: Color {
        EmberPreferences.oledBlackEnabled ? Color(hex: "000000") : Color(hex: "070707")
    }
    static var oledBackground: Color { Color(hex: "000000") }

    // MARK: - Backgrounds
    static var background: Color { studioBackground }
    static var recessedSurface: Color { Color(hex: "0D0D0F") }
    static var backgroundElevated: Color { Color(hex: "121212") }

    // MARK: - Card Surfaces
    static var primaryPanel: Color { Color(hex: "121212") }
    static var nestedRow: Color { Color(hex: "1A1A1A") }
    static var raisedElement: Color { Color(hex: "242424") }
    static var cardSurface: Color { primaryPanel }
    static var cardSurfaceHover: Color { raisedElement }

    // MARK: - Glass
    static var glassStroke: Color { Color(hex: "F5F0E8").opacity(0.08) }
    static var glassHighlight: Color { Color(hex: "F5F0E8").opacity(0.04) }

    // MARK: - Text
    static var textPrimary: Color { Color(hex: "F5F0E8") }
    static var textSecondary: Color { Color(hex: "8A8680") }
    static var textTertiary: Color { Color(hex: "5A5650") }
    static var textDone: Color { textTertiary }

    // MARK: - Accent
    static var accent: Color { currentTheme.accent }
    static var accentLight: Color { currentTheme.accent.opacity(0.82) }
    static var accentDark: Color { currentTheme.accentPressed }
    static var accentSubtle: Color { currentTheme.accentSubtle }
    static var slotOneAccent: Color { currentTheme.accent }

    // MARK: - Primary Accent
    static var ember: Color { currentTheme.accent }
    static var emberBright: Color { Color(hex: "FF7A1A") }
    static var emberGlow: Color { currentTheme.accent.opacity(0.18) }

    // MARK: - Status
    static var success: Color { Color(hex: "4CAF50") }
    static var risk: Color { Color(hex: "FF4D2E") }
    static var analytics: Color { Color(hex: "3FD6FF") }

    // MARK: - Optional Contrast Surfaces
    static var lightPanel: Color { Color(hex: "F7F7F5") }
    static var softLightPanel: Color { Color(hex: "EFEFEC") }
    static var textOnLight: Color { Color(hex: "080808") }
    static var mutedTextOnLight: Color { Color(hex: "8C8C8C") }

    // MARK: - Utility
    static var divider: Color { Color(hex: "F5F0E8").opacity(0.08) }
    static var shimmer: Color { Color(hex: "F5F0E8").opacity(0.10) }
}
