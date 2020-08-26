//
//  DiscreteScaledPOint.swift
//  CanalesDigitalesGCiOS
//
//  Created by Jorge Ouahbi on 22/08/2020.
//  Copyright © 2020 Banco Caminos. All rights reserved.
//

import UIKit
import Accelerate

protocol ScaledPointsGenerator {
    var maximumValue: Float {get}
    var minimumValue: Float {get}
    var insets: UIEdgeInsets {get set}
    var minimum: Float?  {get set}
    var maximum: Float?  {get set}
    var range: Float  {get}
    var hScale: CGFloat  {get}
    var isLimitsDirty: Bool {get set}
    
    func makePoints(data: [Float], size: CGSize) -> [CGPoint]
    func updateRangeLimits(_ data: [Float])
}
// Default values.
extension ScaledPointsGenerator {
    var hScale: CGFloat  {return 1.0}
    var minimum: Float?  {return nil }
    var maximum: Float?  {return nil }
    var range: Float {
        return maximumValue - minimumValue
    }
}
// MARK: - DiscreteScaledPointsGenerator -
class DiscreteScaledPointsGenerator: ScaledPointsGenerator {
    var hScale: CGFloat  { return 1.0 }
    var insets: UIEdgeInsets =  UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
    var isLimitsDirty: Bool = true
    var maximumValue: Float = 0
    var minimumValue: Float = 0
    var minimum: Float? = nil {
        didSet {
            isLimitsDirty = true
        }
    }
    var maximum: Float? = nil {
        didSet {
            isLimitsDirty = true
        }
    }
    func updateRangeLimits(_ data: [Float]) {
        guard isLimitsDirty else {
            return
        }
        // Normalize values in array (i.e. scale to 0-1)...
        var min: Float = 0
        if let minimum = minimum {
            min = minimum
        } else {
            vDSP_minv(data, 1, &min, vDSP_Length(data.count))
        }
        minimumValue = min
        var max: Float = 0
        if let maximum = maximum {
            max = maximum
        } else {
            vDSP_maxv(data, 1, &max, vDSP_Length(data.count))
        }
        maximumValue = max
        isLimitsDirty = false
    }
    func makePoints(data: [Float], size: CGSize) -> [CGPoint] {
        // claculate the size
        let insetHeight   = (insets.bottom + insets.top)
        let insetWidth    = (insets.left + insets.right)
        let insetY        =  insets.top
        // the size
        let newSize  = CGSize(width: size.width,
                             height: size.height - insetHeight)
        var scale = 1 / self.range
        var minusMin = -minimumValue
        var scaled = [Float](repeating: 0, count: data.count)
        //        for (n = 0; n < N; ++n)
        //           scaled[n] = (A[n] + B[n]) * C;
        vDSP_vasm(data, 1, &minusMin, 0, &scale, &scaled, 1, vDSP_Length(data.count))
        let xScale = newSize.width / CGFloat(data.count)
        return scaled.enumerated().map {
            return CGPoint(x: xScale * hScale * CGFloat($0.offset),
                           y: (newSize.height * CGFloat(1.0 - ($0.element.isFinite ? $0.element : 0))) + insetY)
        }
    }
}