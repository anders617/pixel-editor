//
//  CameraViewController.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/4/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit
import AVFoundation

extension CGRect {
    init(centerX:CGFloat, centerY: CGFloat, rectWidth: CGFloat, rectHeight: CGFloat) {
        let minimumX = centerX - rectWidth/2
        let minimumY = centerY - rectHeight/2
        self.init(x: minimumX, y: minimumY, width: rectWidth, height: rectHeight)
    }
}

class CameraViewController: UIViewController {
    
    private let captureSession = AVCaptureSession()
    private var captureDevice:AVCaptureDevice?
    private var videoCaptureDevices:[AVCaptureDevice] = []
    private var currentCaptureDeviceOutput:AVCaptureStillImageOutput?
    private var captureDeviceIndex = 0
    private var currentCaptureDeviceInput:AVCaptureDeviceInput?
    var photoDirectory:NSURL?
    private var previewLayer:AVCaptureVideoPreviewLayer?
    
    @IBOutlet var shutterButton: UIButton!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var switchCameraButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        
        //Setting Initial Button Settings
        
        
        
        
        if AVCaptureDevice.devices().count > 0 {
            println("[Event]Beginning capture session!")
            beginSession()
            //Setting initial Orientation
            
            setOutputOrientationForOutput(currentCaptureDeviceOutput!, withOrientation: self.interfaceOrientation)
        } else {
            let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "showNoHardwareAlert", userInfo: nil, repeats: false)
            switchCameraButton.enabled = false
            shutterButton.enabled = false
        }
        
        
        
        
        
        println("[Status]Camera view has loaded")
    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    func showNoHardwareAlert() {
        let alert = UIAlertController(title: "No Camera", message: "Could not find a suitable camera to use.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: {s1 in println("[Error]No hardware input devices found.")}))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        var videoOrientation = getVideoOrientation(toInterfaceOrientation)
        previewLayer?.connection.videoOrientation = videoOrientation
        setOutputOrientationForOutput(currentCaptureDeviceOutput!, withOrientation: toInterfaceOrientation)
        if self.interfaceOrientation.isPortrait != toInterfaceOrientation.isPortrait {
            previewLayer?.frame = CGRect(x: 0, y: 0, width: self.view.frame.height, height: self.view.frame.width)
        }
        println("[Event]Orientation changed to \(toInterfaceOrientation)")
    }
    
    
    private func setOutputOrientationForOutput(output:AVCaptureStillImageOutput, withOrientation:UIInterfaceOrientation) {
        let videoOrientation = getVideoOrientation(withOrientation)
        for connection in output.connections as! [AVCaptureConnection] {
            connection.videoOrientation = videoOrientation
        }
    }
    
    private func getVideoOrientation(orientation:UIInterfaceOrientation)->AVCaptureVideoOrientation {
        var videoOrientation:AVCaptureVideoOrientation
        switch(orientation) {
        case .LandscapeLeft:
            videoOrientation = .LandscapeLeft
        case .LandscapeRight:
            videoOrientation = .LandscapeRight
        case .Portrait:
            videoOrientation = .Portrait
        case .PortraitUpsideDown:
            videoOrientation = .PortraitUpsideDown
        case .Unknown:
            videoOrientation = .Portrait
        }
        return videoOrientation
    }
    
    private func beginSession() {
        
        //Setting Capture Session Settings
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        
        //Finding AV Capture Device Inputs
        let devices = AVCaptureDevice.devices()
        for device in devices {
            if device.hasMediaType(AVMediaTypeVideo) {
                videoCaptureDevices += [device as! AVCaptureDevice]
            }
            println("[Status]Capture Device Found: \(device as? AVCaptureDevice)")
        }
        captureDevice = videoCaptureDevices.first
        
        //Adding Device Still Output
        currentCaptureDeviceOutput = AVCaptureStillImageOutput()
        captureSession.addOutput(currentCaptureDeviceOutput)
        if let output = currentCaptureDeviceOutput {
            //output.outputSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
        }
        
        //Adding Device Video Inputs
        var err : NSError? = nil
        currentCaptureDeviceInput = AVCaptureDeviceInput(device: captureDevice, error: &err)
        if err != nil {
            println("[Error]\(err?.localizedDescription)")
        }
        captureSession.addInput(currentCaptureDeviceInput)
        
        
        
        //Setting Preview Layer Settings
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.view.layer.insertSublayer(previewLayer, atIndex: 0)
        previewLayer?.frame = self.view.layer.frame
        previewLayer?.connection.videoOrientation = getVideoOrientation(self.interfaceOrientation)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        captureSession.startRunning()
        println("[Status]Capture session is running")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelWasPressed(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func shutterButtonWasPressed(sender: UIButton) {
        let cameraConnection = currentCaptureDeviceOutput?.connectionWithMediaType(AVMediaTypeVideo)
        currentCaptureDeviceOutput?.captureStillImageAsynchronouslyFromConnection(cameraConnection) {
            (pictureBuffer: CMSampleBuffer?, err:NSError?) in
            if (pictureBuffer == nil) || (err != nil) {
                println("[Error]Failed to capture picture correctly. \(err)")
            } else {
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(pictureBuffer)
                let finalImage = UIImage(data: imageData)
                let dateName = NSDate().description.removeChar(" ").removeChar(":").removeChar("+")
                if let newImage = finalImage {
                    self.saveImage(newImage, withName: dateName)
                }
            }
        }
    }
    
    @IBAction func switchWasPressed(sender: UIButton) {
        println("[Status]Switching cameras...")
        if ++captureDeviceIndex == videoCaptureDevices.count {
            captureDeviceIndex = 0
        }
        var err:NSError? = nil
        
        captureSession.beginConfiguration()
        
        captureSession.removeInput(currentCaptureDeviceInput)
        
        captureDevice = videoCaptureDevices[captureDeviceIndex]
        currentCaptureDeviceInput = AVCaptureDeviceInput(device: captureDevice, error: &err)
        captureSession.addInput(currentCaptureDeviceInput)
        
        captureSession.commitConfiguration()
        
        if let error = err {
            println("[Error]\(error)")
        }
        println("[Event]The camera was succesfully switched.")
        
    }
    private func saveImage(image:UIImage, withName: String) {
        let fileManager = NSFileManager()
        var imageData = UIImagePNGRepresentation(image)
        
        let imagePath = photoDirectory?.path?.stringByAppendingPathComponent("\(withName).png")
        if imageData.writeToFile(imagePath!, atomically: true) {
            println("[Status]Saved photo at location \(imagePath)")
        } else {
            println("[Error]Failed to save photo to location \(imagePath)")
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
