//
//  PixelImageView.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/21/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit

class PixelImageView: UIImageView {
    var shouldDisplayGrid = false
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        if shouldDisplayGrid {
            let context = UIGraphicsGetCurrentContext()
            CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
            CGContextSetLineWidth(context, 0.5)
            
            //Vertical Lines
            for i in 0..<Int(bounds.width) {
                CGContextMoveToPoint(context, CGFloat(i), 0)
                CGContextAddLineToPoint(context, CGFloat(i), bounds.height)
            }
            
            //Horizontal Lines
            for i in 0..<Int(bounds.height) {
                CGContextMoveToPoint(context, 0, CGFloat(i))
                CGContextAddLineToPoint(context, bounds.width, CGFloat(i))
            }
            
        }
    }
    
    
}
