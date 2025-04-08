//
//  Colors.swift
//  Brush
//
//  Created by Moon Davé on 12/5/20.
//

import SwiftUI

extension Color {

    // TODO: Obviously we need a design system
    static let tartOrange: Color = { Self.fromRGB(255, 74, 73) }()
    static let polishedPine: Color = { Self.fromRGB(81, 158, 138) }()
    static let eerieBlack: Color = { Self.fromRGB(32, 30, 31) }()
    static let vividTangerine: Color = { Self.fromRGB(255, 166, 158) }()
    static let sunray: Color = { Self.fromRGB(229, 183, 105) }()

    private static func fromRGB(_ r: Int, _ g: Int, _ b: Int) -> Color {
        return Color(CGColor(red: CGFloat(Double(r/255)), green: CGFloat(g/255), blue: CGFloat(b/255), alpha: 0.5))
    }

}

extension Color {

    func toSIMD() -> SIMD4<Float> {
        guard
            let components = self.cgColor?.components,
            components.count == 4
        else { fatalError("Color component issues") }
        return SIMD4<Float>(arrayLiteral: components)
    }

}
