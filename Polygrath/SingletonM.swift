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
    
//question
    var BPMmax: Double = 0
    var BPMmin: Double = 0
    var BPMAverage: Double = 0
    var BPMDeviation: Double = 0
    var totalTruthRate: Double? = 0
    var questions = [question]() {
        didSet{
            //progress data
            self.totalTruthRate = nil
            var truthScores = [Double]()
            for quest in self.questions {
                var i = 0
                if quest.dataValues.count > 0 {
                    quest.questIndex = i 
                    i++
                    //find min
                    quest.max = self.getMax(quest.dataValues)
                    //find max
                    quest.min = self.getMin(quest.dataValues)
                    //find average
                    quest.average = self.getAverage(quest.dataValues)
                    //find score
                    quest.score = self.getTruthRate(quest.dataValues, BPMAverage: self.BPMAverage, BPMDeviation: self.BPMDeviation)
                    quest.isTruth = quest.score > 0.5 ? true : false
                    
                    truthScores.append(quest.score)
                    print("truth score: \(truthScores)")
                }else {
                    //no data to process
                    quest.isTruth = nil
                    

                }
            }
            //calculate total truth rate
            if truthScores.count > 0 {
                self.totalTruthRate = self.getAverage(truthScores)
                
            }else {
                self.totalTruthRate = nil
            }
            NSNotificationCenter.defaultCenter().postNotificationName("questionReload", object: nil)
            
        }
    }
    

    
    
//color view
    
    func getBackgroundGradientLayer(frame: CGRect) -> CALayer {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = [UIColor(red: 24 / 255, green: 33 / 255, blue: 44 / 255, alpha: 1.0).CGColor, UIColor(red: 11 / 255, green: 37 / 255, blue: 78 / 255, alpha: 1.0).CGColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        return gradient
    }
    
    func getNaviBarGradientLayer(frame: CGRect) -> UIImage {
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = frame
        gradient.colors = [UIColor(red: 179 / 255, green: 5 / 255, blue: 19 / 255, alpha: 1.0).CGColor, UIColor(red: 229 / 255, green: 45 / 255, blue: 60 / 255, alpha: 1.0).CGColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: gradient.bounds.width, height: gradient.bounds.height), false, 0)
        let CTX = UIGraphicsGetCurrentContext()!
        gradient.renderInContext(CTX)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    func setupBackgroundGradientColor(VC: UIViewController) {
        //setup background color
        let gradientLayer = Singleton.sharedInstance.getBackgroundGradientLayer(VC.view.bounds)
        VC.view.layer.insertSublayer(gradientLayer, atIndex: 0)
        
    }
    
    func setupNaviBarColor(VC: ViewController) {
        //setup navi bar color
        if let bar = VC.navigationController?.navigationBar {
            print("navi color setup")
            let naviImage = Singleton.sharedInstance.getNaviBarGradientLayer(bar.bounds)
            bar.translucent = false
            let fontDictionary: [String: AnyObject] = [ NSForegroundColorAttributeName:UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0), NSFontAttributeName: UIFont(name: "HelveticaNeue", size: 24)! ]
            bar.titleTextAttributes = fontDictionary
            bar.tintColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0)
            bar.setBackgroundImage(naviImage, forBarMetrics: UIBarMetrics.Default)
        }
    }
    
//time func
    func getTimeString(startTime: NSDate, stopTime: NSDate) -> String {
        let intervalTime = stopTime.timeIntervalSinceDate(startTime)
        var timeText = NSDateComponentsFormatter().stringFromTimeInterval(intervalTime)!
        if intervalTime < 10 {
            timeText = "00:0" + timeText
        }else if intervalTime < 60 {
            timeText = "00:" + timeText
        }
        return timeText
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
    
    func saveVideoToCameraRoll(url: NSURL, completion: ((identifier: NSString, assetUrl: NSURL) -> Void)?) {
        
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
                    let assetUrl = NSURL(string: stringURL)!
                    completion?(identifier: identifier!, assetUrl: assetUrl)
                    
                }else {
                    print("can't save video")
                }
                print(error)
        }
        
    }
