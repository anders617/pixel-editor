//
//  PixelColorViewController.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/9/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension Float {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension UIImage {
    func getPixelColor(pos: CGPoint) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        
        
        let pixelInfo: Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo])
        let g = CGFloat(data[pixelInfo+1])
        let b = CGFloat(data[pixelInfo+2])
        let a = CGFloat(data[pixelInfo+3])
        
        return (r, g, b, a)
    }
    
    func withAlphaLayerOfValue(value:CGFloat)->UIImage {
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let oldData:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let newImageContext = CGBitmapContextCreate(nil, CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage), CGImageGetBitsPerComponent(self.CGImage), CGImageGetBytesPerRow(self.CGImage), CGImageGetColorSpace(self.CGImage), CGImageGetBitmapInfo(self.CGImage) | CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
        let newDataVoidPtr = CGBitmapContextGetData(newImageContext)
        let newData = unsafeBitCast(newDataVoidPtr, UnsafeMutablePointer<UInt8>.self)
        for i in 0..<((Int(self.size.width) * Int(self.size.height)) * 4) {
            if i%4 == 3 {
                newData[i] = UInt8(value)
            } else {
                newData[i] = UInt8(value / 255 * CGFloat(oldData[i]))
            }
        }
        let newImage = CGBitmapContextCreateImage(newImageContext)
        return UIImage(CGImage: newImage)!
    }
    
    func changePixelColor(pos: CGPoint, withData:(CGFloat, CGFloat, CGFloat, CGFloat))->UIImage {
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let oldData:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let newImageContext = CGBitmapContextCreate(nil, CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage), CGImageGetBitsPerComponent(self.CGImage), CGImageGetBytesPerRow(self.CGImage), CGImageGetColorSpace(self.CGImage), CGImageGetBitmapInfo(self.CGImage) | CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue))
        let newDataVoidPtr = CGBitmapContextGetData(newImageContext)
        let newData = unsafeBitCast(newDataVoidPtr, UnsafeMutablePointer<UInt8>.self)
        for i in 0..<((Int(self.size.width) * Int(self.size.height)) * 4) {
            newData[i] = oldData[i]
        }
        
        
        let pixelInfo = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        newData[pixelInfo] = UInt8(withData.3 * withData.0 / 255)
        newData[pixelInfo + 1] = UInt8(withData.3 * withData.1 / 255)
        newData[pixelInfo + 2] = UInt8(withData.3 * withData.2 / 255)
        newData[pixelInfo + 3] = UInt8(withData.3)
        
        let newImage = CGBitmapContextCreateImage(newImageContext)
        let newUIImage = UIImage(CGImage: newImage)
        return newUIImage!
    }
}

class PixelColorViewController: UIViewController, UIScrollViewDelegate {
    
    //TODO:Add variable to store the original color in order to calculate the component differential.
    var imagePath:NSURL?
    var image:UIImage?
    private var redComponent:CGFloat = 0
    private var greenComponent:CGFloat = 120
    private var blueComponent:CGFloat = 250
    private var alphaComponent:CGFloat = 1
    private var tapGestureRecognizer:UITapGestureRecognizer?
    private var doubleTapGestureRecognizer:UITapGestureRecognizer?
    private var hasLayedOutSubview = false
    private var selectedPoint:CGPoint = CGPointZero
    
    private var imageScale:CGFloat?
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var selectedColorView: CircleColorView!
    @IBOutlet var componentSliders: [UISlider]!
    @IBOutlet var componentTitles: [UILabel]!
    @IBOutlet var componentValueLabels: [UILabel]!
    @IBOutlet var coordsLabel: UILabel!
    @IBOutlet var scrollView: PixelScrollView!
    @IBOutlet var toleranceSlider: UISlider!
    @IBOutlet var toleranceLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.contentMode = .ScaleAspectFit
        
