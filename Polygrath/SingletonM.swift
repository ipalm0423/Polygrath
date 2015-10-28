//
//  SingletonM.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/10/27.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import Foundation
import Photos

class Singleton: NSObject {
    class var sharedInstance: Singleton {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var instance: Singleton? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.instance = Singleton()
        }
        return Static.instance!
    }
    
//file func
    func getFileSize(url: NSURL) -> NSNumber {
        var size:NSNumber = 0
        do{
            print(url)
            let fileAttributes = try NSFileManager.defaultManager().attributesOfItemAtPath(url.path!)
            size = fileAttributes[NSFileSize] as! NSNumber
            print("file size: \(size)")
        }catch {
            //error handling
            print(error)
        }
        return size
    }
    
    func getNewFileURL() -> NSURL {
        //Get the place to store the recorded file in the app's memory
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as NSString
        dirPath.stringByAppendingPathComponent("temp")
        //add time component
        let currentDateTime = NSDate();
        let formatter = NSDateFormatter();
        formatter.dateFormat = "ddMMyyyy-HHmmss";
        let recordingVideoName = formatter.stringFromDate(currentDateTime)+".mov"
        //let recordingAudioName = formatter.stringFromDate(currentDateTime) + ".m4a"
        //path
        let pathVideo = dirPath.stringByAppendingPathComponent(recordingVideoName)
        //let pathAudio = dirPath.stringByAppendingPathComponent(recordingAudioName)
       
        
        //Name the file with date/time to be unique
        //create temp folder
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(String(dirPath)) {
            //exist old folder, check duplicate file
            self.removeFileFromURL(NSURL.fileURLWithPath(pathVideo))
            //self.removeFileFromURL(NSURL.fileURLWithPath(pathAudio))
            
        }else {
            //create folder temp
            do {
                print("create temp fold for save video")
                try fileManager.createDirectoryAtPath(String(dirPath), withIntermediateDirectories: false, attributes: nil)
            }catch {
                print(error)
            }
        }
        print("create url: \(recordingVideoName)")
        
        return NSURL.fileURLWithPath(pathVideo)
    }
    
    
    func removeAllVideoTemp() {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0] as String
        let url = NSURL.fileURLWithPathComponents([dirPath, "temp"])!
        self.removeFileFromURL(url)
        print("delete all temp video")
    }
    
    func removeFileFromURL(url: NSURL) {
        let filemanager = NSFileManager.defaultManager()
        if filemanager.fileExistsAtPath(url.path!) {
            do {
                try filemanager.removeItemAtURL(url)
            }catch {
                print("error with delete file")
            }
        }
    }
    
    
//photo func
    
    func findAlbumAssetCollection(title: String) -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", title)
        
        if let collection = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: fetchOptions).firstObject as? PHAssetCollection {
            print("finded collection: \(title)")
            return collection
        }else {
            print("cant find collection: \(title)")
            return nil
        }
    }
    
    func createAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "PolyGraph")
        var collection : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let first_obj = collection.firstObject as? PHAssetCollection {
            //already exist, return object
            print("PolyGraph collection alreay exist")
            return first_obj
        }else {
            //didn't exist, create one
            print("Create new collection : PolyGraph")
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("PolyGraph")
                let assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                
                }, completionHandler: { success, error in
                    if success {
                        print("create success")
                        collection = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
                    }
            })
        }
        return collection.firstObject as! PHAssetCollection?
    }
    
    func saveVideoToCameraRoll(url: NSURL) -> Bool {
        var isSave = false
        var haveAlbum = false
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            //create album and save video
            if let collection = self.createAlbum() {
                haveAlbum = true
                let asset = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
                
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)!
                let assetPlaceholder = assetRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: collection, assets: asset)
                albumChangeRequest?.addAssets([assetPlaceholder!])
            }else {
                print("can't create album")
            }
            }) { (success, error) -> Void in
                isSave = success
                if isSave && haveAlbum {
                    print("save video success")
                }else {
                    print("can't save video")
                }
                print(error)
        }
        return (isSave && haveAlbum)
    }
    
    
//CALayer func
    func createTextCALayer(text: String, uiFont: UIFont, color: UIColor, width: CGFloat, x: CGFloat, y: CGFloat) -> CALayer {
        
        //create
        let subtitle = CATextLayer()
        subtitle.frame  = CGRectMake(x, y, width, uiFont.pointSize)
        subtitle.contentsScale = UIScreen.mainScreen().scale
        
        //attribute
        subtitle.wrapped = true
        subtitle.string = text
        subtitle.alignmentMode = kCAAlignmentCenter
        subtitle.foregroundColor = color.CGColor
        //font
        let fontName: CFStringRef = uiFont.fontName as CFStringRef
        let fontRef: CGFontRef = CGFontCreateWithFontName(fontName)!
        subtitle.font = fontRef
        subtitle.fontSize = uiFont.pointSize
        
        return subtitle
    }
    
    func createUIImageCALayer(image: UIImage, width: CGFloat, height: CGFloat, x: CGFloat, y: CGFloat) -> CALayer {
        let newLayer = CALayer()
        newLayer.contents = image.CGImage
        newLayer.frame = CGRectMake(x, y, width, height)
        newLayer.masksToBounds = true
        
        return newLayer
    }
    
}