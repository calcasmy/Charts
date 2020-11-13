// Copyright 2018 Jorge Ouahbi
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//
//  OMScrollableChart+Selection.swift
//
//  Created by Jorge Ouahbi on 22/08/2020.
//  Copyright © 2020 dsp. All rights reserved.
//

import UIKit
import LibControl

extension OMScrollableChart {
    /// selectNearestRenderLayer
    /// - Parameters:
    ///   - renderIndex: render index
    ///   - point: point
    func selectNearestRenderLayer(_ renderIndex: Int, point: CGPoint ) {
        /// Select the last point if the render is not hidden.
        guard let layer = locationToLayer(renderIndex,
                                              location: point,
                                              mostNearLayer: true)
        else {
            return
        }
        self.selectRenderLayerWithAnimation(layer,
                                            selectedPoint: point,
                                            renderIndex: renderIndex)
    }
    /// selectRenderLayer
    /// - Parameters:
    ///   - layer: layer
    ///   - renderIndex: Int
    func selectRenderLayers(except layer: OMGradientShapeClipLayer, renderIndex: Int) {
        let allUnselectedRenderLayers = self.renderLayers[renderIndex].filter { $0 != layer }
        print("allUnselectedRenderLayers = \(allUnselectedRenderLayers.count)")
        allUnselectedRenderLayers.forEach { (layer: OMGradientShapeClipLayer) in
            layer.gardientColor = self.unselectedColor
            layer.opacity = self.unselectedOpacy
        }
        layer.gardientColor = self.selectedColor
        layer.opacity = self.selectedOpacy
    }

    /// Get the layer in the point using render
    /// - Parameters:
    ///   - location: CGPoint
    ///   - renderIndex: renderIndex
    ///   - mostNearLayer: Bool
    /// - Returns: OMGradientShapeClipLayer
    func locationToLayer(_ renderIndex: Int, location: CGPoint, mostNearLayer: Bool = true) -> OMGradientShapeClipLayer? {
        let mapped = renderLayers[renderIndex].map {
            $0.frame.origin.distance(from: location)
        }
        if mostNearLayer {
            guard let index = mapped.indexOfMin else {
                return nil
            }
            return renderLayers[renderIndex][index]
        } else {
            guard let index = mapped.indexOfMax else {
                return nil
            }
            return renderLayers[renderIndex][index]
        }
    }
    
    /// hitTestAsLayer
    /// - Parameter location: <#location description#>
    /// - Returns: CALayer
    func hitTestAsLayer(_ location: CGPoint) -> CALayer? {
        if let layer = contentView.layer.hitTest(location) { // If you hit a layer and if its a Shapelayer
            return layer
        }
        return nil
    }
    
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - layer: CALayer
    ///   - renderIndex: Int
    ///   - dataIndex: Int
    func didSelectedRenderLayerSection(_ renderIndex: Int, sectionIndex: Int, layer: CALayer) {
        // lets animate the footer rule
        if let footer = ruleManager.footerRule as? OMScrollableChartRuleFooter, let views = footer.views {
            print("circular section index", sectionIndex % numberOfSections)
            // shake section
            views[sectionIndex % numberOfSections].shakeGrow(duration: 1.0)
        }
        renderDelegate?.didSelectSection(chart: self,
                                         renderIndex: renderIndex,
                                         sectionIndex: sectionIndex,
                                         layer: layer)
    }
    
    /// didSelectedRenderLayerIndex
    /// - Parameters:
    ///   - renderIndex: <#renderIndex description#>
    ///   - dataIndex: <#dataIndex description#>
    ///   - layer: <#layer description#>
    func didSelectedRenderLayerIndex(_ renderIndex: Int, dataIndex: Int, layer: CALayer) {
        assert(renderIndex < renderType.count)
        renderDelegate?.didSelectDataIndex(chart: self,
                                           renderIndex: renderIndex,
                                           dataIndex: dataIndex,
                                           layer: layer)
    }

    /// Build the tooltip text to show.
    /// - Parameters:
    ///   - renderIndex: Index
    ///   - dataIndex: data index
    ///   - tooltipPosition: CGPoint
    ///   - layerPoint: layer point
    ///   - selectedPoint: selected point
    ///   - duration: TimeInterval
    private func buildTooltipText(_ renderIndex: Int,
                                  _ dataIndex: Int,
                                  _ tooltipPosition: inout CGPoint,
                                  _ layerPoint: OMGradientShapeClipLayer,
                                  _ selectedPoint: CGPoint,
                                  _ duration: TimeInterval)
    {
        // grab the tool tip text
        let tooltipText = dataSource?.dataPointTootipText(chart: self,
                                                          renderIndex: renderIndex,
                                                          dataIndex: dataIndex,
                                                          section: 0)
        // grab the section
        let dataSection = dataSource?.dataSectionForIndex(chart: self,
                                                          dataIndex: dataIndex,
                                                          section: 0) ?? ""
        tooltipPosition = CGPoint(x: layerPoint.position.x, y: selectedPoint.y)
        
        if let tooltipText = tooltipText { // the dataSource was priority
            tooltip.string = "\(dataSection) \(tooltipText)"
            tooltip.displayTooltip(tooltipPosition, duration: duration)
        } else {
            // then calculate manually
            let amount = Double(renderDataPoints[renderIndex][dataIndex])
            if let dataString = currencyFormatter.string(from: NSNumber(value: amount)) {
                tooltip.string = "\(dataSection) \(dataString)"
            } else if let string = dataStringFromPoint(renderIndex, point: layerPoint.position) {
                tooltip.string = "\(dataSection) \(string)"
            } else {
                print("FIXME: unexpected render | data \(renderIndex) | \(dataIndex)")
            }
            tooltip.displayTooltip(tooltipPosition, duration: duration)
        }
    }
    
