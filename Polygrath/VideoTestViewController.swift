//
//  VideoTestViewController.swift
//  Polygrath
//
//  Created by 陳冠宇 on 2015/10/15.
//  Copyright © 2015年 陳冠宇. All rights reserved.
//

import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import WatchConnectivity

class VideoTestViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, WCSessionDelegate {

//WatchConnection
    var wcSession: WCSession? = WCSession.isSupported() ? WCSession.defaultSession() : nil {
        didSet{
            if wcSession == nil {
                self.alertError("Your device is not support! Please update iOS.")
            }
        }
    }
    

    
//health kit
    var bpm: Int = 0
    var isLying = false {
        didSet{
            if self.isLying {
                Singleton.sharedInstance.playHeartBeatEffect()
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                print("user is lying, vibrate and play sound")
            }else {
                Singleton.sharedInstance.stopPlayingEffect()
            }
        }
    }
    var dataDates = [NSDate]()
    var dataValues = [Double]()
    var questions: [question] = []
    var bpmMax: Double = 0
    var bpmMin: Double = 200
    var average: Double = 0
    var deviation: Double = 0
    var truthRate = 0.0

    @IBOutlet weak var progressLieBar: UIProgressView!
    
//time
    let startTime = NSDate()
    
    
    
//camera
    
    var backCameraDevice: AVCaptureDevice!
    var frontCameraDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var previewLayer = CALayer()
    var isBackCamera = true
    var isRecord = false {
        didSet {
            //change button icon
            if self.isRecord {
                self.recordButton.setTitle("Stop", forState: UIControlState.Normal)
                self.recordButton.backgroundColor = UIColor(red: 1, green: 0.1, blue: 243 / 255, alpha: 0.9)
            }else {
                self.recordButton.setTitle("Record", forState: UIControlState.Normal)
                self.recordButton.backgroundColor = UIColor(red: 80 / 255, green: 1, blue: 0, alpha: 0.9)
            }
        }
    }
    var isCameraOn = false
    
//video
    var avAssetWriter: AVAssetWriter?
    var avAssetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    var tempURL: NSURL!
    
    
//extra pattern
    
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
        }()
    /*
    var stillImage: CIImage!
    lazy var context: CIContext = {
    let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
    let options = [kCIContextWorkingColorSpace : NSNull()]
    return CIContext(EAGLContext: eaglContext, options: options)
    }()
    */
    
//ciimage coordinate
    var naviationHeight:CGFloat = 0.0
    var shrinkPortion: CGFloat = 0.0
    var XBias: CGFloat = 0.0
    var YBias: CGFloat = 0.0
    
//animate const
    var heartDegree = 0
    
    
//audio
    var avAssetWriterAudioInput: AVAssetWriterInput!
    var avAssetWriterVideoInput: AVAssetWriterInput!
    
//queue
    let audioQueue = dispatch_queue_create("AudioQueue", DISPATCH_QUEUE_SERIAL)
    let videoQueue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL)
    var audioCaptureConnection: AVCaptureConnection?
    var videoCaptureConnection: AVCaptureConnection?
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBarHidden = false
        Singleton.sharedInstance.removeAllVideoTemp()
        self.setupWCConnection()
        self.setupCamera(true)
        Singleton.sharedInstance.setupAudioPlayer()
        //idle time disable
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        //setup navi bar height
        if let navigationHeight = self.navigationController?.navigationBar.frame.height {
            self.naviationHeight = navigationHeight
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.stopRecordVideo()
        self.closeCamera()
    }

    
    
    
    
    
//button
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTouch(sender: AnyObject) {
        print("record button touch")
        if self.isRecord {
            self.stopRecordVideo()
            //Save question file url, end time.
            let lastQuest = self.questions[self.questions.count - 1]
            let recordFile = RecordedFile()
            recordFile.title = self.tempURL.lastPathComponent
            recordFile.URL = self.tempURL
            lastQuest.file = recordFile
            lastQuest.endTime = NSDate()
            
        }else {
            self.startRecordVideo()
            //new a question
            let newQuest = question()
            newQuest.questIndex = self.questions.count + 1
            self.questions.append(newQuest)
        }
        
    }
    
    @IBOutlet weak var switchButton: UIButton!
    
    @IBAction func switchButtonTouch(sender: AnyObject) {
        self.isLying = !self.isLying
        self.switchCamera()
    }
    
    
