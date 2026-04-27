import Foundation
import ImageIO
import CoreGraphics
#if canImport(UIKit)
import UIKit
#endif

nonisolated enum ColorExtractor {
    struct Bucket: Sendable {
        let r: UInt8
        let g: UInt8
        let b: UInt8
        let count: Int
    }

    private static let bins: Int = 6
    private static let thumbnailMax: Int = 64

    static func extract(from data: Data) async -> [Bucket] {
        await Task.detached(priority: .userInitiated) {
            Self.extractSync(from: data)
        }.value
    }

    private static func extractSync(from data: Data) -> [Bucket] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return [] }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMax,
        ]

        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return []
        }

        let width = cg.width
        let height = cg.height
        guard width > 0, height > 0 else { return [] }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let ctx = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return [] }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        let bins = Self.bins
        var counts = [Int](repeating: 0, count: bins * bins * bins)
        let total = width * height

        for i in 0..<total {
            let off = i * 4
            let a = pixels[off + 3]
            if a < 64 { continue }
            let r = pixels[off]
            let g = pixels[off + 1]
            let b = pixels[off + 2]
            let ri = min(Int(r) * bins / 256, bins - 1)
            let gi = min(Int(g) * bins / 256, bins - 1)
            let bi = min(Int(b) * bins / 256, bins - 1)
            counts[ri * bins * bins + gi * bins + bi] += 1
        }

        var buckets: [Bucket] = []
        for ri in 0..<bins {
            for gi in 0..<bins {
                for bi in 0..<bins {
                    let count = counts[ri * bins * bins + gi * bins + bi]
                    if count == 0 { continue }
                    buckets.append(Bucket(
                        r: UInt8((ri * 256 + 128) / bins),
                        g: UInt8((gi * 256 + 128) / bins),
                        b: UInt8((bi * 256 + 128) / bins),
                        count: count
                    ))
                }
            }
        }
        return buckets.sorted { $0.count > $1.count }
    }
}
