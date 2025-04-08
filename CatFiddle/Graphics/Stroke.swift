//
//  Stroke.swift
//  Brush
//
//  Created by Moon Davé on 11/10/20.
//

import MetalKit


// MARK: - Stroke

typealias Stroke = [Point]

// MARK: - Point

/// Point will store the position, and additional properties such as angle, pressure, etc...
struct Point {
    var pos: SIMD2<Float>
    var vel = SIMD2<Float>() // maybe this should be required
    var angle: Float = 0.0
    var pressure: Float = 0.0
}


extension Point {

    // TODO: a LERP may be sufficient...
    static func cubicInterpolatedPoint(_ a: Self, _ b: Self) -> Self {
        let G = matrix_float4x2([a.pos, b.pos, a.vel, b.vel])
        let H = matrix_float4x4.hermite()
        let T = SIMD4<Float>(0.125, 0.25, 0.5, 1) // [t^3, t^2, t, 1] t=0.5
        return Point(pos: G * H * T)
    }

}
