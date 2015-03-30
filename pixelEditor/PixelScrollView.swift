//
//  PixelScrollView.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/21/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit

class PixelScrollView: UIScrollView {
    
    /**
        The scalar which the image bounds were mulitplied to fit the UIImageView bounds.
    */
    var imageScale:CGFloat?
    
    /**
    The bounds of the UIImageView contained within the PixelScrollView.
    */
    var imageViewBounds: CGRect = CGRectZero
    
    /**
    Tells the PixelScrollView to resize the grid the next time layoutSubviews is called. This value is reset to false after the grid is resized.
    */
    var shouldResizeGrid = false
    
    /**
    The horixontal offset of the image within the UIImageView contained in the PixelScrollView.
    */
    var imageXOffset:CGFloat = 0
    
    /**
    The vertical offset of the image within the UIImageView contained in the PixelScrollView.
    */
    var imageYOffset:CGFloat = 0
    
    private let RealPixelPerPhotoPixelThreshold:CGFloat = 15
    
    private var gridLayer:CAShapeLayer?
    
    override func layoutSubviews() {
        if gridLayer == nil {
            gridLayer = CAShapeLayer()
            layer.addSublayer(gridLayer)
            setUpGridLayer()
            shouldResizeGrid = false
        } else if let scale = imageScale {
            let realPixelsPerPhotoPixel = zoomScale * scale
            if realPixelsPerPhotoPixel < RealPixelPerPhotoPixelThreshold {
                gridLayer?.removeFromSuperlayer()
                gridLayer = nil
                shouldResizeGrid = false
            } else if shouldResizeGrid{
                gridLayer?.removeFromSuperlayer()
                gridLayer = CAShapeLayer()
                layer.addSublayer(gridLayer)
                setUpGridLayer()
                shouldResizeGrid = false
            }
        }
    }
    
    private func setUpGridLayer() {
        if let scale = imageScale {
            let realPixelsPerPhotoPixel = zoomScale * scale
            if realPixelsPerPhotoPixel >= RealPixelPerPhotoPixelThreshold {
                println("[PixelScrollView]Drawing grid to imageView (\(Int((imageViewBounds.width - 2 * imageXOffset) / scale)) vertical;\(Int((imageViewBounds.height - 2 * imageYOffset) / scale)) horizontal)")
                //Vertical Lines
                for i in 0..<Int((imageViewBounds.width - 2 * imageXOffset) / scale) {
                    let lineLayer = CAShapeLayer()
                    let linePath = UIBezierPath()
                    linePath.moveToPoint(CGPoint(x :(CGFloat(i)) * realPixelsPerPhotoPixel + imageXOffset * zoomScale, y: imageYOffset * zoomScale))
                    linePath.addLineToPoint(CGPoint(x: (CGFloat(i)) * realPixelsPerPhotoPixel + imageXOffset * zoomScale, y: (imageViewBounds.height - imageYOffset) * zoomScale))
                    lineLayer.path = linePath.CGPath
                    lineLayer.strokeColor = UIColor.grayColor().CGColor
                    lineLayer.lineWidth = 0.5
                    gridLayer?.addSublayer(lineLayer)
                    
                }
                
                //Horizontal Lines
                for i in 0..<Int((imageViewBounds.height - 2 * imageYOffset) / scale) {
                    let lineLayer = CAShapeLayer()
                    let linePath = UIBezierPath()
                    linePath.moveToPoint(CGPoint(x: imageXOffset * zoomScale, y: (CGFloat(i)) * realPixelsPerPhotoPixel + imageYOffset * zoomScale))
                    linePath.addLineToPoint(CGPoint(x: (imageViewBounds.width - imageXOffset) * zoomScale, y: (CGFloat(i)) * realPixelsPerPhotoPixel + imageYOffset * zoomScale))
                    lineLayer.path = linePath.CGPath
                    lineLayer.strokeColor = UIColor.grayColor().CGColor
                    lineLayer.lineWidth = 0.5
                    gridLayer?.addSublayer(lineLayer)
                }
                
            }
        }

    }
    
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    /*
    override func drawRect(rect: CGRect) {
    if let scale = imageScale {
    let realPixelsPerPhotoPixel = zoomScale / scale
    if realPixelsPerPhotoPixel > 10 {
    let context = UIGraphicsGetCurrentContext()
    CGContextSetStrokeColorWithColor(context, UIColor.grayColor().CGColor)
    CGContextSetLineWidth(context, 0.5)
    
    //Vertical Lines
    for i in 0..<Int(bounds.width/realPixelsPerPhotoPixel) {
    CGContextMoveToPoint(context, CGFloat(i) * realPixelsPerPhotoPixel, 0)
    CGContextAddLineToPoint(context, CGFloat(i) * realPixelsPerPhotoPixel, bounds.height)
    }
    
    //Horizontal Lines
    for i in 0..<Int(bounds.height/realPixelsPerPhotoPixel) {
    CGContextMoveToPoint(context, 0, CGFloat(i) * realPixelsPerPhotoPixel)
    CGContextAddLineToPoint(context, bounds.width, CGFloat(i) * realPixelsPerPhotoPixel)
    }
    
    }
    }
    }
    */
    
    
}
