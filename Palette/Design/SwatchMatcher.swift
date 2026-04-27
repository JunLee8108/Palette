import Foundation
import PaletteShared

enum SwatchMatcher {
    static func top(
        _ k: Int,
        from buckets: [ColorExtractor.Bucket],
        in swatches: [PaletteSwatch]
    ) -> [PaletteSwatch] {
        guard k > 0, !swatches.isEmpty else { return [] }

        let swatchRGB: [(swatch: PaletteSwatch, rgb: (Int, Int, Int))] = swatches.map {
            ($0, rgb(of: $0))
        }

        var chosen: [PaletteSwatch] = []
        var chosenIds = Set<String>()

        for bucket in buckets {
            let nearest = nearestSwatch(
                r: Int(bucket.r), g: Int(bucket.g), b: Int(bucket.b),
                in: swatchRGB
            )
            if !chosenIds.contains(nearest.id) {
                chosen.append(nearest)
                chosenIds.insert(nearest.id)
                if chosen.count >= k { return chosen }
            }
        }

        guard let dominant = chosen.first else { return chosen }
        let target = rgb(of: dominant)

        let neighbors = swatchRGB
            .filter { !chosenIds.contains($0.swatch.id) }
            .sorted { distance(target, $0.rgb) < distance(target, $1.rgb) }
            .map { $0.swatch }

        for swatch in neighbors {
            chosen.append(swatch)
            if chosen.count >= k { break }
        }
        return chosen
    }

    private static func nearestSwatch(
        r: Int, g: Int, b: Int,
        in swatchRGB: [(swatch: PaletteSwatch, rgb: (Int, Int, Int))]
    ) -> PaletteSwatch {
        var best = swatchRGB[0].swatch
        var bestDist = Int.max
        for entry in swatchRGB {
            let d = distance((r, g, b), entry.rgb)
            if d < bestDist {
                bestDist = d
                best = entry.swatch
            }
        }
        return best
    }

    private static func distance(_ a: (Int, Int, Int), _ b: (Int, Int, Int)) -> Int {
        let dr = a.0 - b.0
        let dg = a.1 - b.1
        let db = a.2 - b.2
        return dr * dr + dg * dg + db * db
    }

    private static func rgb(of swatch: PaletteSwatch) -> (Int, Int, Int) {
        let cleaned = swatch.hex.hasPrefix("#")
            ? String(swatch.hex.dropFirst())
            : swatch.hex
        guard cleaned.count >= 6, let value = Int(cleaned.prefix(6), radix: 16) else {
            return (0, 0, 0)
        }
        return ((value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF)
    }
}
