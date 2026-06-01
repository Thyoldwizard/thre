// GrainOverlay.swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct GrainOverlay: View {
    var opacity: Double = 0.02

    var body: some View {
        GeometryReader { geo in
            Self.noiseImage
                .resizable(resizingMode: .tile)
                .frame(width: geo.size.width, height: geo.size.height)
                .blendMode(.overlay)
                .opacity(opacity)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private static let noiseImage: Image = {
        let context = CIContext(options: [.workingColorSpace: CGColorSpaceCreateDeviceGray()])
        let filter = CIFilter.randomGenerator()
        let rect = CGRect(x: 0, y: 0, width: 192, height: 192)

        guard let outputImage = filter.outputImage?.cropped(to: rect),
              let cgImage = context.createCGImage(outputImage, from: rect) else {
            return Image(systemName: "square.fill")
        }

        return Image(uiImage: UIImage(cgImage: cgImage))
    }()
}

#Preview {
    ZStack {
        Color(hex: "070707").ignoresSafeArea()
        GrainOverlay()
    }
}
