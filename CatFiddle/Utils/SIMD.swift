//
//  SIMD.swift
//  Brush
//
//  Created by Moon Davé on 12/15/20.
//

import CoreGraphics

typealias float2 = SIMD2<Float>
typealias float3 = SIMD3<Float>



extension SIMD2 where Scalar == Float  {

    init(_ x: CGFloat, _ y: CGFloat) {
        self.init(Float(x), Float(y))
    }

}

extension SIMD4 where Scalar == Float  {

    init(arrayLiteral: [CGFloat]) {
        self.init(arrayLiteral.map { Float($0) })
    }
    
}
