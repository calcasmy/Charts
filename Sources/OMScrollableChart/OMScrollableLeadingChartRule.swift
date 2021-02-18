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

import Foundation
import UIKit
import LibControl


public protocol OMScrollableChartRuleDelegate {
    func footerSectionsTextChanged(texts: [String])
    func footerSectionDidSelected(section: Int, selectedView: UIView?)
    func footerSectionDidDeselected(section: Int, selectedView: UIView?)
    func numberOfPagesChanged(pages: Int)
    func contentSizeChanged(contentSize: CGSize)
    func frameChanged(frame: CGRect)
    func dataPointsChanged(dataPoints: [Float], for index: Int)
    func drawRootRuleText(in frame: CGRect, text: NSAttributedString)
    func renderDataTypeChanged(in dataOfRender: RenderType)
    func updateRenderLayers( index: Int, with layers: [GradientShapeLayer])
    func updateRenderData(index: Int, data: RenderData)
    func deviceRotation()
    
}

enum ChartRuleType: Int {
    case leading = 0
    case footer = 1
    case top = 2
    case trailing = 3
}
protocol ChartRuleProtocol: UIView {
    var chart: OMScrollableChart! {get set}
    init(chart: OMScrollableChart!)
    var type: ChartRuleType {get set}

    
    var font: UIFont {get set}
    var fontColor: UIColor {get set}
    var fontStrokeColor: UIColor {get set}
    var decorationColor: UIColor {get set}
    var leftInset: CGFloat {get set}
    var ruleSize: CGSize {get}
    var views: [UIView]? {get}
    func layoutRule() -> Bool
}

// MARK: - OMScrollableLeadingChartRule -
class OMScrollableLeadingChartRule: UIView, ChartRuleProtocol {
    private var labelViews = [UIView]()
    var views: [UIView]?  {
        return labelViews
    }
    var type: ChartRuleType = .leading
    var chart: OMScrollableChart!
    var decorationColor: UIColor = .black
    //var isPointsNeeded: Bool =  true
    required init(chart: OMScrollableChart!) {
        super.init(frame: .zero)
        self.chart = chart
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    var fontColor = UIColor.black {
        didSet {
            views?.forEach({($0 as? UILabel)?.textColor = fontColor})
        }
    }
    var fontStrokeColor = UIColor.lightGray
    
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    var ruleSize: CGSize = CGSize(width: 60, height: 0)
    var leftInset: CGFloat = 15
    func layoutRule() -> Bool {
        guard let chart = chart else {
            return false
        }
        labelViews.forEach({$0.removeFromSuperview()})
        labelViews.removeAll()
        let fontSize: CGFloat = font.pointSize
                
        for (index, item) in chart.ruleManager.rulesPoints.enumerated() {
                if let stepString = chart.currencyFormatter.string(from: NSNumber(value: chart.rulesMarks[index])) {
                    let string = NSAttributedString(string: stepString,
                                                    attributes: [NSAttributedString.Key.font: self.font,
                                                                 NSAttributedString.Key.foregroundColor: self.fontColor,
                                                                 NSAttributedString.Key.strokeColor: self.fontStrokeColor])
                    let label = UILabel()
                    label.attributedText = string
                    label.sizeToFit()
                    label.frame = CGRect(x: leftInset,
                                     y: (item.y - fontSize),
                                         width: label.bounds.width,
                                         height: label.bounds.height)
                    self.addSubview(label)
                    labelViews.append(label)
                    // Notify the draw
                    chart.flowDelegate?.drawRootRuleText(in: label.frame, text: string)
                }
        }
        return true
    }
   
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setNeedsLayout()
    }
    
    var oldFrame: CGRect = .zero
    override func layoutSubviews() {
        super.layoutSubviews()
        if !layoutRule() { // TODO: update layout
           // Log.print("Unable to create the rule layout",.error)
        }
    }
}

