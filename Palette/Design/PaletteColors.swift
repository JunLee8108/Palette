import SwiftUI

struct PaletteSwatch: Identifiable, Hashable {
    let id: String
    let hex: String
    var color: Color { Color(hex: hex) }
}

enum DefaultPalette {
    static let id = "default_v1"

    static let swatches: [PaletteSwatch] = [
        .init(id: "d1_01", hex: "#E8594A"),
        .init(id: "d1_02", hex: "#F07D4C"),
        .init(id: "d1_03", hex: "#F4A74C"),
        .init(id: "d1_04", hex: "#F5C84C"),
        .init(id: "d1_05", hex: "#E8DC6F"),
        .init(id: "d1_06", hex: "#C8D96E"),
        .init(id: "d1_07", hex: "#8FC06E"),
        .init(id: "d1_08", hex: "#5AA874"),
        .init(id: "d1_09", hex: "#3D8A6B"),
        .init(id: "d1_10", hex: "#2C5F4F"),
        .init(id: "d1_11", hex: "#6FB3D2"),
        .init(id: "d1_12", hex: "#4A8FBD"),
        .init(id: "d1_13", hex: "#2E6B9E"),
        .init(id: "d1_14", hex: "#1F4A7A"),
        .init(id: "d1_15", hex: "#16305C"),
        .init(id: "d1_16", hex: "#9B7EBD"),
        .init(id: "d1_17", hex: "#B46FAB"),
        .init(id: "d1_18", hex: "#C85A94"),
        .init(id: "d1_19", hex: "#D96E7C"),
        .init(id: "d1_20", hex: "#A04A5C"),
        .init(id: "d1_21", hex: "#F5F2EB"),
        .init(id: "d1_22", hex: "#E8E0D0"),
        .init(id: "d1_23", hex: "#C8BBA8"),
        .init(id: "d1_24", hex: "#7A756E"),
        .init(id: "d1_25", hex: "#2A2824")
    ]
}