//WC SESSION
    func setupWCConnection() {
        if WCSession.isSupported() {
            self.wcSession?.delegate = self
            self.wcSession?.activateSession()
            if let isConnect = self.wcSession?.reachable {
                print("session reachable: \(isConnect)")
            }else {
                self.alertWatchConnection()
            }
        }
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        
        //geting data from watch
        if let dics = userInfo["heartRateData"] as? [NSDate : Double] {
            //sort by time
            let dicsSort = dics.sort({ (a, b) -> Bool in
                if a.0.timeIntervalSince1970 > b.0.timeIntervalSince1970 {
                    return false
                }
                return true
            })
            print("got new heart rate data: \(dicsSort)")
            //add to grath
            dispatch_sync(dispatch_get_main_queue()) { () -> Void in
                //save
                for dic in dicsSort {
                    self.dataDates.append(dic.0)
                    self.dataValues.append(dic.1)
                
                    //set bpm data
                    self.bpm = Int(dic.1)
                    if dic.1 > self.bpmMax {
                        self.bpmMax = dic.1
                    }
                    if dic.1 < self.bpmMin {
                        self.bpmMin = dic.1
                    }
                    
                    //calculate
                    self.updateQuestionData(dic.0, value: dic.1)
                    if self.getTruthRate() < 0.5 {
                        self.isLying = true
                    }else {
                        self.isLying = false
                    }
                    self.progressLieBar.setProgress(Float(1 - self.truthRate), animated: true)
                }
            }
        }
    }
    
    func session(session: WCSession, didReceiveMessage message: [String : AnyObject]) {
        print(message)
        
        // get command from watch
        if let cmd = message["cmd"] as? String {
            if cmd == "stop" {
                print("recieve cmd from watch: stop")
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.stopRecordVideo()
                    //alert
                    self.alertMessage("Test was stop by iWatch", type: 0)
                })
            }
        }
    }
    
    
    
    func sendCMDStopWatch() {
        if self.wcSession!.reachable {
            //send cmd to watch
            self.wcSession?.sendMessage(["cmd" : "stop"], replyHandler: { (reply) -> Void in
                if let response = reply["cmdResponse"] as? Bool {
                    if response {
                        print("got 'stop' cmd response from watch: \(response)")
                        
                    }
                }
                }, errorHandler: { (error) -> Void in
                    print(error)
            })
        }else {
            //unReachable, alert manually close
            self.alertStopMannualOnWatch()
            return
        }
    }

    
    
//data analyse
    func updateQuestionData(time: NSDate, value: Double) {
        if self.questions.count > 0 {
            for quest in self.questions {
                
                if time.timeIntervalSinceDate(quest.startTime) > 0 && quest.endTime.timeIntervalSinceDate(time) > 0 {
                    //data is in previous time range
                    quest.dataValues.append(value)
                    quest.dataDates.append(time)
                    print("add data to Q.\(quest.questIndex)")
                    return
                }
            }
            //data is in the last time range
            self.questions[questions.count - 1].dataValues.append(value)
            self.questions[questions.count - 1].dataDates.append(time)
            print("add data to Q.\(self.questions.count)")
        }
    }
    
    func getTruthRate() -> Double {
        self.average = Singleton.sharedInstance.getAverage(self.dataValues)
        self.deviation = Singleton.sharedInstance.getStandardDeviation(self.dataValues)
        let oneDeviation = self.average + self.deviation
        self.truthRate = 1.0
        let count = self.dataValues.count
        
        if count > 2 {
            let delta = self.dataValues.last! - self.dataValues[count - 2]
            if delta > 4 {
                self.truthRate = self.truthRate - 0.2 * (delta - 4)
            }else if delta < -7 {
                //comedown
                self.truthRate = self.truthRate * 1.2
            }
            if self.dataValues.last > oneDeviation {
                self.truthRate = self.truthRate * 0.4
            }
            //previous 2 point
            for var i = 2; i < 4; i++ {
                if self.dataValues[count - i] > oneDeviation {
                    self.truthRate = self.truthRate * 0.9
                }
            }
            
        }
        
        //return 100%
        if self.truthRate > 1 {
            self.truthRate = 1
        }
        
        return truthRate
    }
    
