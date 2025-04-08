//
//  UITouch.swift
//  CatFiddle
//
//  Created by Moon Davé on 12/29/20.
//

import UIKit

extension UITouch {

    /// Extracts point data from `UITouch`.
    /// Converts point to NDC coordinates
    /// - Parameter view: The `UIView` the touch resides in
    /// - Returns: `Point`
    func getPoint(in view: UIView) -> Point {
        let cgPoint = self.location(in: view)
        return Point(
            pos: float2(
                2 * cgPoint.x / view.frame.size.width - 1,
                -2 * cgPoint.y / view.frame.size.height + 1
            ),
            angle: Float(self.altitudeAngle),
            pressure: Float(self.force)
        )
    }

}
