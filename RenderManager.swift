//
//  RenderManager.swift
//  OMScrollableChart
//
//  Created by Jorge Ouahbi on 17/02/2021.
//

import UIKit
import LibControl

/*
 
 Host           Renders
 [SC]  --->   |  ---- Polyline
 (Data)  |  ---- Points
 |  ---- Selected point
 
 | ---- Base custom render
 
 
 
 */


// MARK: Default renders idents
public enum RenderIdent: Int {
    case polyline       = 0
    case points         = 1
    case selectedPoint  = 2
    case base           = 3  //  public renders base index
}

public enum SimplifyType {
    case none
    case douglasPeuckerRadial
    case douglasPeuckerDecimate
    case visvalingam
    case ramerDouglasPeuckerPerp
}

public enum RenderDataType: Equatable {
    case discrete
    case stadistics(CGFloat)
    case simplify(SimplifyType, CGFloat)
    case regress(Int)
}

typealias RenderType = RenderDataType

public struct DataRender  {
    static var empty: DataRender = DataRender(data: [], points: [])
    internal var output: [CGPoint] = []
    internal var input: [Float] = []
    // tipo de render
    private var type: RenderType = .discrete
    init( data: [Float], points: [CGPoint], type: RenderType = RenderType.discrete) {
        self.input = data
        self.output = points
        self.type = type
    }
    init(  points: [CGPoint]) {
        input = []
        type = .discrete
        output = points
    }
    init( data: [Float]) {
        input = data
        type = .discrete
        output = []
    }
    
    var copy: DataRender {
        return DataRender(data: data,
                          points: points,
                          type: type)
    }
    
    public var points: [CGPoint] { return output}
    public var data: [Float] { return input}
    public var dataType: RenderDataType { return type}
    public var minPoint: CGPoint? {
        return output.max(by: {$0.x > $1.x})
    }
    public var maxPoint: CGPoint? {
        return output.max(by: {$0.x <= $1.x})
    }
    /// Get  render point from index.
    /// - Parameters:
    ///   - renderIndex: Render index
    ///   - index: index point in render index ´renderIndex´
    /// - Returns: CGPoint or nil if point not found
    public func point(withIndex index: Int) -> CGPoint? {
        assert(index < points.count)
        return points[index]
    }
    /// indexForPoint
    /// - Parameters:
    ///   - point: CGPoint
    ///   - renderIndex: Int
    /// - Returns: Int?
    public func index(withPoint point: CGPoint) -> Int? {
        switch type {
        case .discrete:
            return points.map { $0.distance(point) }.mini
        case .stadistics:
            return points.map { $0.distance(point) }.mini
        case .simplify:
            return points.map { $0.distance(point) }.mini
        case .regress:
            return points.map { $0.distance(point) }.mini
        }
    }
    /// data from point
    /// - Parameter point: point description
    /// - Returns: description
    public func data(withPoint point: CGPoint) -> Float? {
        switch dataType {
        case .discrete:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        case .stadistics:
            if let firstIndex = points.map({ $0.distance(point) }).mini {
                return data[firstIndex]
            }
        case .simplify:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        case .regress:
            if let firstIndex = points.firstIndex(of: point) {
                return data[firstIndex]
            }
        }
        return nil
        // return dataIndexFromLayers(point, renderIndex: renderIndex)
    }
    
    public func dataIndex(withPoint point: CGPoint) -> Int? {
        switch dataType {
        case .discrete:
            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }
            
        case .stadistics:
            if let firstIndex = index(withPoint: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }
        case .simplify:
            
            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }
            
        case .regress:
            
            if let firstIndex = points.firstIndex(of: point) {
                return firstIndex
            } else {
                return points.map({ $0.distance(point) }).mini
            }
            
        }
        return nil // dataIndexFromLayers(point, renderIndex: renderIndex)
    }
}

// MARK: RenderProtocol
public protocol RenderProtocol {
    associatedtype DataRender
    var data: DataRender {get set} // Points and data
    var layers: [GradientShapeLayer] {get set}
    var index: Int {get set}
    func locationToLayer(_ location: CGPoint, mostNearLayer: Bool ) -> GradientShapeLayer?
    func layerPointFromPoint(_ point: CGPoint ) -> CGPoint
    func layerFrameFromPoint(_ point: CGPoint ) -> CGRect
    func makePoints(_ size: CGSize) -> [CGPoint]
    var isEmpty: Bool { get}
}

// MARK: BaseRender
open class BaseRender: RenderProtocol {
    public var index: Int = 0
    public var data: DataRender = .empty
    public var layers: [GradientShapeLayer] = []
    public init(index: Int) {
        self.index = index
    }
    public init() {
        
    }
    
    public var isEmpty: Bool {
        return data.data.isEmpty && data.points.isEmpty
    }
    
    public func allOtherLayers(layer: GradientShapeLayer ) -> [GradientShapeLayer] {
        if !layers.contains(layer) { return [] }
        return layers.filter { $0 != layer }
    }
    
    /// locationToLayer
    /// - Parameters:
    ///   - location: CGPoint
    ///   - mostNearLayer: Bool
    /// - Returns: GradientShapeLayer
    public func locationToLayer(_ location: CGPoint, mostNearLayer: Bool = true) -> GradientShapeLayer? {
        let mapped = layers.map {  (layer: CALayer) in
            layer.frame.origin.distance(location)
        }
        if mostNearLayer {
            guard let index = mapped.mini else {
                return nil
            }
            return layers[index]
        } else {
            guard let index = mapped.maxi else {
                return nil
            }
            return layers[index]
        }
    }
    /// layerPointFromPoint
    /// - Parameter point: CGPoint
    /// - Returns: CGPoint
    public func layerPointFromPoint(_ point: CGPoint ) -> CGPoint{
        /// Select the last point if the render is not hidden.
        guard let layer = locationToLayer(point, mostNearLayer: true) else {
            return .zero
        }
        return layer.position
    }
    