//camera
    
    func setupCamera(isBackCamera: Bool) {
        
        print("setup camera")
        //setup device
        let availableCameraDevices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in availableCameraDevices as! [AVCaptureDevice] {
            if device.position == .Back {
                self.backCameraDevice = device
            }
            else if device.position == .Front {
                self.frontCameraDevice = device
            }
        }
        self.isBackCamera = isBackCamera
        //setup session
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(AVCaptureSessionPresetiFrame1280x720) {
            print("preset session medium")
            self.captureSession.sessionPreset = AVCaptureSessionPresetiFrame1280x720
        }
        
        do {
            
            //audio INPUT
            let audioDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            }
            
            //audio OUTPUT
            let audioDeviceOutput = AVCaptureAudioDataOutput()
            audioDeviceOutput.setSampleBufferDelegate(self, queue: self.audioQueue)
            if self.captureSession.canAddOutput(audioDeviceOutput) {
                self.captureSession.addOutput(audioDeviceOutput)
                self.audioCaptureConnection = audioDeviceOutput.connectionWithMediaType(AVMediaTypeAudio)
            }
            
            //video INPUT
            let videoDevice = isBackCamera ? self.backCameraDevice : self.frontCameraDevice
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            
            //video OUTPUT
            let videoDeviceOutput = AVCaptureVideoDataOutput()
            videoDeviceOutput.setSampleBufferDelegate(self, queue: videoQueue)
            
            //output setting
            let videoSets = NSDictionary(object: NSNumber(unsignedInt: kCVPixelFormatType_32BGRA), forKey: String(kCVPixelBufferPixelFormatTypeKey))
            videoDeviceOutput.videoSettings = videoSets as [NSObject : AnyObject]
            videoDeviceOutput.alwaysDiscardsLateVideoFrames = false
            if self.captureSession.canAddOutput(videoDeviceOutput) {
                self.captureSession.addOutput(videoDeviceOutput)
                self.videoCaptureConnection = videoDeviceOutput.connectionWithMediaType(AVMediaTypeVideo)
            }
            
            //frame rate
            
            let frameDuration = CMTimeMake(1, 15)
            print("device max frame: \(videoDevice.activeVideoMaxFrameDuration)")
            if videoDevice.activeVideoMaxFrameDuration > frameDuration {
                print("setup frame rate: 15")
                try videoDevice.lockForConfiguration()
                videoDevice.activeVideoMaxFrameDuration = frameDuration
                videoDevice.activeVideoMinFrameDuration = frameDuration
                videoDevice.unlockForConfiguration()
            }
            
            
            
            
            captureSession.commitConfiguration()
            
            //preview camera
            
            previewLayer.anchorPoint = CGPointZero
            previewLayer.bounds = view.bounds
            previewLayer.contentsGravity = kCAGravityResizeAspectFill
            self.view.layer.addSublayer(previewLayer)
            self.view.clipsToBounds = true
            
            //setup image portion
            
            print("preview frame: \(previewLayer.frame)")
            print("view frame: \(self.view.frame)")
            print("preview center: \(view.center)")
            //button
            self.view.bringSubviewToFront(self.recordButton)
            self.view.bringSubviewToFront(self.switchButton)
            self.view.bringSubviewToFront(self.progressLieBar)
            self.captureSession.startRunning()
            
        }catch {
            print("error: can't setup camera")
            self.alertError("Can't open camera")
            print(error)
            return
        }
        
        
    }
    
    func closeCamera() {
        self.captureSession.stopRunning()
        
        for output in self.captureSession.outputs {
            self.captureSession.removeOutput(output as? AVCaptureOutput)
        }
        
        for input in self.captureSession.inputs {
            self.captureSession.removeInput(input as? AVCaptureInput)
        }
        
        self.captureSession = nil
        self.frontCameraDevice = nil
        self.backCameraDevice = nil
        self.previewLayer.removeFromSuperlayer()
        self.isCameraOn = false
        
    }
    
    func switchCamera() {
        if !self.isRecord {
            self.closeCamera()
            if isBackCamera {
                self.setupCamera(false)
            }else {
                self.setupCamera(true)
            }
            self.isCameraOn = false
        }
    }
    
    func takeStillPicture(){
        if let connection = self.videoCaptureConnection {
            /* save UIView
            UIGraphicsBeginImageContext(self.view.bounds.size);
            self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            let screenShot = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            // アルバムに追加
            UIImageWriteToSavedPhotosAlbum(screenShot, self, nil, nil)
            
            
            //Save image (need modify for IOS9)
            var cgImage = context.createCGImage(self.stillImage, fromRect: stillImage.extent)
            ALAssetsLibrary().writeImageToSavedPhotosAlbum(cgImage, metadata: self.stillImage.properties)
                { (url: NSURL!, error :NSError!) -> Void in
                    if error == nil {
                        println("保存成功")
                        println(url)
                    } else {
                        let alert = UIAlertView(title: "错误",
                            message: error.localizedDescription,
                            delegate: nil,
                            cancelButtonTitle: "确定")
                        alert.show()
                    }
                    self.captureSession.startRunning()
                    sender.enabled = true
            }*/

        }
    }
    