//CALayer key frame animation func
    func createCALayerStringAnimation(size: CGSize, font: UIFont,duration: NSTimeInterval, texts: [String], keyTimes: [NSNumber], repeatCount: Float , removeOnCompletion: Bool) -> CAKeyframeAnimation {
        //bug fix
        var imageArray = [CGImageRef]()
        for text in texts {
            imageArray.append(self.createCGImageText(text, font: font, size: size))
        }
        
        let stringAnimation = CAKeyframeAnimation(keyPath: "contents") //"string" have bug, so use contents
        stringAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
        stringAnimation.calculationMode = kCAAnimationDiscrete //kCAAnimationLinear
        stringAnimation.duration = duration
        stringAnimation.values = imageArray
        stringAnimation.keyTimes = keyTimes
        stringAnimation.repeatCount = repeatCount
        stringAnimation.removedOnCompletion = removeOnCompletion
        
        print("text: \(texts), key time: \(keyTimes), duration: \(duration)")
        
        return stringAnimation
    }
    
    func createCALayerScaleAnimation(period: NSTimeInterval, scales: [NSNumber], delay: CFTimeInterval, duration: NSTimeInterval, autoReverse: Bool, removeOnComplete: Bool) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.duration = period
        animation.values = scales //heart scale
        animation.autoreverses = autoReverse
        animation.repeatDuration = duration
        animation.removedOnCompletion = removeOnComplete
        animation.beginTime = AVCoreAnimationBeginTimeAtZero + delay
        
        return animation
    }
    
    
    
    
//CALayer func
    func createTextCALayer(text: String, uiFont: UIFont, color: UIColor, x: CGFloat, y: CGFloat) -> CALayer {
        //calculate width and height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center //alignment
        let attr = [NSFontAttributeName: uiFont, NSForegroundColorAttributeName:UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle] // [NSShadowAttributeName: shadow]
        let sizeOfText = text.sizeWithAttributes(attr)
        
        //create CALayer
        let subtitle = CATextLayer()
        subtitle.frame  = CGRectMake(x, y, sizeOfText.width, sizeOfText.height)
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
    
    func getWaterMarkLayer(size: CGSize) -> CALayer {
        //create CALayer
        let textColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0)
        let textLayer = self.createTextCALayer("Polygraph", uiFont: UIFont(name: "Helvetica-Bold", size: 18)!, color: textColor, x: 10, y: 10) //constraint = 10, 10
        
        //put into a size
        let overlayLayer = CALayer()
        overlayLayer.frame =  CGRect(x: 0, y: 0, width: size.width, height: size.height)
        overlayLayer.addSublayer(textLayer)
        overlayLayer.masksToBounds = true
        
        return overlayLayer
    }
    
    func getBPMLayerWithAnimation(questionNO: Int, parentViewSize: CGSize) -> CALayer {
        
        let quest = self.questions[questionNO]
        let textColor = UIColor(red: 242 / 255, green: 242 / 255, blue: 242 / 255, alpha: 1.0)
        let font = UIFont(name: "HelveticaNeue", size: 55)!
        let BPMLayer = self.createTextCALayer("---", uiFont: font, color: textColor, x: 0, y: 0)
        //set to parentview center (height bias +5)
        BPMLayer.frame = CGRectMake((parentViewSize.width - BPMLayer.bounds.width) / 2, (parentViewSize.height - BPMLayer.bounds.height + 10) / 2, BPMLayer.bounds.width, BPMLayer.bounds.height)
        
        //if have data, create animation
        if quest.dataValues.count > 0 {
            var BPMstring = [String]()
            //change data to string
            for data in quest.dataValues {
                BPMstring.append(Int(data).description)
            }
            //caculate time
            let duration = quest.endTime.timeIntervalSinceDate(quest.startTime)
            var keyTime = [NSNumber(double: 0.0)]
            for date in quest.dataDates {
                let interval = date.timeIntervalSinceDate(quest.startTime)
                let space = interval / duration
                print("start : \(quest.startTime), endtime: \(quest.endTime)")
                print("\(date) has interval: \(interval)")
                keyTime.append(space)
            }
            keyTime.append(NSNumber(double: 1.0))
            
            //setup animation
            let stringAnimation = self.createCALayerStringAnimation(BPMLayer.bounds.size, font: font, duration: duration, texts: BPMstring, keyTimes: keyTime, repeatCount: 1, removeOnCompletion: false)
            
            //add animation to layer
            BPMLayer.addAnimation(stringAnimation, forKey: "BPMstring")
        }else {
            //no data
            BPMLayer.opacity = 0
        }
        
        return BPMLayer
        
        
    }
    
    
    func getHeartBeatLayerWithAnimation(questionNO: Int, parentViewSize: CGSize) -> CALayer {
    
        let heartLayer = self.createUIImageCALayer(UIImage(named: "heart")!, width: 140, height: 120, x: parentViewSize.width / 2 - 70, y: parentViewSize.height / 2 - 60)
        var heartAnimation = [CAKeyframeAnimation]()
        let quest = self.questions[questionNO]
        var truthRate: Double = 1
        var halfPeriod: Double = 0
        var heartScaleRatio:NSNumber = 0
        
        //if have data, create animation
        if quest.dataValues.count > 0 {
            
            var i = 0
            
            var tempData = [Double]()
            for data in quest.dataValues {
                
                var duration: CFTimeInterval!
                halfPeriod = 60 / data / 2
                heartScaleRatio = NSNumber(double: data / 60)
                var delay:CFTimeInterval = 0
                tempData.append(data)
                
                //score calculate
                
                if i > 1 {
                    truthRate = self.getTruthRate(tempData, BPMAverage: self.BPMAverage, BPMDeviation: self.BPMDeviation)
                    //turth effect ratio
                    if truthRate < 0.3 {
                        heartScaleRatio = NSNumber(double: 1.2 * Double(heartScaleRatio)) // ratio = 1.2
                        halfPeriod = halfPeriod * 0.7
                    }else if truthRate < 0.5 {
                        heartScaleRatio = NSNumber(double: 1.1 * Double(heartScaleRatio)) // ratio = 1.2
                        halfPeriod = halfPeriod * 0.85
                    }
                }
                
                //time calculate
                if i == 0 {
                    //first data
                    duration = quest.dataDates[i].timeIntervalSinceDate(quest.startTime)
                    delay = 0
                }else {
                    //have previous data
                    duration = quest.dataDates[i].timeIntervalSinceDate(quest.dataDates[i - 1])
                    delay = quest.dataDates[i - 1].timeIntervalSinceDate(quest.startTime)
                }
                
                //create animation
                let animation = self.createCALayerScaleAnimation(halfPeriod, scales: [NSNumber(double: 1.0), heartScaleRatio], delay: delay, duration: duration, autoReverse: true, removeOnComplete: false)
                
                heartAnimation.append(animation)
                i++
            }
            
            //add last time
            let lastDuration = quest.endTime.timeIntervalSinceDate(quest.dataDates[i - 1])
            let lastDelay = quest.dataDates[i - 1].timeIntervalSinceDate(quest.startTime)
            let lastAnimation = self.createCALayerScaleAnimation(halfPeriod, scales: [NSNumber(double: 1.0), heartScaleRatio], delay: lastDelay, duration: lastDuration, autoReverse: true, removeOnComplete: false)
            
            heartAnimation.append(lastAnimation)
            
        }
        print("heart animation:\(heartAnimation)")
        
        //add animation
        var j = 0
        for animation in heartAnimation {
            heartLayer.addAnimation(animation, forKey: "heartbeat animation no.\(j)")
            j++
        }
        
        
        return heartLayer
    }
    
    
    
