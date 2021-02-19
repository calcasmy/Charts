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

// https://stackoverflow.com/questions/35915853/how-to-show-tooltip-on-a-point-click-in-swift
// https://itnext.io/swift-uiview-lovely-animation-and-transition-d34bd623391f
// https://stackoverflow.com/questions/29674959/linear-regression-accelerate-framework-in-swift
// https://gist.github.com/marmelroy/ed4bd675bd75c757ab7447d1b3488886

import UIKit
import Accelerate
import LibControl

public struct RuleManager {
    
    var rootRule: ChartRuleProtocol?
    var footerRule: ChartRuleProtocol?
    var topRule: ChartRuleProtocol?
    var rules = [ChartRuleProtocol]()
    var ruleLeadingAnchor: NSLayoutConstraint?
    var ruletopAnchor: NSLayoutConstraint?
    var rulebottomAnchor: NSLayoutConstraint?
    var rulewidthAnchor: NSLayoutConstraint?
    var ruleHeightAnchor: NSLayoutConstraint?
    var ruleFont = UIFont.systemFont(ofSize: 10, weight: .medium)
    var rulesPoints = [CGPoint]()
    var footerViewHeight: CGFloat = 60
    var topViewHeight: CGFloat = 20
    
    func hideRules() { rules.forEach{$0.isHidden = true }}
    func showRules() { rules.forEach{$0.isHidden = false }}
}


/*
 [topRule]
 ---------------------
 |
 rootRule   |
 |
 |
 |       footerRule
 |______________________
 */

extension OMScrollableChart {
    
    /// addLeadingRuleIfNeeded
    /// - Parameters:
    ///   - rule: ChartRuleProtocol
    ///   - view: UIView
    func addLeadingRuleIfNeeded(_ rule: ChartRuleProtocol?,
                                view: UIView? = nil) {
        guard let rule = rule else {
            return
        }
        //rule.backgroundColor = .red
        assert(rule.type == .leading)
        if rule.superview == nil {
            rule.translatesAutoresizingMaskIntoConstraints = false
            if let view = view  {
                view.insertSubview(rule, at: rule.type.rawValue)
            } else {
                self.insertSubview(rule, at: rule.type.rawValue)
            }
            let width = rule.ruleSize.width > 0 ?
                rule.ruleSize.width :
                contentView.bounds.width
            let height = rule.ruleSize.height > 0 ?
                rule.ruleSize.height :
                contentView.bounds.height
            print(height, width)
            ruleManager.ruleLeadingAnchor  = rule.leadingAnchor.constraint(equalTo: self.leadingAnchor)
            ruleManager.ruletopAnchor      = rule.topAnchor.constraint(equalTo: self.contentView.topAnchor)
            ruleManager.rulewidthAnchor    = rule.widthAnchor.constraint(equalToConstant: CGFloat(width))
            ruleManager.ruleHeightAnchor    = rule.heightAnchor.constraint(equalToConstant: CGFloat(height))
            
            if let footerRule = ruleManager.footerRule {
                ruleManager.rulebottomAnchor =  rule.bottomAnchor.constraint(equalTo: footerRule.bottomAnchor,
                                                                 constant: -footerRule.ruleSize.height)
            }
            
            ruleManager.ruleLeadingAnchor?.isActive  = true
            ruleManager.ruletopAnchor?.isActive  = true
            //rulebottomAnchor?.isActive  = true
            ruleManager.rulewidthAnchor?.isActive  = true
            ruleManager.ruleHeightAnchor?.isActive  = true
        }
    }
    
