import SwiftUI
import UIKit

struct AppIconService {
    enum Icon: String, CaseIterable, Identifiable {
        case primary

        var id: String { rawValue }

        var iconName: String? {
            switch self {
            case .primary:
                return nil
            }
        }

        var title: String {
            switch self {
            case .primary:
                return "thre"
            }
        }

        var subtitle: String {
            switch self {
            case .primary:
                return "[thre] mark"
            }
        }

        var backgroundTop: Color {
            switch self {
            case .primary:
                return .black
            }
        }

        var backgroundBottom: Color {
            switch self {
            case .primary:
                return .black
            }
        }

        var coreInner: Color {
            switch self {
            case .primary:
                return Color(hex: "FF7D28")
            }
        }

        var coreOuter: Color {
            switch self {
            case .primary:
                return Color(hex: "FF5A00")
            }
        }

        var ringColor: Color {
            switch self {
            case .primary:
                return Color.white.opacity(0.06)
            }
        }

        var glowColor: Color {
            switch self {
            case .primary:
                return Color(hex: "FF6A00").opacity(0.26)
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
