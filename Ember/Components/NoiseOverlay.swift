// NoiseOverlay.swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct NoiseOverlay: View {
    /// Opacity of the noise layer — default 3%
    var opacity: Double = 0.03

    var body: some View {
        GeometryReader { geo in
            noiseImage
                .resizable(resizingMode: .tile)
                .frame(width: geo.size.width, height: geo.size.height)
                .blendMode(.overlay)
                .opacity(opacity)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    /// Try to load bundled texture; fall back to generated noise
    private var noiseImage: Image {
        if UIImage(named: "noise-grain") != nil {
            return Image("noise-grain")
        } else {
            return generatedNoiseImage
        }
    }

    /// Programmatically generated noise texture using CIFilter
    private var generatedNoiseImage: Image {
        let context = CIContext()
        let filter = CIFilter.randomGenerator()

        guard let outputImage = filter.outputImage else {
            return Image(systemName: "square.fill")
        }

        // Crop to 256x256
        let cropped = outputImage.cropped(to: CGRect(x: 0, y: 0, width: 256, height: 256))

        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else {
            return Image(systemName: "square.fill")
        }

        let uiImage = UIImage(cgImage: cgImage)
        return Image(uiImage: uiImage)
    }
}
