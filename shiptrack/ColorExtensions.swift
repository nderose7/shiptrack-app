//
//  ColorExtensions.swift
//  shiptrack
//
//  Created by Nick DeRose on 12/7/23.
//

import Foundation
import SwiftUI

extension Color {
    static func hex(_ hex: String) -> Color {
        var cleanedHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if cleanedHex.count == 6 {
            cleanedHex = "FF" + cleanedHex // Default to fully opaque if no alpha component is provided
        }

        var int = UInt64()
        Scanner(string: cleanedHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)

        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