//CIImage func
    var frameCount = 0
    func drawAllAnimationInCIImage(width: CGFloat, height: CGFloat, bpm: Double, truthRate: Double, recordTime: NSDate?) -> CIImage? {
        frameCount++
        //Constraints
        let topConstraint:CGFloat = 20
        let sideConstraint:CGFloat = 30
        let truthText2HeartImage: CGFloat = 65
        let constraintHeartLineDown:CGFloat = 30
        let centerPoint = CGPoint(x: width / 2, y: height / 2)
        let topFont = UIFont(name: "HelveticaNeue", size: 18)!
        let midFont = UIFont(name: "HelveticaNeue", size: 50)!
        let heartLineHeight: CGFloat = 200
        
        //BPM text
        let BPMText = createTextString(Int(bpm).description, font: midFont)
        let sizeOfBPMText = BPMText.size()
        //time text
        
        var timeText: NSMutableAttributedString?
        if let startTime = recordTime {
            let timeString = getTimeString(startTime, stopTime: NSDate())
            timeText = createTextString(timeString, font: topFont)
        }
        let sizeOfTimeText = timeText?.size()
        
        //brand text
        let brandText = createTextString("Polygraph", font: topFont)
        let sizeOfBrandText = brandText.size()

        //truth label
        var truthText: NSMutableAttributedString?
        if truthRate < 0.5 {
            truthText = createTextString("\"untruth\"", font: topFont)
        }
        let sizeOfTruthText = truthText?.size()
        
        //heart line
        let heartLineLayer = createHeartLineLayer(bpm, frameCount: frameCount, width: width, height: heartLineHeight)
        
        //heart animate
        let heartRadius = getHeartRadius(bpm, truthRate: truthRate)
        let heartImage = UIImage(named: "heart-1")!
        
        
        
        
        //new a context and start drawing
        UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), false, 0)
        let CTX = UIGraphicsGetCurrentContext()!
        
        //TOP
        
        brandText.drawInRect(CGRect(x: sideConstraint, y: topConstraint, width: sizeOfBrandText.width, height: sizeOfBrandText.height))
        
        if let timetext = timeText {
            timetext.drawInRect(CGRectMake(width - sideConstraint - (sizeOfTimeText!.width / 2), topConstraint, sizeOfTimeText!.width, sizeOfTimeText!.height))
        }
        
        
        //MID
        //heart animate
        //heartImage.drawInRect(CGRect(x: centerPoint.x - (heartRadius * 1.1627), y: centerPoint.y - heartRadius, width: (heartRadius * 1.1627 ) * 2, height: heartRadius * 2))
        //BPM text
        //BPMText.drawInRect(CGRect(x: (width - sizeOfBPMText.width) / 2, y: (height - sizeOfBPMText.height) / 2 - 7, width: sizeOfBPMText.width, height: sizeOfBPMText.height))
        
        //truth text
        if let truthtext =  truthText {
            truthtext.drawInRect(CGRect(x: (width - sizeOfTruthText!.width) / 2, y: (height - sizeOfTruthText!.height) / 2 + truthText2HeartImage, width: sizeOfTruthText!.width, height: sizeOfTruthText!.height)) //bias 65 for heart image
        }

        //heart line
        CGContextTranslateCTM(CTX, 0, height - (heartLineHeight + constraintHeartLineDown)) // change CTM position
        heartLineLayer.renderInContext(UIGraphicsGetCurrentContext()!)
        
        
        // getting an image from it
        //let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()

        return nil
    }
    
    
    func getHeartRadius(bpm: Double, truthRate: Double) -> CGFloat {
        
        //time movement
        let period = 60 / bpm //seconds
        let percentage:CGFloat = CGFloat(abs(cos(Double(frameCount) * 0.0333 * M_PI / period))) //frame = 30/1 s
        //heart radius
        let range = CGFloat(bpm) * 0.3
        var heartRadius: CGFloat = 20 + (percentage) * range
        if truthRate < 0.5 {
            heartRadius = heartRadius * 1.2
        }
        
        return heartRadius
    }
    
    
    func createHeartLineLayer(bpm: Double, frameCount: Int, width: CGFloat, height: CGFloat) -> CALayer {
        print("create heart line from count: \(frameCount)")
        //constant
        let period = 60 / bpm //seconds
        let percentage = cos((Double(frameCount) * 0.03333) * (2 * M_PI) / period) //frame = 30/1 s
        var heartHeight = CGFloat(percentage * (bpm / 110)) * height // max bpm is 110
        print("percent: \(percentage)")
        
        //set view height as max line height
        if heartHeight > height / 2 {
            heartHeight = height / 2
        }
        
        let controlPoint1: CGPoint = CGPoint(x: width * 0.5, y: heartHeight)
        let controlPoint2: CGPoint = CGPoint(x: width * 0.5, y: -heartHeight)
        
        //set path
        let heartPath = UIBezierPath()
        heartPath.moveToPoint(CGPoint(x: 0, y: 0))
        heartPath.addCurveToPoint(CGPoint(x: width, y: 0), controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        heartPath.stroke()
        
        let arc = CAShapeLayer()
        arc.path = heartPath.CGPath
        arc.position = CGPoint(x: 0, y: height / 2)
        arc.fillColor = UIColor.clearColor().CGColor
        arc.strokeColor = UIColor.purpleColor().CGColor
        arc.lineWidth = 4
        arc.lineCap = kCALineCapRound ; //线条拐角
        arc.lineJoin = kCALineJoinRound
        
        //set gradient color
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        gradientLayer.colors = [UIColor.redColor().CGColor, UIColor.yellowColor().CGColor, UIColor.redColor().CGColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        gradientLayer.mask = arc
        gradientLayer.opacity = 0.8 //transparency
        return gradientLayer
    }
    
    
    func createTextString(text: String, font: UIFont) -> NSMutableAttributedString {
        
        // setting attr: font name, color, alignment...etc.
        /*
        //shadow
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.lightTextColor()
        shadow.shadowOffset = CGSizeMake (0.2, 0.4)
        shadow.shadowBlurRadius = 1
        */
        
        //alignment
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.Center
        //create attribute
        let attr = [NSFontAttributeName: font, NSForegroundColorAttributeName:UIColor.whiteColor(), NSParagraphStyleAttributeName : paragraphStyle, NSKernAttributeName : 0.0] // [NSShadowAttributeName: shadow]
        
        //calculate width and height
        //let sizeOfText = text.sizeWithAttributes(attr)
        
        return NSMutableAttributedString(string: text, attributes: attr)
    }
    
    func createCGImageText(text: String, font: UIFont, size: CGSize) -> CGImageRef {
        let string = self.createTextString(text, font: font)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        
        string.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext()
        return newImage.CGImage!
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
    

//video progress
    
    //oriented from transform
    func getOrientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        print("asset preference transferom is : \(transform)")
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    
    
    func getMediaCompositionOfURL(URL: NSURL) -> AVMutableComposition? {
        //new a composition. track
        let composition = AVMutableComposition()
        let videoTrack:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        let audioTrack:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        
        //get source video/audio tracks
        let sourceAsset = AVAsset(URL: URL)
        let tracks = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)
        let audios = sourceAsset.tracksWithMediaType(AVMediaTypeAudio)
        
        
        //input source video/audio
        if tracks.count > 0{
            print("get composition for tracks count: \(tracks.count)")
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: tracks[0], atTime: kCMTimeZero)
                
                print("get composition for size: \(videoTrack.naturalSize)")
                print("get composition for frame: \(videoTrack.nominalFrameRate)")
                
            }catch {
                print(error)
            }
        }
        if audios.count > 0{
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero,sourceAsset.duration), ofTrack: audios[0], atTime: kCMTimeZero)
            }catch {
                print(error)
            }
        }
        
        if tracks.count > 0 {
            
            return composition
        }
        
        return nil
    }
    
    func mixCompositionWithAnimationLayer(composition: AVMutableVideoComposition, size: CGSize, questNO: Int) {
        print("mix animation layer to video compostition: \(size)")
        //create  CALayer
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        let videoFrame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        parentLayer.frame = videoFrame
        videoLayer.frame = videoFrame
        
        //create watermark layer
        let watermarkLayer = self.getWaterMarkLayer(size)
        
        
        //create time label
        
        
        //create heart beat scale animation
        let heartBeatLayer = self.getHeartBeatLayerWithAnimation(questNO, parentViewSize: size)
        print("heart layer back animation: \(heartBeatLayer.animationKeys())")
        
        //create bpm label
        let BPMLayer = self.getBPMLayerWithAnimation(questNO, parentViewSize: size)
        
        //create heart line
        
        
        
        
        
        //input animation layer by postion
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(watermarkLayer)
        parentLayer.addSublayer(heartBeatLayer)
        parentLayer.addSublayer(BPMLayer)
        
        //add to tools
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
    }
    
    func exportAndSaveComposistion(composition: AVMutableComposition, mixVideoComposistion: AVMutableVideoComposition, completion: ((newURL: NSURL) -> Void)?) {
        var newURL = self.getNewFileURL()
        if let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            print("create new composition video: \(newURL)")
            exporter.outputURL = newURL
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = true
            //exporter.audioMix
            exporter.videoComposition = mixVideoComposistion
            
            exporter.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                print("export video success")
                completion?(newURL: newURL)
            })
        }
    }
    
    //main func
    func videoComposeWithQuestion(questionNO: Int) {
        print("start to compose video...")
        
        let url = self.questions[questionNO].file.URL
        let sourceAsset = AVAsset(URL: url)
        let assetTrack = sourceAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
        
        //create source composition and get the size
        if let sourceComposition = self.getMediaCompositionOfURL(url) {
            let videoTrack = sourceComposition.tracksWithMediaType(AVMediaTypeVideo)[0]
            
            //setup instruction
            let videoInstruction = AVMutableVideoCompositionInstruction()
            videoInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,sourceComposition.duration)
            let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack) //setup instruction layer
            
            //add rotate instruction layer
            let rotatePrefer = self.getOrientationFromTransform(assetTrack.preferredTransform)
            var concat = CGAffineTransformConcat((assetTrack.preferredTransform), CGAffineTransformMakeTranslation(assetTrack.naturalSize.height, 0))
            videoLayerInstruction.setTransform(concat, atTime: kCMTimeZero)
            videoInstruction.layerInstructions = [videoLayerInstruction]
            
        //create video composition for animation, rotate
            let videoComposition = AVMutableVideoComposition()
            videoComposition.frameDuration = CMTimeMake(1, 30)
            var videoRotateSize = CGSize() //roate by orientation
            //render size with orientation
            print("rotate status: \(rotatePrefer)")
            if rotatePrefer.isPortrait {
                videoRotateSize = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.width)
            }else {
                videoRotateSize = CGSizeMake(assetTrack.naturalSize.width, assetTrack.naturalSize.height)
            }
            print("after rotate size: \(videoRotateSize)")
            videoComposition.renderSize = videoRotateSize
            
            //add instrucion to composition
            videoComposition.instructions = [videoInstruction]
            
            //add animation CALayer
            self.mixCompositionWithAnimationLayer(videoComposition, size: videoRotateSize, questNO: questionNO)
            
            self.exportAndSaveComposistion(sourceComposition, mixVideoComposistion: videoComposition, completion: { (newURL) -> Void in
                print("SAVE compose to question. \(questionNO), and post a notify")
                //save to singleton
                let file = self.questions[questionNO].file
                file.isProcess = true
                file.assetURL = newURL
                //notify
                
                NSNotificationCenter.defaultCenter().postNotificationName("videoCompose", object: nil, userInfo: ["index" : questionNO, "newURL": newURL])
            })
        }
    }
    
    
    