// MARK: - OMScrollableChartRuleFooter -
class OMScrollableChartRuleFooter: UIStackView, ChartRuleProtocol {
    var fontStrokeColor: UIColor = .black
    var leftInset: CGFloat = 16
    var chart: OMScrollableChart!
    //var isPointsNeeded: Bool  =  false
    var type: ChartRuleType = .footer
    var views: [UIView]? {
        return arrangedSubviews
    }
    var footerRuleHeight: CGFloat = 30 {
        didSet {
            setNeedsLayout()
        }
    }
    /// init
    /// - Parameter chart: OMScrollableChart
    required init(chart: OMScrollableChart!) {
        super.init(frame: .zero)
        self.chart = chart
        self.alignment = .top
        backgroundColor = .clear
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    var ruleSize: CGSize { return CGSize(width: 0, height: self.chart.ruleManager.footerViewHeight)}
    var fontColor = UIColor.darkGreyBlueTwo {
        didSet {
            views?.forEach({($0 as? UILabel)?.textColor = fontColor})
        }
    }
    var font = UIFont.systemFont(ofSize: 14, weight: .thin) {
        didSet {
            views?.forEach({($0 as? UILabel)?.font = font})
        }
    }
    // Sections text.
    var footerSectionsText = [NSLocalizedString("Ene"), NSLocalizedString("Feb"), NSLocalizedString("Mar"),
                                                                          NSLocalizedString("Abr"),
                                                                          NSLocalizedString("May"), NSLocalizedString("Jun"), NSLocalizedString("Jul"), NSLocalizedString("Ago"), NSLocalizedString("Sep"), NSLocalizedString("Oct"), NSLocalizedString("Nov"), NSLocalizedString("Dic")] {
        didSet {
            #if DEBUG
            if footerSectionsText.count > 0 {
                assert(footerSectionsText.count == Int(chart.numberOfSections))
            }
            #endif
            setNeedsLayout()
        }
    }
    /// Border decoration.
    var borderDecorationWidth: CGFloat = 0.5
    var decorationColor: UIColor = UIColor.darkGreyBlueTwo
    var  borderViews = [UIView]()
    /// create rule layout
    /// - Returns: Bool
    func layoutRule() -> Bool {
        guard !self.frame.isEmpty else {
            return false
        }
        self.borderViews.forEach({ $0.removeFromSuperview()})
        self.subviews.forEach({ $0.removeFromSuperview()})
        let width  = chart.sectionWidth
        let height = ruleSize.height * 0.5
        let numOfSections = Int(chart.numberOfSections)
        let month = Calendar.current.dateComponents([.day, .month, .year], from: Date()).month ?? 0
        //if let month = startIndex {
        let currentMonth = month
        //let symbols = DateFormatter().monthSymbols
        for monthIndex in currentMonth...numOfSections + currentMonth  {
            //GCLog.print("monthIndex: \(monthIndex % footerSectionsText.count) \(footerSectionsText[monthIndex % footerSectionsText.count])", .trace)
            let label = UILabel(frame: .zero)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = footerSectionsText[monthIndex % footerSectionsText.count]
            label.textAlignment = .center
            label.font = font
            label.sizeToFit()
                label.backgroundColor = .clear
            label.textColor = fontColor
            self.addArrangedSubview(label)
            label.widthAnchor.constraint(equalToConstant: width).isActive = true
                //label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
            label.heightAnchor.constraint(equalToConstant: height).isActive = true
            borderViews.append(label.setBorder(border: .right(inset: 5),
                                            weight: borderDecorationWidth,
                                color: decorationColor.withAlphaComponent(0.24)))
        }
       // }
        borderViews.append(self.setBorder(border: .top(inset: 10),
                                      weight: borderDecorationWidth,
                       color: decorationColor.withAlphaComponent(0.24)))
        return true
    }
    var section: Int = 0
    var selectedView: UIView? = nil
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if let touch = touches.first {
            let location = touch.location(in: self)
            if let sectionSelectedIndex = arrangedSubviews.map{ $0.frame.origin }.map { $0.distance(location) }.mini {
                section = sectionSelectedIndex
                selectedView = arrangedSubviews[sectionSelectedIndex]
                print("Notify section selected index", sectionSelectedIndex, selectedView)
                
                chart.flowDelegate?.footerSectionDidSelected(section: sectionSelectedIndex,
                                                            selectedView: selectedView)
                
            }
        }
    }
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
  
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        chart.flowDelegate?.footerSectionDidDeselected(section: section,
                                                       selectedView: selectedView)
        section = 0
        selectedView = nil
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if !layoutRule() { // TODO: update layout
           // Log.print("Unable to create the rule layout", .error)
        }
    }
    override func layoutSubviews() {
        super.layoutSubviews()
//        backgroundColor = .surfaceDark
         if !layoutRule() { // TODO: update layout
            //Log.print("Unable to create the rule layout" ,.error)
        }
    }
}
