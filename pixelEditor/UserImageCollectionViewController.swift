//
//  UserImageCollectionViewController.swift
//  pixelEditor
//
//  Created by Anders Boberg on 2/27/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit
import AVFoundation

extension String {
    func removeChar(character:Character)->String {
        let components = self.componentsSeparatedByString("\(character)")
        var outputString = ""
        for component in components {
            outputString += component
        }
        return outputString
    }
}

let reuseIdentifier = "imageCell"

class UserImageCollectionViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private var baseDirectory:NSURL?
    private var photoDirectory:NSURL?
    private var photoPaths:[NSURL:UIImage?] = [:]
    private var selectedPath:Int?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fileManager = NSFileManager()
        
        //Setting Base Path URL
        let directories = NSSearchPathForDirectoriesInDomains(.DocumentDirectory , .UserDomainMask, true)
        let documentDirectory = directories[0] as! String
        baseDirectory = NSURL(fileURLWithPath: documentDirectory, isDirectory: true)!
        
        //Locate/Create Video Folder
        let fileEnum = fileManager.enumeratorAtURL(baseDirectory!, includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants, errorHandler: nil)
        while let file = fileEnum?.nextObject() as? NSURL {
            if file.lastPathComponent == "Photos" {
                photoDirectory = file
                println("[Status]Located Photos directory at \(file)")
            }
        }
        if photoDirectory == nil {
            var err:NSError?
            let newURL = NSURL(string: "Photos", relativeToURL: baseDirectory!)
            fileManager.createDirectoryAtURL(newURL!, withIntermediateDirectories: false, attributes: nil, error: &err)
            if let error = err {
                println("[Error]\(error)")
            } else {
                println("[Status]Created new Photos directory")
                photoDirectory = newURL!
            }
        }
        
        //Locate Photos Within Photo Directory
        reloadImagePaths()
        

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
        collectionView?.backgroundColor = UIColor.whiteColor()
        
    }
    
    func loadImagesFromFile() {
        for (path, image) in photoPaths {
            if image == nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.photoPaths[path] = UIImage(contentsOfFile: path.path!)
                    let indexPath = NSIndexPath(forRow: find(photoPaths.keys.array, path)!, inSection: 0)
                    self.collectionView?.reloadItemsAtIndexPaths([indexPath])
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        reloadImagePaths()
        collectionView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func testPicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    private func reloadImagePaths() {
        let fileManager = NSFileManager()
        var newPaths:[NSURL:UIImage?] = [:]
        let photoEnum = fileManager.enumeratorAtURL(photoDirectory! , includingPropertiesForKeys: nil, options: .SkipsSubdirectoryDescendants, errorHandler:nil)
        while let file = photoEnum?.nextObject() as? NSURL {
            if file.lastPathComponent!.hasSuffix("png") {
                if !contains(photoPaths.keys, file) {
                    newPaths.updateValue(nil, forKey: file)
                    println("[Status]New photo located at \(file)")
                } else {
                    newPaths.updateValue(photoPaths[file]!, forKey: file)
                }
            }
        }
        photoPaths = newPaths
        loadImagesFromFile()
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
        reloadImagePaths()
        collectionView?.reloadData()
    }
    
    private func deleteImageAtPath(path:NSURL) {
        let fileManager = NSFileManager()
        var err:NSError?
        fileManager.removeItemAtURL(path, error: &err)
        if let error = err {
            println("[Error]\(error)")
        }
        reloadImagePaths()
        collectionView?.reloadData()
    }

    @IBAction func didPressImportPhoto(sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let popover = UIPopoverController(contentViewController: imagePicker)
            popover.presentPopoverFromBarButtonItem(sender, permittedArrowDirections: .Any, animated: true)
        } else {
            self.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
        
        //self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if let destinationViewController = segue.destinationViewController as? PhotoViewController {
            destinationViewController.imagePath = photoPaths.keys.array[selectedPath!]
        } else if let destinationViewController = segue.destinationViewController as? CameraViewController {
            destinationViewController.photoDirectory = photoDirectory
        }
        
        
        
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return photoPaths.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell
    
        // Configure the cell
        let imageView = cell.viewWithTag(2) as? UIImageView
        let paths = photoPaths.keys.array
        if let image = photoPaths[paths[indexPath.row]] {
            if image != nil {
                imageView?.image = image
            } else {
                imageView?.image = UIImage(named: "TestImage")
            }
        } else {
            imageView?.image = UIImage(named: "TestImage")
        }
        
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }


    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }


    
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        selectedPath = indexPath.row
        var photoView = self.storyboard?.instantiateViewControllerWithIdentifier("photoView") as? PhotoViewController
        photoView?.imagePath = photoPaths.keys.array[indexPath.row]
        self.showViewController(photoView!, sender: self)
    }
    
    
    
    //Image Picker Delegate Methods
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        let newImage = info[UIImagePickerControllerOriginalImage] as? UIImage
        saveImage(newImage!, withName: NSDate().description.removeChar(" ").removeChar(":").removeChar("+"))
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    

}