//video
    
    func createPixelFromImage(image: CGImageRef) -> CVPixelBufferRef? {
        
        let option: NSDictionary = [
            String(kCVPixelBufferCGImageCompatibilityKey): NSNumber(bool: true),
            String(kCVPixelBufferCGBitmapContextCompatibilityKey) : NSNumber(bool: true)]
        var pixelBuffer: CVPixelBufferRef? = nil
        
        let status: CVReturn = CVPixelBufferCreate(kCFAllocatorDefault, Int(currentVideoDimensions!.width), Int(currentVideoDimensions!.height), kCVPixelFormatType_32ARGB, option, &pixelBuffer)
        
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
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        
        
        if connection == self.videoCaptureConnection {
            //parameter setup
            let format = CMSampleBufferGetFormatDescription(sampleBuffer)!
            self.currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(format)
            self.currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            
            //original image
            var tempCIImage: CIImage = CIImage(CVPixelBuffer: CMSampleBufferGetImageBuffer(sampleBuffer)!)
        
            //preview layer is ready
            if !self.isCameraOn {
                self.setupAVAssetWriter()
                self.setupImagePortion(tempCIImage.extent)
                self.isCameraOn = true
            }
            
            //add-on image
            tempCIImage = self.drawAnimationByFrame(tempCIImage)
            
//record video
            if self.isRecord {
                
                if self.avAssetWriterPixelBufferInput?.assetWriterInput.readyForMoreMediaData == true {
                    //draw water mark
                    //tempCIImage = self.drawWaterMark(tempCIImage)
                    
                    //<oringinal type>
                    //self.avAssetWriterPixelBufferInput?.assetWriterInput.appendSampleBuffer(sampleBuffer)
                    
                    
                    //test
                    /*
                    if let newBuffer = self.createPixelFromImage(cgimage) {
                        if let success = self.avAssetWriterPixelBufferInput?.appendPixelBuffer(newBuffer, withPresentationTime: self.currentSampleTime!) {
                            if !success {
                                //fail to append buff
                                print("fail to append buffer with modify")
                            }
                        }
                    }*/
                    
                    //<modify type>
                    //change CIImage to buffer for saving
                    var newPixelBuffer: CVPixelBuffer? = nil
                    CVPixelBufferPoolCreatePixelBuffer(nil, self.avAssetWriterPixelBufferInput!.pixelBufferPool!, &(newPixelBuffer))
                    self.context.render(tempCIImage, toCVPixelBuffer: newPixelBuffer!, bounds: tempCIImage.extent, colorSpace: nil)
                    
                    if let success = self.avAssetWriterPixelBufferInput?.appendPixelBuffer(newPixelBuffer!, withPresentationTime: self.currentSampleTime!) {
                        if !success {
                            //fail to append buff
                            print("fail to append buffer with modify")
                        }
                    }
                }
            }
        
//preview
            //rotate to portait
            let t = CGAffineTransformMakeRotation(CGFloat((-M_PI / 2.0)))
            tempCIImage = tempCIImage.imageByApplyingTransform(t)
            
            //change content preview layer
            let cgimage = self.context.createCGImage_(tempCIImage, fromRect: tempCIImage.extent)
            
            dispatch_sync(dispatch_get_main_queue(), {
                //change to CGImage
                self.previewLayer.contents = cgimage
                
            })
            
        }else if connection == self.audioCaptureConnection {
            //audio
            if self.isRecord {
                if self.avAssetWriterAudioInput?.readyForMoreMediaData == true {
                    self.avAssetWriterAudioInput.appendSampleBuffer(sampleBuffer)
                }
            }
        }
    }
    
    
    func setupAVAssetWriter() {
        do {
            let url = Singleton.sharedInstance.getNewFileURL()
            self.tempURL = url
            self.avAssetWriter = try AVAssetWriter(URL: url, fileType: AVFileTypeQuickTimeMovie)
            
            //video
            let videoSettings: [String : AnyObject] = [
                AVVideoCodecKey : AVVideoCodecH264,
                AVVideoWidthKey : Int(currentVideoDimensions!.width),
                AVVideoHeightKey : Int(currentVideoDimensions!.height)
            ]
            
            self.avAssetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            avAssetWriterVideoInput.expectsMediaDataInRealTime = true
            avAssetWriterVideoInput.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0))
            
            let sourcePixelBufferAttributesDictionary: [String : AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: kCVPixelFormatType_32BGRA), String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
                String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height)]
            
            self.avAssetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: self.avAssetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            
            //audio
            let audioSettings: [String: AnyObject] = [
                AVFormatIDKey: NSNumber(unsignedInt: kAudioFormatMPEG4AAC),
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 64000
            ]
            self.avAssetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
            self.avAssetWriterAudioInput.expectsMediaDataInRealTime = true
            
            
            
            
            if self.avAssetWriter!.canAddInput(self.avAssetWriterVideoInput) && self.avAssetWriter!.canAddInput(self.avAssetWriterAudioInput) {
                self.avAssetWriter!.addInput(self.avAssetWriterVideoInput)
                self.avAssetWriter!.addInput(self.avAssetWriterAudioInput)
            } else {
                print("不能添加视频writer的input \(self.avAssetWriterVideoInput), \(self.avAssetWriterAudioInput)")
            }
            
            
        }catch {
            print("setup AVAssetWriter fail")
            print(error)
            return
        }
    }
    
    func createNewAVAssetWriter() {
        
        do {
            //new url
            let url = Singleton.sharedInstance.getNewFileURL()
            self.tempURL = url
            self.avAssetWriter = try AVAssetWriter(URL: url, fileType: AVFileTypeQuickTimeMovie)
            
            //input
            if self.avAssetWriter!.canAddInput(self.avAssetWriterVideoInput) && self.avAssetWriter!.canAddInput(self.avAssetWriterAudioInput) {
                self.avAssetWriter!.addInput(self.avAssetWriterVideoInput)
                self.avAssetWriter!.addInput(self.avAssetWriterAudioInput)
            } else {
                print("不能添加视频writer的input \(self.avAssetWriterVideoInput), \(self.avAssetWriterAudioInput)")
            }
            
            
        }catch {
            print("create new AVAssetWriter fail")
            print(error)
            return
        }
        
    }
    
    func startRecordVideo() {
        if !self.isRecord {
            self.createNewAVAssetWriter()
            self.avAssetWriter?.startWriting()
            self.avAssetWriter?.startSessionAtSourceTime(currentSampleTime!)
            self.isRecord = true
        }
    }
    
    func stopRecordVideo() {
        if self.isRecord {
            self.isRecord = false
            self.avAssetWriter?.finishWritingWithCompletionHandler({ () -> Void in
                print("錄製完成")
                Singleton.sharedInstance.saveVideoToCameraRoll(self.tempURL)
            })
        }
    }
    

