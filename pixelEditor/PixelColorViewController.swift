//
//  PixelColorViewController.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/9/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit

extension Double {
    
    /**
    Creates a string with the given number of decimal places.
    
    :param: f A string representing the number of decimal places to use.
    :returns: A string with the given number of decimal places of the double.
    
    */
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

extension Float {
    
    /**
    Creates a string with the given number of decimal places.
    
    :param: f A string representing the number of decimal places to use.
    :returns: A string with the given number of decimal places of the float.
    
    */
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
    
    /**
    
    */
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
    
    
    /**
    Shifts the red, green, blue and alpha components of pixels by the values passed through the byValues parameter at the locations specified by the positions parameter.
    
    :param: positions The points to which the shift should be applied.
    :param: byValues The red, green, blue and alpha shift which should be applied to the pixels.
    :param: updateProgress A function to be called when a progress indicator should be updated. The passed value is the fraction of work completed.
    :returns: A new UIImage instance which includes the shifted component values.
    */
    func shiftPixelColors(positions:[CGPoint], byValues: (CGFloat, CGFloat, CGFloat, CGFloat), updateProgress:(Float -> Void)?) -> UIImage {
        
        func pixelIndex(x:CGFloat, y:CGFloat) -> Int {
            return ((Int(self.size.width) * Int(y)) + Int(x)) * 4
        }
        
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let oldData:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let newImageContext = CGBitmapContextCreate(
            nil,
            CGImageGetWidth(self.CGImage),
            CGImageGetHeight(self.CGImage),
            CGImageGetBitsPerComponent(self.CGImage),
            CGImageGetBytesPerRow(self.CGImage),
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage)|CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        )
        let newDataVoidPtr = CGBitmapContextGetData(newImageContext)
        let newData = unsafeBitCast(newDataVoidPtr, UnsafeMutablePointer<UInt8>.self)
        for i in 0..<((Int(self.size.width) * Int(self.size.height)) * 4) {
            newData[i] = oldData[i]
        }
        
        var index:Int = 0
        var alphaFactor:CGFloat = 0
        let totalPixels = Float(positions.count)
        var currentPixel:Float = 0
        var newThread = NSThread()
        for point in positions {
            index = pixelIndex(point.x, point.y)
            alphaFactor = min((CGFloat(oldData[index + 3]) + byValues.3), 255) / 255
            newData[index] = UInt8(max(min((CGFloat(oldData[index]) + byValues.0) * alphaFactor, 255), 0))
            newData[index + 1] = UInt8(max(min((CGFloat(oldData[index + 1]) + byValues.1) * alphaFactor, 255),0))
            newData[index + 2] = UInt8(max(min((CGFloat(oldData[index + 2]) + byValues.2) * alphaFactor, 255),0))
            newData[index + 3] = UInt8(max(min((CGFloat(oldData[index + 3]) + byValues.3), 255),0))
            if currentPixel % 50 == 0 {
                if let displayProgress = updateProgress {
                    displayProgress(currentPixel / (totalPixels + totalPixels/10))
                }
            }
            currentPixel++
        }
        
        let newImage = CGBitmapContextCreateImage(newImageContext)
        let newUIImage = UIImage(CGImage: newImage)
        if let displayProgress = updateProgress {
            displayProgress(1)
        }
        return newUIImage!
        
    }
    
    func changePixelColor(pos: CGPoint, withData:(CGFloat, CGFloat, CGFloat, CGFloat))->UIImage {
        let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let oldData:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let newImageContext = CGBitmapContextCreate(
            nil,
            CGImageGetWidth(self.CGImage),
            CGImageGetHeight(self.CGImage),
            CGImageGetBitsPerComponent(self.CGImage),
            CGImageGetBytesPerRow(self.CGImage),
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage) | CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        )
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
    // TODO:Move overlayView and activity indicator to center when zoomed - Fixed?
    // TODO:Shift grid based on image borders to align with pixels
    // TODO:Add percentage completion to activity indicator
    // TODO:Prevent overflow/underflow when shifting colors
    // TODO:Do computations in parallel
    
    
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
    private var originalColorComponents:(CGFloat, CGFloat, CGFloat) = (0,0,0)
    
