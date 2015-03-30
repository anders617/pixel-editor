//
//  CircleColorView.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/9/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

extension UIColor {
    
    /**
    Convenience initializer to create a UIColor object with red, green and blue components ranging from 0 to 255. The alpha value should be between 0 and 1.
    */
    convenience init(redComp: CGFloat, greenComp: CGFloat, blueComp: CGFloat, alpha: CGFloat) {
        let red = redComp/255
        let green = greenComp/255
        let blue = blueComp/255
        self.init(red:red, green: green, blue: blue, alpha: alpha)
    }
}

import UIKit

//@IBDesignable
/**
This subclass of UIView displays an oval fit to the bounds of the view. The fill color of the view may be changed through the fillColor property.
*/
class CircleColorView: UIView {
    
    private var circleLayer:CAShapeLayer?
    
    /**
    The color with which the circle layer in the CircleColorView will be filled.
    */
    var fillColor:UIColor?
    
    private var currentBounds:CGRect?
    
    
    
    override func layoutSubviews() {
        
        if (circleLayer == nil) {
            
            circleLayer = CAShapeLayer()
            layer.addSublayer(circleLayer)
            
            let circlePath = UIBezierPath(ovalInRect: self.bounds)
            circleLayer?.path = circlePath.CGPath
            
            if let color = fillColor {
                circleLayer?.fillColor = color.CGColor
            } else {
                circleLayer?.fillColor = UIColor(redComp: 0, greenComp: 120, blueComp: 250, alpha: 1).CGColor
            }
            circleLayer?.lineWidth = 0
            currentBounds = bounds
            
        } else {
            if bounds != currentBounds {
                circleLayer?.bounds = bounds
                currentBounds = bounds
                let circlePath = UIBezierPath(ovalInRect: bounds)
                circleLayer?.path = circlePath.CGPath
            }
            if let newColor = fillColor {
                circleLayer?.fillColor = newColor.CGColor
            } else {
                circleLayer?.fillColor = UIColor(redComp: 0, greenComp: 120, blueComp: 250, alpha: 1).CGColor
            }
        }
        
        
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