//image modify
    func setupImagePortion(cameraRect: CGRect) {
        //calculate portion
        //first setup
        let uiViewFrame = self.view.frame
        let rawImageFrame = cameraRect
        //reverse X,Y
        let portionY = cameraRect.width / uiViewFrame.height
        let portionX = cameraRect.height / uiViewFrame.width
        if abs(1 - portionX) > abs(1 - portionY) {
            //height(y) will be larger
            self.shrinkPortion = portionX
            //reverse x, y
            self.YBias = -((uiViewFrame.height * self.shrinkPortion) - rawImageFrame.width) / 2
        }else {
            //width(x) will be larger
            self.shrinkPortion = portionY
            //reverse x, y
            XBias = -((uiViewFrame.width * self.shrinkPortion) - rawImageFrame.height) / 2
            
        }
        
        return
    }
    
    func drawAnimationByFrame(image: CIImage) -> CIImage {
        //frame
        let uiviewFrame = self.view.frame
        
        //temp image
        var tempImage = image
        //heart image
        let heartImage = UIImage(named: "heart-80-vec")!
        let heartRadius = self.getHeartRadiusByFrame()
        
        //text image
        let bpmTextImage = Singleton.sharedInstance.createTextCIImage(bpm.description, font: UIFont.italicSystemFontOfSize(26))
        let textFrame = bpmTextImage.extent
        
        //coordinate, original = (0, 0)
        let heartCenter = CGPoint(x: 60 , y:  self.naviationHeight + 10 + 60 )
        let textCenter = CGPoint(x: (uiviewFrame.width - (20 + textFrame.width / 2)), y: (self.naviationHeight + 10 + 20 + textFrame.height / 2))
        
        //setup heart animation
        tempImage = Singleton.sharedInstance.drawCIImageOnSource(image, addCIImage: CIImage(image: heartImage), center: heartCenter, halfWidth: heartRadius, halfHeight: heartRadius, shrinkPortion: self.shrinkPortion, xbias: self.XBias, ybias: self.YBias)
        //setup text animation
        tempImage = Singleton.sharedInstance.drawCIImageOnSource(tempImage, addCIImage: bpmTextImage, center: textCenter, halfWidth: textFrame.width / 2, halfHeight: textFrame.height / 2, shrinkPortion: self.shrinkPortion, xbias: self.XBias, ybias: self.YBias)
        
        return tempImage
    }
    
    
    