        self.navigationItem.title = "Pixel Editor"
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveChanges")
        let revertButton = UIBarButtonItem(barButtonSystemItem: .Undo, target: self, action: "revertChanges")
        self.navigationItem.rightBarButtonItems = [saveButton, revertButton]
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "didPressDone")
        self.navigationItem.leftBarButtonItem = doneButton
        if let path = imagePath {
            image = UIImage(contentsOfFile: path.path!)
        }
        
        if let viewImage = image {
            imageView.image = UIImage(CGImage: viewImage.CGImage)?.withAlphaLayerOfValue(255)
        }
        imageView.backgroundColor = UIColor.blackColor()
        
        selectColorAtPoint(selectedPoint)
        
        componentSliders[0].value = Float(redComponent)
        componentSliders[1].value = Float(greenComponent)
        componentSliders[2].value = Float(blueComponent)
        componentSliders[3].value = Float(alphaComponent)
        
        for sliderIndex in 0..<componentSliders.count {
            componentValueLabels[sliderIndex].text = "\(componentSliders[sliderIndex].value.description)"
        }
        
        //Set Up ScrollView
        scrollView.maximumZoomScale = 4.0
        scrollView.pinchGestureRecognizer.enabled = true
        scrollView.delegate = self
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "processTap")
        scrollView.addGestureRecognizer(tapGestureRecognizer!)
        doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: "doubleTap")
        doubleTapGestureRecognizer?.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGestureRecognizer!)
        centerScrollViewContents()
        scrollView.imageViewBounds = imageView.bounds
        
        // Do any additional setup after loading the view.
        println("[Pixel Editor]Loaded pixel editor view.")
    }
    
    override func viewDidLayoutSubviews() {
        findImageScale()
        if !hasLayedOutSubview {
            scrollView.contentOffset = CGPointZero
            scrollView.maximumZoomScale = 50 / imageScale!
            hasLayedOutSubview = true
        }
    }
    
    func doubleTap() {
        if let isInScrollViewCheck = doubleTapGestureRecognizer?.locationInView(scrollView) {
            if let imageViewLocation = doubleTapGestureRecognizer?.locationInView(imageView) {
                println("[Pixel Editor]Double tap detected.")
                let imageLocation = getPhotoCoordinatesFromImageViewCoordinates(imageViewLocation)
                if scrollView.zoomScale < scrollView.maximumZoomScale {
                    if let viewImage = imageView.image {
                        let halfWidth = viewImage.size.width * imageScale! / 3 / scrollView.zoomScale
                        let halfHeight = viewImage.size.height * imageScale! / 3 / scrollView.zoomScale
                        let zoomRect = CGRect(centerX: imageViewLocation.x, centerY: imageViewLocation.y, rectWidth: halfWidth, rectHeight: halfHeight)
                        scrollView.zoomToRect(zoomRect, animated: true)
                    }
                    
                } else {
                    scrollView.zoomToRect(imageView.bounds, animated: true)
                }
            }
        }
    }
    
    func didPressDone() {
        let saveAlert = UIAlertController(title: "Warning", message: "All unsaved changes will be lost! Are you sure you would like to exit the editor?", preferredStyle: .Alert)
        saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default) {
            s1 in
            self.navigationController?.popViewControllerAnimated(true)
            })
        saveAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(saveAlert, animated: true, completion: nil)
    }
    
    func saveChanges() {
        let fileManager = NSFileManager()
        var imageData = UIImagePNGRepresentation(imageView.image)
        if let path = imagePath {
            if imageData.writeToFile(path.path!, atomically: true) {
                println("[Pixel Editor]Saved edited photo at location \(path.path!)")
            } else {
                println("[Error]Failed to save edited photo to location \(path.path!)")
            }
        }
    }
    
    func revertChanges() {
        let loseChangesAlert = UIAlertController(title: "Revert Changes?", message: "All unsaved changes to this photo will be lost. Are you sure?", preferredStyle: .Alert)
        loseChangesAlert.addAction(UIAlertAction(title: "Yes", style: .Default) {
            s1 in
            if let viewImage = self.image {
                self.imageView.image = UIImage(CGImage: viewImage.CGImage)
                println("[Pixel Editor]Reverted edited photo to original.")
                self.updateComponentValuesAtPoint(self.selectedPoint)
            }
            })
        loseChangesAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(loseChangesAlert, animated: true, completion: nil)
    }
    
    private func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func processTap() {
        println("[Pixel Editor]Single tap detected.")
        if let isInScrollViewCheck = tapGestureRecognizer?.locationInView(scrollView) {
            if let location = tapGestureRecognizer?.locationInView(imageView) {
                selectColorAtPoint(location)
            }
        }
        
    }
    
    @IBAction func didChangeSlider(sender: UISlider) {
        let index = find(componentSliders, sender)
        componentValueLabels[index!].text = componentSliders[index!].value.format(".2")
        if let compIndex = index {
            switch(compIndex) {
            case 0:redComponent = CGFloat(sender.value)
            case 1: greenComponent = CGFloat(sender.value)
            case 2: blueComponent = CGFloat(sender.value)
            case 3: alphaComponent = CGFloat(sender.value)
            default: redComponent = CGFloat(sender.value)
            }
        }
        updateViewColor()
    }
    
    @IBAction func didFinishChangingSlider(sender: UISlider) {
        imageView.image = imageView.image?.changePixelColor(selectedPoint, withData: (redComponent, greenComponent, blueComponent, alphaComponent))
    }
    
    func updateViewColor() {
        let newColor = UIColor(redComp: redComponent, greenComp: greenComponent, blueComp: blueComponent, alpha: alphaComponent/255)
        selectedColorView.fillColor = newColor
        //selectedColorView.alpha = alphaComponent
        selectedColorView.setNeedsLayout()
    }
    
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let points = touches as? Set<UITouch>
        if let point = points?.first?.locationInView(scrollView) {
            selectColorAtPoint(point)
        }
        
    }
    
    private func updateComponentValuesAtPoint(realCoords:CGPoint) {
        if let pixelInfo = imageView.image?.getPixelColor(realCoords) {
            redComponent = pixelInfo.0
            componentSliders[0].value = Float(pixelInfo.0)
            componentValueLabels[0].text = Double(pixelInfo.0).format(".2")
            greenComponent = pixelInfo.1
            componentSliders[1].value = Float(pixelInfo.1)
            componentValueLabels[1].text = Double(pixelInfo.1).format(".2")
            blueComponent = pixelInfo.2
            componentSliders[2].value = Float(pixelInfo.2)
            componentValueLabels[2].text = Double(pixelInfo.2).format(".2")
            alphaComponent = pixelInfo.3
            componentSliders[3].value = Float(pixelInfo.3)
            componentValueLabels[3].text = Double(pixelInfo.3).format(".2")
            updateViewColor()
        }
    }
    
    private func selectColorAtPoint(point:CGPoint) {
        if let currentImage = image {
            if let coords = getPhotoCoordinatesFromImageViewCoordinates(point) {
                coordsLabel.text = "\(Int(coords.x))X\(Int(coords.y))"
                println("[Pixel Editor]Selected color at point (\(Int(coords.x)), \(Int(coords.y)))")
                if let realCoords = getOriginalPhotoCoordinatesFromPhotoCoordinates(coords) {
                    //coordsLabel.text! += "\t\(Int(realCoords.x))X\(Int(realCoords.y))"
                    selectedPoint = realCoords
                    updateComponentValuesAtPoint(realCoords)
                }
            }
            
        }
    }
    
    private func getPhotoCoordinatesFromImageViewCoordinates(point:CGPoint)->CGPoint? {
        if let scale = imageScale {
            let originalImageHeight = imageView.image?.size.height
            let originalImageWidth = imageView.image?.size.width
            
            let imageViewWidth = imageView.bounds.width
            let imageViewHeight = imageView.bounds.height
            
            let displayImageHeight = originalImageHeight! * scale
            let displayImageWidth = originalImageWidth! * scale
            
            let widthMargin = ((imageViewWidth - displayImageWidth) / 2)
            let heightMargin = ((imageViewHeight - displayImageHeight) / 2)
            
            let newX = point.x - widthMargin
            let newY = point.y - heightMargin
            
            if (newX >= 0)&&(newX <= displayImageWidth)&&(newY >= 0)&&(newY <= displayImageHeight) {
                return CGPoint(x: newX, y: newY)
            } else {
                return nil
            }
        } else {
            findImageScale()
            return point
        }
    }
    
    private func getOriginalPhotoCoordinatesFromPhotoCoordinates(point:CGPoint)->CGPoint? {
        if let scale = imageScale {
            let newX = point.x / scale
            let newY = point.y / scale
            return CGPoint(x: newX, y: newY)
        } else {
            findImageScale()
            return point
        }
    }
    
    private func findImageScale() {
        let imageViewWidth = imageView.bounds.width
        let imageViewHeight = imageView.bounds.height
        let originalImageHeight = imageView.image?.size.height
        let originalImageWidth = imageView.image?.size.width
        
        let widthScale = imageViewWidth / originalImageWidth!
        let heightScale = imageViewHeight / originalImageHeight!
        
        imageScale = fmin(widthScale, heightScale)
        scrollView.imageScale = imageScale
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private func componentDifferentialFrom(original:(CGFloat, CGFloat, CGFloat), toComponents:(CGFloat, CGFloat, CGFloat)) -> CGFloat {
        let squareSum = pow(toComponents.0 - original.0, 2) + pow(toComponents.1 - original.1, 2) + pow(toComponents.2 - original.2, 2)
        return sqrt(squareSum)
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        self.scrollView.imageViewBounds = imageView.bounds
        self.scrollView.shouldResizeGrid = true
        scrollView.setNeedsLayout()
    }
    
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
    
}