    /// addFooterRuleIfNeeded
    /// - Parameters:
    ///   - rule: ruleFooter description
    ///   - view: UIView
    func addFooterRuleIfNeeded(_ rule: ChartRuleProtocol? = nil,
                               view: UIView? = nil) {
        guard let rule = rule else {
            return
        }
        assert(rule.type == .footer)
        //rule.backgroundColor = .red
        if rule.superview == nil {
            rule.translatesAutoresizingMaskIntoConstraints = false
            if let view = view {
                view.insertSubview(rule, at: rule.type.rawValue)
            } else {
                self.insertSubview(rule, at: rule.type.rawValue)
            }
            
            let width = rule.ruleSize.width > 0 ?
                rule.ruleSize.width :
                contentView.bounds.width
            let height = rule.ruleSize.height > 0 ?
                rule.ruleSize.height :
                contentView.bounds.height
            
            //rule.backgroundColor = UIColor.gray
            rule.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
            rule.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
            rule.topAnchor.constraint(equalTo: self.contentView.bottomAnchor,
                                      constant: 0).isActive = true
            rule.heightAnchor.constraint(equalToConstant: CGFloat(height)).isActive = true
            rule.widthAnchor.constraint(equalToConstant: width).isActive = true
        }
    }
    
    //     func addTopRuleIfNeeded(_ ruleTop: ChartRuleProtocol? = nil) {
    //        guard let ruleTop = ruleTop else {
    //            return
    //        }
    //        assert(ruleTop.type == .top)
    //        //ruleTop.removeFromSuperview()
    //        ruleTop.translatesAutoresizingMaskIntoConstraints = false
    //        ruleTop.backgroundColor = UIColor.clear
    //        self.addSubview(ruleTop)
    //        //        topView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
    //        //        topView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
    //        ruleTop.topAnchor.constraint(equalTo:  self.topAnchor).isActive = true
    //        ruleTop.heightAnchor.constraint(equalToConstant: CGFloat(topViewHeight)).isActive = true
    //        ruleTop.widthAnchor.constraint(equalToConstant: contentSize.width).isActive = true
    //        ruleTop.backgroundColor = .gray
    //    }
    
    
    func appendRuleMark( _ value: Float) {
//        if value > 100000 {
//            let roundToNearest = round(value / 10000) * 10000
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 10000 {
//            let roundToNearest = round(value / 1000) * 1000
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 1000 {
//            let roundToNearest = round(value / 100) * 100
//            internalRulesMarks.append(roundToNearest)
//        } else if value > 100 {
//            let roundToNearest = round(value / 10) * 10
//            internalRulesMarks.append(roundToNearest)
//        } else {
//            internalRulesMarks.append(round(value))
//        }
        
        // Dont be adaptative, only round the 1000
        if value > 10000 {
            let roundToNearest = round(value / 1000) * 1000
            internalRulesMarks.append(roundToNearest)
        }else {
            internalRulesMarks.append(round(value))
        }
    }
    // Calculate the rules marks positions
    func internalCalcRules(generator: ScaledPointsGenerator) {
        // Get the polyline generator
        // + 2 is the limit up and the limit down
        let numberOfAllRuleMarks = Int(numberOfRuleMarks) + 2 - 1
        let roundedStep = generator.range / Float(numberOfAllRuleMarks)
        for ruleMarkIndex in 0..<numberOfAllRuleMarks {
            let value = generator.minimumValue + Float(roundedStep) * Float(ruleMarkIndex)
            appendRuleMark(value)
        }
        appendRuleMark(generator.maximumValue)
        
    }
    // Create and add
    func createSuplementaryRules() {
        
        let rootRule = OMScrollableLeadingChartRule(chart: self)
        rootRule.chart = self
        rootRule.font  = ruleManager.ruleFont
        rootRule.fontColor = fontRootRuleColor
        let footerRule = OMScrollableChartRuleFooter(chart: self)
        footerRule.chart = self
        footerRule.font  = ruleManager.ruleFont
        footerRule.fontColor = fontFooterRuleColor
        ruleManager.rootRule = rootRule
        ruleManager.footerRule = footerRule
        ruleManager.rules.append(rootRule)
        ruleManager.rules.append(footerRule)
        // self.rules.append(topRule)
        
        
        //        if let topRule = topRule {
        //
        //        }
    }
    func makeRulesPoints() -> Bool {
        var generator: ScaledPointsGenerator?
        switch engine.renders[RenderIdent.polyline.rawValue].data.dataType {
        case .discrete:
             let data = engine.renders[RenderIdent.polyline.rawValue].data
            generator  = DiscreteScaledPointsGenerator(data: data.data)
            
        case .stadistics(_):
             let data = engine.renders[RenderIdent.polyline.rawValue].data
            generator  = DiscreteScaledPointsGenerator(data: data.data)
            
        case .simplify(_,_):
            break
            
        case .regress(_):
            break
        }
   
        guard numberOfRuleMarks > 0,
              let generatorUnwarp = generator,
              (generatorUnwarp.range != 0)  else {
            return false
        }
        internalRulesMarks.removeAll()
        internalCalcRules(generator: generatorUnwarp)
        ruleManager.rulesPoints = generatorUnwarp.makePoints(data: rulesMarks, size: drawableFrame.size)
        return true
    }
    
    func addDashLinesToMarksToVerticalRule(_ leadingRule: ChartRuleProtocol) {
        dashLineLayers.forEach({$0.removeFromSuperlayer()})
        dashLineLayers.removeAll()
        
        let leadingRuleWidth: CGFloat = leadingRule.ruleSize.width
        let width: CGFloat = contentView.frame.width
        
        //let fontSize = ruleFont.pointSize
        for (index, item) in ruleManager.rulesPoints.enumerated() {
            var yPos = item.y
            if index > 0 {
                if index < ruleManager.rulesPoints.count - 1 {
                    yPos = item.y
                } else {
                    yPos = item.y
                }
            }
            let markPointLeft  = CGPoint(x: leadingRuleWidth, y: yPos)
            let markPointRight = CGPoint(x: width, y: yPos)
            addDashLineLayerFromRuleMark(point: markPointLeft, endPoint: markPointRight)
        }
    }
    ///
    func layoutRules() {
        // rules lines
        let oldRulesPoints = ruleManager.rulesPoints
        guard let leadingRule = ruleManager.rootRule else {
            return
        }
        guard makeRulesPoints() else {
            return
        }
        if ruleManager.rulesPoints == oldRulesPoints {
            return
        }
        addDashLinesToMarksToVerticalRule(leadingRule)
        // Mark for display the rule.
        ruleManager.rules.forEach {
           _ = $0.layoutRule()
            $0.setNeedsDisplay()
        }
    }
}


public class OMScrollableChartRuleFlow: OMScrollableChartRuleDelegate {
    public func deviceRotation() {
        print("[Flow] deviceRotation")
    }
    public func footerSectionDidSelected(section: Int, selectedView: UIView?) {
        print("[Flow] footerSectionDidSelected", section, selectedView)
    }
    
    public func footerSectionDidDeselected(section: Int, selectedView: UIView?) {
        print("[Flow] footerSectionDidDeselected", section, selectedView)
    }
    
    public func updateRenderLayers(index: Int, with layers: [GradientShapeLayer]) {
        print("[Flow] updateRenderLayers", index, layers)
    }
    
    public func updateRenderData(index: Int, data: RenderData) {
        print("[Flow] updateRenderData", index, data)
    }
    
    public func renderDataTypeChanged(in dataOfRender: RenderType) {
        print("[Flow] renderDataTypeChanged", dataOfRender)
    }
    
    public func drawRootRuleText(in frame: CGRect, text: NSAttributedString) {
        print("[Flow] drawRootRuleText", frame, text)
    }
    
    public func footerSectionsTextChanged(texts: [String]) {
        print("[Flow] footerSectionsTextChanged", texts)
    }
    
    public func numberOfPagesChanged(pages: Int) {
        print("[Flow] numberOfPagesChanged", pages)
    }
    
    public func contentSizeChanged(contentSize: CGSize) {
        print("[Flow] contentSizeChanged", contentSize)
    }
    
    public func frameChanged(frame: CGRect) {
        print("[Flow] frameChanged", frame)
    }
    
    public func dataPointsChanged(dataPoints: [Float], for index: Int) {
        print("dataPointsChanged", index, dataPoints)
    }
}