//Calculation
    func getRamdom(maxDice: UInt32) -> Double {
        let diceRoll = (Double(arc4random_uniform(maxDice) + 1))
        return diceRoll
    }
    
    func getMin(values: [Double]) -> Double {
        if values.count == 0 {
            return 0
        }
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
        if arr.count == 0 {
            return 0
        }
        let length = Double(arr.count)
        let avg = arr.reduce(0, combine: {$0 + $1}) / length
        let sumOfSquaredAvgDiff = arr.map { pow($0 - avg, 2.0)}.reduce(0, combine: {$0 + $1})
        let dev = sqrt(sumOfSquaredAvgDiff / length)
        
        print("calculate deviation: \(dev)")
        return dev
    }
    
    func getTruthRate(values: [Double], BPMAverage: Double, BPMDeviation: Double) -> Double {
        
        if values.count > 0 {
            let avg = self.getAverage(values)
            //let max = self.getMax(values)
            //let min = self.getMin(values)
            let dev = self.getStandardDeviation(values)
            let T = 5.0
            var score: Double = 1
            
            //have deviation difference
            if dev > 0 {
                score = T / (3 * dev)
                if avg > BPMAverage + 0.2 * BPMDeviation {
                    score = score * 0.8
                }
            }
            
            
            //max score = 1
            if score > 1 {
                score = 1
            }
            
            return score
        }
        //not enough data
        return 1
    }
    
    
