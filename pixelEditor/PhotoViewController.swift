//
//  PhotoViewController.swift
//  pixelEditor
//
//  Created by Anders Boberg on 3/4/15.
//  Copyright (c) 2015 Anders Boberg. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {

    @IBOutlet var photoView: UIImageView!
    var imagePath:NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let path = imagePath {
            self.navigationItem.title = "\(path.lastPathComponent!)"
        }
        
        let editButton = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "didPressEditButton")
        var rightBarButtons = self.navigationItem.rightBarButtonItems!
        rightBarButtons += [editButton]
        self.navigationItem.rightBarButtonItems = rightBarButtons
        
        
        photoView.contentMode = .ScaleAspectFit
        self.view.backgroundColor = UIColor.blackColor()
        
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        //Load image from file
        println("[Status]PhotoView loaded with path \(imagePath?.path)")
        loadPhotoFromPath()
    }
    
    private func loadPhotoFromPath() {
        var image:UIImage?
        if let path = imagePath {
            image = UIImage(contentsOfFile: path.path!)
        }
        photoView.image = image
        if let img = image {
            println("[Status]Loaded photo from \(imagePath?.path!) successfully")
        } else {
            println("[Error]Failed to load photo from \(imagePath?.path!)")
        }
    }
    
    private func deleteImageAtPath(path:NSURL) {
        let fileManager = NSFileManager()
        var err:NSError?
        fileManager.removeItemAtURL(path, error: &err)
        if let error = err {
            println("[Error]\(error)")
        } else {
            println("[Status]Deleted photo at path \(imagePath?.path!)")
        }
    }
    
    func didPressEditButton() {
        if let pixelEditor = self.storyboard?.instantiateViewControllerWithIdentifier("pixelEditor") as? PixelColorViewController {
            pixelEditor.imagePath = imagePath
            self.showViewController(pixelEditor, sender: self)
        }
    }
    
    @IBAction func didPressTrashButton(sender: UIBarButtonItem) {
        let deleteAlert = UIAlertController(title: "Delete Photo?", message: "Would you like to remove this photo?", preferredStyle: .Alert)
        deleteAlert.addAction(UIAlertAction(title: "Yes", style: .Destructive) {
            s1 in
            self.deleteImageAtPath(self.imagePath!)
            self.navigationController?.popViewControllerAnimated(true)
            })
        deleteAlert.addAction(UIAlertAction(title: "No", style: .Cancel, handler: nil))
        self.presentViewController(deleteAlert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
