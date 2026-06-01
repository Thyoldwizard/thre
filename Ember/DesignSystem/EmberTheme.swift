import SwiftUI

enum EmberTheme: String, CaseIterable {
    case ember
    case electric
    case bone
    case magma

    var displayName: String {
        switch self {
        case .ember:
            return "thre"
        case .electric:
            return "electric"
        case .bone:
            return "bone"
        case .magma:
            return "magma"
        }
    }

    var accent: Color {
        switch self {
        case .ember:
            return Color(hex: "FF6A00")
        case .electric:
            return Color(hex: "3FD6FF")
        case .bone:
            return Color(hex: "E8DED0")
        case .magma:
            return Color(hex: "FF4D2E")
        }
    }

    var accentPressed: Color {
        switch self {
        case .ember:
            return Color(hex: "E05C00")
        case .electric:
            return Color(hex: "17B5E2")
        case .bone:
            return Color(hex: "CFC3B4")
        case .magma:
            return Color(hex: "D83A20")
        }
    }

    var accentSubtle: Color {
        switch self {
        case .ember:
            return Color(hex: "FF6A00").opacity(0.16)
        case .electric:
            return Color(hex: "3FD6FF").opacity(0.16)
        case .bone:
            return Color(hex: "E8DED0").opacity(0.18)
        case .magma:
            return Color(hex: "FF4D2E").opacity(0.16)
        }
    }
}