//play video
    
    
//image func
    //constant
    //ciimage coordinate
    var naviationHeight:CGFloat = 0.0
    var shrinkPortion: CGFloat = 0.0
    var XBias: CGFloat = 0.0
    var YBias: CGFloat = 0.0
    
    //extra pattern
    
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
    }()
    
    

    
    func createPixelBuffFromImage(image: CGImageRef, currentVideoDimensions: CMVideoDimensions) -> CVPixelBufferRef? {
        
        let option: NSDictionary = [
            String(kCVPixelBufferCGImageCompatibilityKey): NSNumber(bool: true),
            String(kCVPixelBufferCGBitmapContextCompatibilityKey) : NSNumber(bool: true)]
        var pixelBuffer: CVPixelBufferRef? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(currentVideoDimensions.width), Int(currentVideoDimensions.height), kCVPixelFormatType_32ARGB, option, &pixelBuffer)
        
        if status == kCVReturnSuccess && pixelBuffer != nil {
            return pixelBuffer!
        }else {
            return nil
        }
        
    }
    
    func captureImage(sampleBuffer:CMSampleBufferRef) -> UIImage{
        
        // Sampling Bufferから画像を取得
        let imageBuffer:CVImageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        
        // pixel buffer のベースアドレスをロック
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        
        let baseAddress:UnsafeMutablePointer<Void> = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
        let bytesPerRow:Int = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width:Int = CVPixelBufferGetWidth(imageBuffer)
        let height:Int = CVPixelBufferGetHeight(imageBuffer)
        
        
        // 色空間
        let colorSpace:CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        
        
        // swift 2.0
        let newContext:CGContextRef = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace,  CGImageAlphaInfo.PremultipliedFirst.rawValue|CGBitmapInfo.ByteOrder32Little.rawValue)!
        
        //CGImage
        let imageRef:CGImageRef = CGBitmapContextCreateImage(newContext)!
        //UIImage
        let resultImage = UIImage(CGImage: imageRef, scale: 1.0, orientation: UIImageOrientation.Right)
        //CIImage
        //var outputImage = CIImage(CVPixelBuffer: imageBuffer)
        
        //unlock
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
        
        return resultImage
    }
    
    func setupImagePortion(cameraRect: CGRect, view: UIView) {
        //calculate portion
        //first setup
        let uiViewFrame = view.frame
        let rawImageFrame = cameraRect
        //reverse X,Y
        let portionY = cameraRect.width / uiViewFrame.height
        let portionX = cameraRect.height / uiViewFrame.width
        if abs(1 - portionX) > abs(1 - portionY) {
            //height(y) will be larger
            //self.shrinkPortion = portionX
            //reverse x, y
            //self.YBias = -((uiViewFrame.height * self.shrinkPortion) - rawImageFrame.width) / 2
        }else {
            //width(x) will be larger
            //self.shrinkPortion = portionY
            //reverse x, y
            //XBias = -((uiViewFrame.width * self.shrinkPortion) - rawImageFrame.height) / 2
            
        }
        
        return
    }
    
    func drawAnimationByFrame(image: CIImage, view: UIView) -> CIImage {
        
        //frame
        let uiviewFrame = view.frame
        let targetFrame = image.extent
        print("ui view frame: \(uiviewFrame) ")
        print("ciimage view frame: \(targetFrame) ")
        
        //get bias
        self.setupImagePortion(targetFrame, view: view)
        
        //generate all animate on new CIImage
        var recordStartTime: NSDate? = nil
        //recordStartTime = self.questions.last!.startTime
        
        
        //merge
        //let animationCIImage = Singleton.sharedInstance.drawAllAnimationInCIImage(targetFrame.height, height: targetFrame.width, bpm: self.bpm, truthRate: self.truthRate, recordTime: recordStartTime)
        
        //var animateImage = Singleton.sharedInstance.drawCIImageOnSource(image, addCIImage: CIImage(image: heartImage), center: heartCenter, halfWidth: heartRadius, halfHeight: heartRadius, shrinkPortion: self.shrinkPortion, xbias: self.XBias, ybias: self.YBias)
        
        //setup text animation
        //animateImage = Singleton.sharedInstance.drawCIImageOnSource(animateImage, addCIImage: bpmTextImage, center: textCenter, halfWidth: textFrame.width / 2, halfHeight: textFrame.height / 2, shrinkPortion: self.shrinkPortion, xbias: self.XBias, ybias: self.YBias)
        //setup heartLine animation
        //animateImage = Singleton.sharedInstance.drawCIImageOnSource(animateImage, addCIImage: heartLineImage, center: heartLineCenter, halfWidth: uiviewFrame.width / 2, halfHeight: 100, shrinkPortion: self.shrinkPortion, xbias: self.XBias, ybias: self.YBias) //height = 200
        //setup final animation
        
        
        
        return image
    }
    
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
    
    func shareVideoToMessengerAndCameraRoll(url: NSURL, completion: ((assetUrl: NSURL) -> Void )?) {
        if let videoData = NSData(contentsOfURL: url) {
            self.saveVideoToCameraRoll(url, completion: { (identifier, assetUrl) -> Void in
                //save to question
                completion?(assetUrl: assetUrl)
                
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
        self.saveVideoToCameraRoll(url) { (identifier, assetUrl) -> Void in
            print("share video to facebook: \(assetUrl)")
            //save to question
            completion?(newURL: assetUrl)
            
            //facebook func
            self.shareVideoToFacebook(assetUrl, targetVC: targetVC)
        }
    }

    
    
    
    
}



extension Int {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}