    /**
    The maximum distance between the colors of the selected pixel and another pixel in the image to be selected for color shifting.
    */
    private var tolerance:CGFloat = 50
    
    var imageActivityIndicator: UIActivityIndicatorView!
    var progressIndicator:UIProgressView!
    var overlayView:UIView!
    
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
    @IBOutlet var shouldChangeMultiplePixels: UISwitch!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Load Image From File
        if let path = imagePath {
            image = UIImage(contentsOfFile: path.path!)
        }
        
        //Set Up imageView
        imageView.contentMode = .ScaleAspectFit
        if let viewImage = image {
            imageView.image = UIImage(CGImage: viewImage.CGImage)?.withAlphaLayerOfValue(255)
        }
        imageView.backgroundColor = UIColor.blackColor()
        
        
        //Set Up Navigation Bar
        self.navigationItem.title = "Pixel Editor"
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: "saveChanges")
        let revertButton = UIBarButtonItem(barButtonSystemItem: .Undo, target: self, action: "revertChanges")
        self.navigationItem.rightBarButtonItems = [saveButton, revertButton]
        let doneButton = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "didPressDone")
        self.navigationItem.leftBarButtonItem = doneButton
        
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
        self.automaticallyAdjustsScrollViewInsets = false
        
        //Select Initial Point
        selectColorAtPoint(selectedPoint)
        
        //Set Slider Initial Values
        componentSliders[0].value = Float(redComponent)
        componentSliders[1].value = Float(greenComponent)
        componentSliders[2].value = Float(blueComponent)
        componentSliders[3].value = Float(alphaComponent)
        
        //Set Up Slider Labels
        for sliderIndex in 0..<componentSliders.count {
            componentValueLabels[sliderIndex].text = "\(componentSliders[sliderIndex].value.description)"
        }
        
        //Set Up Progress Indicator
        progressIndicator = UIProgressView(progressViewStyle: .Default)
        
        //Set Up Activity Indicator
        imageActivityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .White)
        
        //Set Up Overlay View For Activity Indicator
        overlayView = UIView(frame: scrollView.frame)
        overlayView.opaque = false
        overlayView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        overlayView.addSubview(progressIndicator)
        overlayView.addSubview(imageActivityIndicator)
        
        //Finished Loading
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
    IBAction Methods
    */
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
        if shouldChangeMultiplePixels.on {
            ///TODO: Check if this is correct way of using threads.
            imageActivityIndicator.hidden = false
            NSThread.detachNewThreadSelector("shouldStartAnimatingIndicator", toTarget: self, withObject: nil)
            imageActivityIndicator.startAnimating()
            let label = "pixelEditorQueue"
            var newQueue = dispatch_queue_create(label, DISPATCH_QUEUE_SERIAL)
            dispatch_async(newQueue) {
                let pointsToChange = self.findPixelsToChange()
                let difference = (self.redComponent -  self.originalColorComponents.0, self.greenComponent - self.originalColorComponents.1, self.blueComponent - self.originalColorComponents.2, CGFloat(0))
                println("[Pixel Editor]Began shifting pixels...")
                let newImage = self.imageView.image?.shiftPixelColors(pointsToChange, byValues: difference, updateProgress: self.updateProgressIndicator)
                println("[Pixel Editor]Ended shifting pixels...")
                dispatch_sync(dispatch_get_main_queue()) {
                    self.imageView.image = newImage
                    self.selectColorAtPoint(self.selectedPoint)
                    self.shouldStopAnimatingIndicator()
                }
            }
        } else {
            imageView.image = imageView.image?.changePixelColor(selectedPoint, withData: (redComponent, greenComponent, blueComponent, alphaComponent))
        }
    }
    
    @IBAction func didChangeToleranceSlider(sender: UISlider) {
        tolerance = CGFloat(sender.value)
        toleranceLabel.text = sender.value.format("2")
    }
    
    
    /**
    Translates coordinates from the coordinates in the image of the UIImageView to the pixel coordinates of the image.
    
    :param: point The coordinates of the point within the image of the UIImageView.
    :returns: The pixel coordinates for the original image.
    */
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
    
    /**
    Translates the coordinates within the UIImageView to coordinates within the displayed image of the UIImageView.
    
    :param: point The coordinates of the point within the UIImageView.
    :returns: The coordinates of the point within the displayed image of the UIImageView.
    */
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
            
            scrollView.imageXOffset = widthMargin
            scrollView.imageYOffset = heightMargin
            
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
    
    
    /**
    Determines the scalar value by which the size of the image was multiplied to produce the image which is displayed within the UIImageView.
    */
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
    
    
    /**
    Method called when the UIActivityIndicatorView and corresponding OverlayView should be removed from the display. This method also re-enables the use of the component sliders and tolerance slider.
    */
    func shouldStopAnimatingIndicator() {
        overlayView.removeFromSuperview()
        imageActivityIndicator.stopAnimating()
        for slider in componentSliders {
            slider.enabled = true
        }
        toleranceSlider.enabled = true
    }
    
    
    /**
    Method called when the UIActivityIndicatorView and corresponding OverlayView should be displayed to the user. This method also disables the use of the component sliders and tolerance slider.
    */
    func shouldStartAnimatingIndicator() {
        ///TODO: Improve UIProgressView progress updates to better match actual progress.
        imageActivityIndicator.frame = CGRect(centerX: scrollView.frame.width/2, centerY: scrollView.frame.height/2, rectWidth: imageActivityIndicator.frame.width, rectHeight: imageActivityIndicator.frame.height)
        progressIndicator.frame = CGRect(x: scrollView.frame.width/2 - scrollView.frame.width/4, y: scrollView.frame.height/2 + imageActivityIndicator.frame.height, width: scrollView.frame.width/2, height: progressIndicator.frame.height)
        progressIndicator.progress = 0
        overlayView.frame = scrollView.frame
        for slider in componentSliders {
            slider.enabled = false
        }
        toleranceSlider.enabled = false
        self.view.addSubview(overlayView)
        imageActivityIndicator.startAnimating()
    }
    
    
    /**
    Sets the center of the UIImageView to be at the center of the PixelScrollView
    */
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
    
    
    /**
    Finds the color of the pixel at a point and updates the component sliders and CircleColorView to reflect the color of the selected pixel.
    
    :param: realCoords The pixel coordinates within the original image of the UIImageView.
    */
    private func updateComponentValuesAtPoint(realCoords:CGPoint) {
        if let pixelInfo = imageView.image?.getPixelColor(realCoords) {
            originalColorComponents = (pixelInfo.0, pixelInfo.1, pixelInfo.2)
            
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
    
    /**
    Initializes a new UIColor instance using the currently selected red, green, blue and alpha components, which it then uses as the fill color for the CircleColorView.
    */
    func updateViewColor() {
        let newColor = UIColor(redComp: redComponent, greenComp: greenComponent, blueComp: blueComponent, alpha: alphaComponent/255)
        selectedColorView.fillColor = newColor
        //selectedColorView.alpha = alphaComponent
        selectedColorView.setNeedsLayout()
    }
    
    
    /**
    Updates the CircleColorView and component sliders to match the color at the passed point.
    
    :param: point The coordinates within the imageView which should be selected.
    */
    private func selectColorAtPoint(point:CGPoint) {
        if let currentImage = image {
            if let coords = getPhotoCoordinatesFromImageViewCoordinates(point) {
                //coordsLabel.text = "\(Int(coords.x))X\(Int(coords.y))"
                println("[Pixel Editor]Selected color at point (\(Int(coords.x)), \(Int(coords.y)))")
                if let realCoords = getOriginalPhotoCoordinatesFromPhotoCoordinates(coords) {
                    coordsLabel.text! = "\(Int(realCoords.x))X\(Int(realCoords.y))"
                    selectedPoint = realCoords
                    updateComponentValuesAtPoint(realCoords)
                }
            }
            
        }
    }
    
    
    /**
    Sets the UIImageView image to the original image loaded from the file system.
    */
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
    
    
    /**
    Asks the user whether they would like to exit the pixel editor. It presents a warning that unsaved data will be lost.
    */
    func didPressDone() {
        let saveAlert = UIAlertController(title: "Warning", message: "All unsaved changes will be lost! Are you sure you would like to exit the editor?", preferredStyle: .Alert)
        saveAlert.addAction(UIAlertAction(title: "Yes", style: .Default) {
            s1 in
            self.navigationController?.popViewControllerAnimated(true)
            })
        saveAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(saveAlert, animated: true, completion: nil)
    }
    
    
    /**
    Overwrites the image file located at the file path with the edited version contained within the UIImageView.
    */
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
    
    
    /**
    Compares the component differential for each pixel to the user defined tolerance and selects which pixels should be included in the color shift.
    
    If the component differential between the original color of the selected pixel and the color of the pixel being scrutinized is less than the tolerance set by the user, it is added to the array returned by the method. Otherwise, the point is not included.
    
    :returns: An array of CGPoints which represent pixels within the image to be altered.
    */
    private func findPixelsToChange()-> [CGPoint] {
        var colors:[CGPoint] = []
        var colorData:(CGFloat, CGFloat, CGFloat, CGFloat) = (0,0,0,0)
        for xCoor in 0..<Int(imageView.image!.size.width) {
            for yCoor in 0..<Int(imageView.image!.size.height) {
                colorData = imageView.image!.getPixelColor(CGPoint(x: xCoor, y: yCoor))
                if componentDifferentialFrom(originalColorComponents, toComponents: (colorData.0, colorData.1, colorData.2)) < tolerance {
                    colors += [CGPoint(x: xCoor, y: yCoor)]
                }
            }
        }
        return colors
    }
    
    
    /**
    Computes the distance between two colors in the RGB color space using their respective components.
    
    :param: original A tuple containing the red, green and blue components of the original color.
    :param: toComponents A tuple containg the red, green and blue components of the second color.
    :returns: The distance between the two colors in the RGB color space.
    */
    private func componentDifferentialFrom(original:(CGFloat, CGFloat, CGFloat), toComponents:(CGFloat, CGFloat, CGFloat)) -> CGFloat {
        return sqrt(pow(toComponents.0 - original.0, 2) + pow(toComponents.1 - original.1, 2) + pow(toComponents.2 - original.2, 2))
    }
    
    
    /**
    Changes the UIProgressView progress property to the newValue passed.
    
    :param: newValue The new value to set the progress property of the UIProgressView with.
    */
    private func updateProgressIndicator(newValue:Float) {
        dispatch_sync(dispatch_get_main_queue()) {
            self.progressIndicator.setProgress(newValue, animated: true)
        }
        
    }
    
    
    /*
    ScrollViewDelegate Methods
    */
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView!, atScale scale: CGFloat) {
        self.scrollView.imageViewBounds = imageView.bounds
        self.scrollView.shouldResizeGrid = true
        scrollView.setNeedsLayout()
    }
    
    
    /*
    Gesture Recognizer Methods
    */
    func processTap() {
        println("[Pixel Editor]Single tap detected.")
        if let isInScrollViewCheck = tapGestureRecognizer?.locationInView(scrollView) {
            if let location = tapGestureRecognizer?.locationInView(imageView) {
                selectColorAtPoint(location)
            }
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
    
    
    /*
    Touch Methods
    */
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        let points = touches as? Set<UITouch>
        if let point = points?.first?.locationInView(scrollView) {
            selectColorAtPoint(point)
        }
        
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