//culculation
    func getHeartRadiusByFrame() -> CGFloat {
        let range = CGFloat(self.bpm) * 0.3
        var heartRadius: CGFloat = 20 + abs(cos((self.heartDegree.degreesToRadians)) * range)
        if self.isLying {
            heartRadius = heartRadius * 1.2
        }
        //ratio is from 12~24
        self.heartDegree += 12 * (self.bpm / 60)
        
        return heartRadius
    }
    
    
//alert
    func alertError(error: String) {
        print("alert error message: \(error)")
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertWatchConnection() {
        
    }
    
    func alertStopMessage() {
        print("alert message: stop")
        let alert = UIAlertController(title: "Alert", message: "Program is stop by iWatch", preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            switch action.style{
            case .Default:
                print("test is stop by watch, jump to result", terminator: "")
                //segue
                self.performSegueWithIdentifier("ResultSegue", sender: self)
                
            case .Cancel:
                print("cancel", terminator: "")
                
            case .Destructive:
                print("destructive", terminator: "")
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertStopMannualOnWatch() {
        print("alert message: stop mannully")
        let alert = UIAlertController(title: "Alert", message: "Press 'Stop' button on your iWatch", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func alertMessage(message: String, type: Int) {
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ResultSegue" {
            if let VC = segue.destinationViewController as? ResultViewController {
                VC.BPMAverage = self.average
                VC.BPMDeviation = self.deviation
                VC.BPMmax = self.bpmMax
                VC.BPMmin = self.bpmMin
                VC.questions = self.questions
            }
        }
    }

}

extension CIContext {
    func createCGImage_(image:CIImage, fromRect:CGRect) -> CGImage {
        let width = Int(fromRect.width)
        let height = Int(fromRect.height)
        
        let rawData =  UnsafeMutablePointer<UInt8>.alloc(width * height * 4)
        render(image, toBitmap: rawData, rowBytes: width * 4, bounds: fromRect, format: kCIFormatRGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        let dataProvider = CGDataProviderCreateWithData(nil, rawData, height * width * 4) {info, data, size in UnsafeMutablePointer<UInt8>(data).dealloc(size)}
        return CGImageCreate(width, height, 8, 32, width * 4, CGColorSpaceCreateDeviceRGB(), CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue), dataProvider, nil, false, .RenderingIntentDefault)!
    }
}

extension Int {
    var degreesToRadians : CGFloat {
        return CGFloat(self) * CGFloat(M_PI) / 180.0
    }
}