    /// layerFrameFromPoint
    /// - Parameter point: point description
    /// - Returns: CGRect
    public func layerFrameFromPoint(_ point: CGPoint ) -> CGRect{
        /// Select the last point if the render is not hidden.
        guard let layer = locationToLayer(point, mostNearLayer: true) else {
            return .zero
        }
        return layer.frame
    }
    
    /// makePoints
    /// - Parameter size: CGSize
    /// - Returns: [CGPoint]
    public func makePoints(_ size: CGSize) -> [CGPoint] {
        assert(size != .zero)
        return DiscreteScaledPointsGenerator().makePoints(data: self.data.data, size: size)
    }
    
    public func sectionIndex( withPoint point: CGPoint, numberOfSections: Int) -> Int {
        let dataIndexLayer = data.dataIndex( withPoint: point )
        // Get the selection data index
        if let dataIndex = dataIndexLayer {
            let pointPerSectionRelation = Double(data.data.count) / Double(numberOfSections)
            let sectionIndex = Int(floor(Double(dataIndex) / Double(pointPerSectionRelation) ) ) % numberOfSections
            //            print(
            //                """
            //                        Render index: \(Int(render.index))
            //                        Data index: \(Int(dataIndex))
            //
            //                        \((ruleManager.footerRule?.views?[Int(sectionIndex)] as? UILabel)?.text ?? "")
            //
            //                        Point to section relation \(pointPerSectionRelation)
            //                        Section index: \(Int(sectionIndex))
            //                """)
            
            return Int(sectionIndex)
        }
        return Index.bad.rawValue
    }
}

public class PolylineRender: BaseRender {
    override init() {
        super.init(index: RenderIdent.polyline.rawValue)
    }
}

public class PointsRender: BaseRender {
    override init() {
        super.init(index: RenderIdent.points.rawValue)
    }
}

public class SelectedPointRender: BaseRender {
    override init() {
        super.init(index: RenderIdent.selectedPoint.rawValue)
    }
}


public protocol RenderEngineClientProtocol: class {
    var engine: RenderManagerProtocol {get}
}

// MARK: - RenderManagerProtocol -
public protocol RenderManagerProtocol {
    
    var version: Int {get}
    
    
    init()
    
    func configureRenders() -> [BaseRender]
    func update(_ numberOfdRenders: Int)
    func removeAllLayers()
    
    var visibleLayers: [CAShapeLayer] { get }
    var invisibleLayers: [CAShapeLayer] { get }
    var allPointsRender: [CGPoint] { get }
    var allDataPointsRender: [Float] { get }
    var allRendersLayers: [CAShapeLayer] { get }
    
    var points: [[CGPoint]] { get set }
    var layers: [[GradientShapeLayer]]  { get set }
    var data: [[Float]]   { get set }
    
    static var shared: RenderManager {get}
    var renders: [BaseRender] {get set}
}

extension RenderManagerProtocol {
    public var version: Int { 1}
}

open class RenderManager: RenderManagerProtocol {
    static public var shared: RenderManager = RenderManager()
    open var renders: [BaseRender] = []
    required public init() {
        self.renders = configureRenders()
    }
    open func update(_ numberOfdRenders: Int) {
        for idx in renders.count..<numberOfdRenders {
            renders.insert(BaseRender(index: idx), at: idx)
        }
    }
    open func configureRenders() -> [BaseRender] { [RenderManager.polyline, RenderManager.points, RenderManager.selectedPoint] }
    open func removeAllLayers() {
        self.renders.forEach{
            $0.layers.forEach{$0.removeFromSuperlayer()}
            $0.layers.removeAll()
        }
    }
    open var layers: [[GradientShapeLayer]] {
        get { RenderManager.shared.renders.reduce([[]]) { $0 + [$1.layers] } }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.layers = newValue[$0]
                
            }
        }
    }
    // points
    open var points: [[CGPoint]] {
        get { RenderManager.shared.renders.map{$0.data.points} }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach {
                $1.data = DataRender(data: $1.data.data , points: newValue[$0], type: $1.data.dataType )
            }
        }
    }
    // data
    open var data: [[Float]]  {
        get { RenderManager.shared.renders.map{$0.data.data} }
        set(newValue) {
            return RenderManager.shared.renders.enumerated().forEach{
                $1.data = DataRender(data: newValue[$0], points: $1.data.points, type: $1.data.dataType )
            }
        }
    }
    
    //
    // Getters helpers
    //
    
    
    public var visibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 1.0 } }
    public var invisibleLayers: [CAShapeLayer] { allRendersLayers.filter { $0.opacity == 0 }}
    public var allPointsRender: [CGPoint] {    RenderManager.shared.points.flatMap{$0}}
    public var allDataPointsRender: [Float]  {   RenderManager.shared.data.flatMap{$0}}
    public var allRendersLayers: [CAShapeLayer]  {   RenderManager.shared.layers.flatMap{$0} }
    


}



extension RenderManager {
    //
    // Renders
    //
    
    public static var polyline: PolylineRender  = PolylineRender()
    public static var points: PointsRender = PointsRender()
    public static var selectedPoint: SelectedPointRender = SelectedPointRender()
}
