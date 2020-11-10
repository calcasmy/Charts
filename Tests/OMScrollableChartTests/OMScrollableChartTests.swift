//
//  ExampleTests.swift
//  ExampleTests
//
//  Created by Jorge Ouahbi on 29/10/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import XCTest
@testable import OMScrollableChart
@testable import LibControl

class OMScrollableChartTests: XCTestCase {

    static var allTests = [
        ("testSimplification", testSimplification),
        ("testScaledPointsGenerator", testScaledPointsGenerator),
        ("testEquality", testEquality),
        ("testMidpoint", testMidpoint),
        ("testAngle", testAngle),
        ("testLength", testLength),
        ("testTranslate", testTranslate),
        ("testRotate", testRotate),
        ("testInterpolatePointAtT", testInterpolatePointAtT),
        ("testBounds", testBounds),
        ("testPointsOnLineAtDistance", testPointsOnLineAtDistance),
        ("testIntersectionPointWithLineSegment", testIntersectionPointWithLineSegment)
            // test intersection
    ]
    func testSimplification() {
        var result1 = [CGPoint]()
        var result2 = [CGPoint]()
        var result3 = [CGPoint]()
        var decimate = [CGPoint]()
        
        let numberOfItems = 300
        let randomPoints  = (0..<numberOfItems).map { _ in CGPoint(x: .random(min: 0, max: UIScreen.main.bounds.size.width),
                                                                y: .random(min: 0, max: UIScreen.main.bounds.size.height)) }
        print("#  ",
              "  Visva",
              "  DP Rad",
              "  Ramer DP",
              "  Decimate")
        
        for index in (0..<numberOfItems) {
            result1 = OMSimplify.visvalingamSimplify(randomPoints, limit: CGFloat(index) )
            result2 = OMSimplify.simplifyDouglasPeuckerRadial(randomPoints, tolerance: CGFloat(index), highestQuality: true)
            decimate = OMSimplify.simplifyDouglasPeuckerDecimate(randomPoints, tolerance:  CGFloat(sqrt(Double(index * 2))) )
            result3 = OMSimplify.ramerDouglasPeuckerSimplify(randomPoints, epsilon: Double(index) )
            print(index,
                  "    \(result1.count)",
                  "    \(result2.count)",
                  "     \(result3.count)",
                  "    \(decimate.count)")
        }
    }
    
    func testScaledPointsGenerator() {
        let numberOfItems = 300
        let sizes = randomSize(bounded: UIScreen.main.bounds, numberOfItems: numberOfItems)
        let scaler = DiscreteScaledPointsGenerator()
        for size in sizes {
            let randomData = randomFloat(numberOfItems)
            let points  = scaler.makePoints(data: randomData, size: size)
            points.forEach { CGRect(origin: .zero, size: size).contains($0) }
            let points2 = ScaledPointsGenerator(randomData, size: size, insets: .zero).makePoints()
            points2.forEach { CGRect(origin: .zero, size: size).contains($0)}
            XCTAssert(points == points2)
        }
    }

  
    func testEquality() {
        let segment1 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let segment2 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        
        XCTAssert(segment1 == segment2)
    }
    
    func testMidpoint() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let actualMidpoint = CGPoint(x: 5.0, y: 5.0)
        
        XCTAssert(segment.midpoint() == actualMidpoint)
    }
    
    func testAngle() {
        // Test vertical
        let vertical = LineSegment(CGPoint(x: 0.0, y: -10.0), CGPoint(x: 0.0, y: 10.0))
        XCTAssert(vertical.angle() == CGFloat(M_PI/2))
        
        // Test horizontal
        let horizontal = LineSegment(CGPoint(x: 0.0, y: -1.0), CGPoint(x: 10.0, y: -1.0))
        XCTAssert(horizontal.angle() == 0)
        
        // Test 45deg or PI/4
        let fortyfive = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        XCTAssert(fortyfive.angle() == CGFloat(M_PI/4.0))
    }
    
    func testLength() {
        let segment = LineSegment(CGPoint(x: 0.0, y: -10.0), CGPoint(x: 0.0, y: 10.0))
        
        XCTAssert(segment.length() == 20.0)
    }
    
    func testTranslate() {
        var segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        segment.translateInPlace(dX: -1.0, dY: -1.0)
        
        XCTAssert(segment.p1 == CGPoint(x: -1.0, y: -1.0) && segment.p2 == CGPoint(x: 9.0, y: 9.0))
    }
    
    func testRotate() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let rotated = segment.rotate(radians: -CGFloat(M_PI/2), aboutPoint: CGPoint(x: 0.0, y: 0.0))
        
        XCTAssert( rotated.p1 == CGPoint(x: 0, y: 0) && rotated.p2 == CGPoint(x: 10, y: -10))
    }
    
    func testInterpolatePointAtT() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let point = segment.interpolatePointAtT(t: 0.5)
        
        XCTAssert(point == CGPoint(x: 5.0, y: 5.0))
    }
    
    func testBounds() {
        let segment = LineSegment(CGPoint(x: -10.0, y: -10.0), CGPoint(x: 10.0, y: 10.0))
        
        XCTAssert(segment.bounds() == CGRect(x: -10.0, y: -10.0, width: 20.0, height: 20.0))
    }
    
    func testPointsOnLineAtDistance() {
        let segment = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 0.0))
        let pts = segment.pointsOnLineAtDistance(distance: 2.0)
        let comparePts = [
            CGPoint(x: 2.0, y: 0.0),
            CGPoint(x: 4.0, y: 0.0),
            CGPoint(x: 6.0, y: 0.0),
            CGPoint(x: 8.0, y: 0.0),
            CGPoint(x: 10.0, y: 0.0)
        ]
        
        XCTAssert(pts == comparePts)
    }
    
    func testIntersectionPointWithLineSegment() {
        // test intersection
        let segment1 = LineSegment(CGPoint(x: 0.0, y: 0.0), CGPoint(x: 10.0, y: 10.0))
        let segment2 = LineSegment(CGPoint(x: 0.0, y: 10.0), CGPoint(x: 10.0, y: 0.0))
        
        XCTAssert(segment1.intersectionPointWithLineSegment(segment: segment2)! == CGPoint(x: 5.0, y: 5.0), "Lines should intersection at (5.0, 5.0)")
        
        // test do not intersect
        let segment3 = LineSegment(CGPoint(x: 20.0, y: 20.0), CGPoint(x: 30.0, y: 30.0))
        
        XCTAssert(segment1.intersectionPointWithLineSegment(segment: segment3) == nil, "Lines should not intersection, expected nil")
    }
}