    private func notifySectionSelection(_ renderIndex: Int, _ dataIndex: Int, _ layerPoint: OMGradientShapeClipLayer) {
        let pointPerSectionRelation = self.renderResolution(with: renderType[renderIndex], renderIndex: renderIndex)
        let sectionIndex: Int = Int(floor(Double(dataIndex) / Double(pointPerSectionRelation))) % numberOfSections
       // print("Selected section: \(Int(sectionIndex)) \((footerRule?.views?[sectionIndex] as? UILabel)?.text)")
        
        // notify the section selection
        self.didSelectedRenderLayerSection( renderIndex,
                                           sectionIndex: Int(sectionIndex),
                                           layer:layerPoint)
    }
    /// Show tooltip
    /// - Parameters:
    ///   - layerPoint: OMGradientShapeClipLayer
    ///   - renderIndex: Index
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - duration: TimeInterval
    private func selectionShowTooltip( _ layerPoint: OMGradientShapeClipLayer,
                                       _ renderIndex: Int,
                                       _ selectedPoint: CGPoint,
                                       _ animation: Bool,
                                       _ duration: TimeInterval) {
        var tooltipPosition = CGPoint.zero
        var tooltipPositionFix = CGPoint.zero
        if animation {
            tooltipPositionFix = layerPoint.position
        }
        // Get the selection data index
        if let dataIndex = dataIndexFromPoint( renderIndex, point: layerPoint.position) {
            print("Selected data point index: \(dataIndex) type: \(renderType[renderIndex])")
            // notify the data index selection
            self.didSelectedRenderLayerIndex( renderIndex, dataIndex: Int(dataIndex), layer: layerPoint)
            self.notifySectionSelection(renderIndex,
                                        dataIndex,
                                        layerPoint)
            // Create the text and show the
            self.buildTooltipText(renderIndex,
                                  dataIndex,
                                  &tooltipPosition,
                                  layerPoint,
                                  selectedPoint,
                                  duration)
        }
        if animation {
            let distance = tooltipPositionFix.distance(from: tooltipPosition)
            let factor = TimeInterval(1 / (self.contentView.bounds.size.height / distance))
            let after: TimeInterval = 0.5
            DispatchQueue.main.asyncAfter(deadline: .now() + after) {
                self.tooltip.moveTooltip(tooltipPositionFix,
                                         duration: factor * duration)
            }
        }
    }
    
    /// selectRenderLayerWithAnimation
    /// - Parameters:
    ///   - layerPoint: OMGradientShapeClipLayer
    ///   - selectedPoint: CGPoint
    ///   - animation: Bool
    ///   - renderIndex: Int
    func selectRenderLayerWithAnimation(_ layerPoint: OMGradientShapeClipLayer,
                                        selectedPoint: CGPoint,
                                        animation: Bool = false,
                                        renderIndex: Int,
                                        duration: TimeInterval = 0.5) {
        CATransaction.setAnimationDuration(duration)
        CATransaction.begin()
    
        if showPointsOnSelection {
            self.selectRenderLayers(except: layerPoint, renderIndex: renderIndex)
        }
        if animateOnRenderLayerSelection, layerPoint.opacity > 0, animation {
            self.animateOnRenderLayerSelection(layerPoint, renderIndex: renderIndex, duration: duration)
        }
        if showTooltip {
            self.selectionShowTooltip( layerPoint,
                                      renderIndex,
                                      selectedPoint,
                                      animation,
                                      duration)
        }
    
        if zoomIsActive {
            if zoomScale == 1 {
                CATransaction.begin()
                CATransaction.setAnimationDuration(1.0)
                CATransaction.setCompletionBlock( {
                    CATransaction.setAnimationDuration(duration)
                    let scale = CATransform3DMakeScale(self.maximumZoomScale, self.maximumZoomScale, 1)
                    self.zoom(to: self.zoomRectForScale(scale: self.maximumZoomScale, center: selectedPoint), animated: true)
                    //self.footerRule?.views?.forEach{$0.layer.transform = scale}
                    
                    
//                    self.oldFooterTransform3D = self.footerRule?.transform ?? .init()
//                    self.oldRootTransform3D = self.rootRule?.transform3D ?? .init()
//                    self.footerRule?.transform3D = scale
//                    self.rootRule?.transform3D  = scale
                    
                    
                    //self.zoom(toPoint: selectedPoint, scale: 2.0, animated: true)
                })
                CATransaction.commit()
            }
        }
        CATransaction.commit()
    }
    /// locationFromTouchInContentView
    /// - Parameter touches: Set<UITouch>
    /// - Returns: CGPoint
    public func locationFromTouchInContentView(_ touches: Set<UITouch>) -> CGPoint {
        if let touch = touches.first {
            return touch.location(in: self.contentView)
        }
        return .zero
    }
}

