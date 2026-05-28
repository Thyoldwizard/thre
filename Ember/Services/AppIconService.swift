import SwiftUI
import UIKit

struct AppIconService {
    enum Icon: String, CaseIterable, Identifiable {
        case primary
        case black = "Black"
        case minimal = "Minimal"
        case magma = "Magma"

        var id: String { rawValue }

        var iconName: String? {
            switch self {
            case .primary:
                return nil
            case .black, .minimal, .magma:
                return rawValue
            }
        }

        var title: String {
            switch self {
            case .primary:
                return "Default"
            case .black:
                return "Black"
            case .minimal:
                return "Minimal"
            case .magma:
                return "Magma"
            }
        }

        var subtitle: String {
            switch self {
            case .primary:
                return "Studio ember"
            case .black:
                return "All-black mark"
            case .minimal:
                return "Bright ember dot"
            case .magma:
                return "Deep red ember"
            }
        }

        var backgroundTop: Color {
            switch self {
            case .primary:
                return Color(hex: "161616")
            case .black:
                return Color(hex: "111111")
            case .minimal:
                return Color(hex: "121212")
            case .magma:
                return Color(hex: "120908")
            }
        }

        var backgroundBottom: Color {
            switch self {
            case .primary:
                return Color(hex: "050505")
            case .black:
                return Color(hex: "020202")
            case .minimal:
                return Color(hex: "040404")
            case .magma:
                return Color(hex: "030303")
            }
        }

        var coreInner: Color {
            switch self {
            case .primary:
                return Color(hex: "FF7D28")
            case .black:
                return Color(hex: "1A1A1A")
            case .minimal:
                return Color(hex: "FF8E3A")
            case .magma:
                return Color(hex: "D04A2B")
            }
        }

        var coreOuter: Color {
            switch self {
            case .primary:
                return Color(hex: "FF5A00")
            case .black:
                return Color(hex: "050505")
            case .minimal:
                return Color(hex: "FF5A00")
            case .magma:
                return Color(hex: "6B180D")
            }
        }

        var ringColor: Color {
            switch self {
            case .primary:
                return Color.white.opacity(0.16)
            case .black:
                return Color.white.opacity(0.09)
            case .minimal:
                return Color(hex: "FFD6B8").opacity(0.16)
            case .magma:
                return Color(hex: "FFB39B").opacity(0.14)
            }
        }

        var glowColor: Color {
            switch self {
            case .primary:
                return Color(hex: "FF6A00").opacity(0.26)
            case .black:
                return Color.black.opacity(0.34)
            case .minimal:
                return Color(hex: "FF6A00").opacity(0.24)
            case .magma:
                return Color(hex: "7C1D10").opacity(0.30)
            }
        }
    }

    enum AppIconError: LocalizedError {
        case unsupported

        var errorDescription: String? {
            switch self {
            case .unsupported:
                return "Alternate app icons are not available on this device."
            }
        }
    }

    @MainActor
    static var supportsAlternateIcons: Bool {
        UIApplication.shared.supportsAlternateIcons
    }

    @MainActor
    static func currentIcon() -> Icon {
        guard let name = UIApplication.shared.alternateIconName else {
            return .primary
        }

        return Icon(rawValue: name) ?? .primary
    }

    @MainActor
    static func setIcon(_ icon: Icon) async throws {
        guard supportsAlternateIcons || icon == .primary else {
            throw AppIconError.unsupported
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            UIApplication.shared.setAlternateIconName(icon.iconName) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
