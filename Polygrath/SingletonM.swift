//
//  SingletonM.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/10/27.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import Foundation
import Photos
import AVKit
import FBSDKMessengerShareKit
import FBSDKShareKit

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
    
    func saveVideoToCameraRoll(url: NSURL, completion: ((identifier: NSString, newUrl: NSURL) -> Void)?) {
        
        var identifier: NSString?
        var assetPlaceholder: PHObjectPlaceholder!
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
            //create album and save video
            
            if let collection = self.createAlbum() {
                
                let asset = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)!
                assetPlaceholder = assetRequest.placeholderForCreatedAsset!
                let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: collection, assets: asset)
                albumChangeRequest?.addAssets([assetPlaceholder])
            }else {
                print("can't create album")
                
            }
            }) { (success, error) -> Void in
                
                if success {
                    
                    identifier = assetPlaceholder.localIdentifier
                    print("save video success, identifier: \(identifier)")
                    let uuid = identifier!.substringToIndex(36)
                    let stringURL = "assets-library://asset/asset.MOV?id=\(uuid)&ext=MOV"
                    let newUrl = NSURL(string: stringURL)!
                    completion?(identifier: identifier!, newUrl: newUrl)
                    
                }else {
                    print("can't save video")
                }
                print(error)
        }
        
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
    
//CIImage func
    func createTextCIImage(text: String, font: UIFont) -> CIImage {
        
        // setting attr: font name, color, alignment...etc.
        //shadow
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.lightTextColor()
        shadow.shadowOffset = CGSizeMake (0.2, 0.4)
        shadow.shadowBlurRadius = 1
        //alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        //create attribute
        let attr = [NSFontAttributeName: font, NSForegroundColorAttributeName:UIColor.redColor(), NSParagraphStyleAttributeName : paragraphStyle, NSKernAttributeName : 0.0, NSShadowAttributeName: shadow]
        
        //calculate width and height
        let sizeOfText = text.sizeWithAttributes(attr)
        
        //drawing to context
        UIGraphicsBeginImageContextWithOptions(CGSize(width: sizeOfText.width, height: sizeOfText.height), false, 0)
        let wordStamp = NSMutableAttributedString(string: text, attributes: attr)
        wordStamp.drawInRect(CGRectMake(0, 0, sizeOfText.width, sizeOfText.height))
        
        // getting an image from it
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        
        return CIImage(CGImage: newImage.CGImage!)
    }
    
    func drawCIImageOnSource(sourceImage: CIImage, addCIImage: CIImage?, center: CGPoint, halfWidth: CGFloat, halfHeight: CGFloat, shrinkPortion: CGFloat, xbias: CGFloat, ybias: CGFloat) -> CIImage {
        
        //transffer
        if var addOnImage = addCIImage {
            //rotate addon image
            let t = CGAffineTransformMakeRotation(CGFloat((M_PI / 2.0)))
            addOnImage = addOnImage.imageByApplyingTransform(t)
            
            //reverse X, Y
            let boundHalfWidth = halfHeight * shrinkPortion
            let boundHalfHeight = halfWidth * shrinkPortion
            let newCenter = CGPoint(x: center.y * shrinkPortion + ybias, y: center.x * shrinkPortion + xbias)
            
            let filter = CIFilter(name: "CIPerspectiveTransform")
            let topleft = CIVector(x: newCenter.x - boundHalfWidth, y: newCenter.y + boundHalfHeight)
            let topright = CIVector(x: newCenter.x + boundHalfWidth, y: newCenter.y + boundHalfHeight)
            let btmright = CIVector(x: newCenter.x + boundHalfWidth, y: newCenter.y - boundHalfHeight)
            let btmleft = CIVector(x: newCenter.x - boundHalfWidth, y: newCenter.y - boundHalfHeight)
            
            //let setting: [String: AnyObject] = ["inputImage" : oringinalImage, "inputTopLeft": btmleft, "inputTopRight": topleft, "inputBottomRight": topright, "inputBottomLeft": btmright]
            let setting: [String: AnyObject] = ["inputImage" : addOnImage, "inputTopLeft": topleft, "inputTopRight": topright, "inputBottomRight": btmright, "inputBottomLeft": btmleft]
            filter?.setValuesForKeysWithDictionary(setting)
            let modifyAddOnImage = filter?.outputImage
            
            //combine to background
            return modifyAddOnImage!.imageByCompositingOverImage(sourceImage)
        }else {
            return sourceImage
        }
    }
    
    func rotateCGImageByDeviceOrientation(inputImage: CIImage, biasDegree: Double) -> CIImage {
        //depends on device rotate
        let orientation = UIDevice.currentDevice().orientation
        let biasRadian = biasDegree * M_PI / 180.0
        var t: CGAffineTransform!
        if orientation == UIDeviceOrientation.Portrait {
            t = CGAffineTransformMakeRotation(CGFloat((-M_PI / 2.0) + biasRadian))
        } else if orientation == UIDeviceOrientation.PortraitUpsideDown {
            t = CGAffineTransformMakeRotation(CGFloat((M_PI / 2.0) + biasRadian))
        } else if (orientation == UIDeviceOrientation.LandscapeRight) {
            t = CGAffineTransformMakeRotation(CGFloat(M_PI + biasRadian))
        } else {
            t = CGAffineTransformMakeRotation(CGFloat(0 + biasRadian))
        }
        
        return inputImage.imageByApplyingTransform(t)
    }
    

//Calculation
    func getMin(values: [Double]) -> Double {
        var min:Double = 200
        for value in values {
            if value < min && value != 0 {
                min = value
            }
        }
        return min
    }
    
    func getMax(values: [Double]) -> Double {
        var max:Double = 0
        for value in values {
            if value > max {
                max = value
            }
        }
        return max
    }
    
    func getAverage(nums: [Double]) -> Double {
        var total = 0.0
        //use the parameter-array instead of the global variable votes
        for vote in nums{
            total += Double(vote)
        }
        let votesTotal = Double(nums.count)
        let avg = total / votesTotal
        
        print("calculate average: \(avg)")
        return avg
    }
    
    func getStandardDeviation(arr : [Double]) -> Double {
        let length = Double(arr.count)
        let avg = arr.reduce(0, combine: {$0 + $1}) / length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, combine: {$0 + $1})
        let dev = sqrt(sumOfSquaredAvgDiff / length)
        
        print("calculate deviation: \(dev)")
        return dev
    }
    
    
//play video
    
    
    
    
//sound effect
    var audioPlayer = AVAudioPlayer()
    let heartSound = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("heartbeat", ofType: "mp3")!)
    
    func setupAudioPlayer() {
        do {
            try audioPlayer = AVAudioPlayer(contentsOfURL: heartSound, fileTypeHint: nil)
            audioPlayer.prepareToPlay()
        }catch {
            print("can't play heart beat sound effect")
            print(error)
        }
    }
    
    func playHeartBeatEffect() {
        self.stopPlayingEffect()
        do {
            print(self.heartSound)
            try audioPlayer = AVAudioPlayer(contentsOfURL: heartSound, fileTypeHint: AVFileTypeMPEGLayer3)
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            print("play heart beat sound effect")
        }catch {
            print("can't play heart beat sound effect")
            print(error)
        }
    }
    
    func stopPlayingEffect() {
        
        if self.audioPlayer.playing {
            self.audioPlayer.stop()
        }
    }
    

//facebook
    func shareVideoToMessenger(url: NSURL) {
        if let videoData = NSData(contentsOfURL: url) {
            FBSDKMessengerSharer.shareVideo(videoData, withOptions: nil)
        }
    }
    
    func shareVideoToMessengerAndCameraRoll(url: NSURL, completion: ((url: NSURL) -> Void )?) {
        if let videoData = NSData(contentsOfURL: url) {
            self.saveVideoToCameraRoll(url, completion: { (identifier, newUrl) -> Void in
                //save to question
                completion?(url: newUrl)
                
                //share to messenger
                FBSDKMessengerSharer.shareVideo(videoData, withOptions: nil)
            })
        }
    }
    
    func shareVideoToFacebook(assetURL: NSURL, targetVC: UIViewController) {
        let video = FBSDKShareVideo()
        video.videoURL = assetURL
        let content = FBSDKShareVideoContent()
        content.video = video
        
        //perfrom dialog
        let dialog = FBSDKShareDialog()
        dialog.shareContent = content
        dialog.fromViewController = targetVC
        dialog.mode = FBSDKShareDialogMode.Native
        dialog.show()
    }
    
    func shareVideoToFacebookAndCameraRoll(url: NSURL, targetVC: UIViewController, completion: ((newURL: NSURL) -> Void )?) {
        self.saveVideoToCameraRoll(url) { (identifier, newUrl) -> Void in
            print("share video to facebook: \(newUrl)")
            //save to question
            completion?(newURL: newUrl)
            
            //facebook func
            self.shareVideoToFacebook(newUrl, targetVC: targetVC)
        }
    }

    
    
    
    
}