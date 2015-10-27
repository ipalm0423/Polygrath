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

class VideoTestViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {

    
    
    
    
    
//camera
    @IBOutlet weak var cameraView: UIView!
    var backCameraDevice: AVCaptureDevice!
    var frontCameraDevice: AVCaptureDevice!
    var captureSession: AVCaptureSession!
    var previewLayer = CALayer()
    var isRecord = false
    
//video
    var avAssetWriter: AVAssetWriter?
    var avAssetWriterPixelBufferInput: AVAssetWriterInputPixelBufferAdaptor?
    var currentSampleTime: CMTime?
    var currentVideoDimensions: CMVideoDimensions?
    var tempURL: NSURL!
    /*
    var stillImage: CIImage!
    lazy var context: CIContext = {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        let options = [kCIContextWorkingColorSpace : NSNull()]
        return CIContext(EAGLContext: eaglContext, options: options)
        }()
    */

    
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
        self.setupCamera(true)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.closeCamera()
    }

    
    
    
    
    
//button
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func recordButtonTouch(sender: AnyObject) {
        print("record button touch")
        if self.isRecord {
            self.stopRecordVideo()
        }else {
            self.startRecordVideo()
        }
        
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
        
        //setup session
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        if captureSession.canSetSessionPreset(AVCaptureSessionPresetMedium) {
            print("preset session medium")
            self.captureSession.sessionPreset = AVCaptureSessionPresetMedium
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
            
            let frameDuration = CMTimeMake(1, 30)
            if videoDevice.activeVideoMaxFrameDuration > frameDuration {
                print("setup frame rate: 30")
                try videoDevice.lockForConfiguration()
                videoDevice.activeVideoMaxFrameDuration = frameDuration
                videoDevice.activeVideoMinFrameDuration = frameDuration
                videoDevice.unlockForConfiguration()
            }
            
            
            
            
            captureSession.commitConfiguration()
            
            //preview camera
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.frame = self.view.layer.frame
            self.view.layer.addSublayer(previewLayer)
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
            
            let image = self.captureImage(sampleBuffer)
            
            //fine tune video
            
            
            
            //preview video
            /*
            dispatch_sync(dispatch_get_main_queue(), {
                self.previewLayer.contents = image
                let textLayer = CALayer(layer: self.createTextCALayer("hello world"))
                textLayer.frame = CGRectMake(0, 0, self.view.frame.width, 50)
                self.previewLayer.addSublayer(textLayer)
            })*/
            
            //record video
            if self.isRecord {
                
                if self.avAssetWriterPixelBufferInput?.assetWriterInput.readyForMoreMediaData == true {
                    //oringinal
                    self.avAssetWriterPixelBufferInput?.assetWriterInput.appendSampleBuffer(sampleBuffer)
                }
            }
            
        }else if connection == self.audioCaptureConnection {
            //audio
            if self.avAssetWriterPixelBufferInput?.assetWriterInput.readyForMoreMediaData == true {
                
            }
            
        }
    }
    
    
    
    func createAVAssetWriter() {
        
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
            
            let assetWriterVideoInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: videoSettings)
            assetWriterVideoInput.expectsMediaDataInRealTime = true
            assetWriterVideoInput.transform = CGAffineTransformMakeRotation(CGFloat(M_PI / 2.0))
            
            let sourcePixelBufferAttributesDictionary: [String : AnyObject] = [String(kCVPixelBufferPixelFormatTypeKey): NSNumber(unsignedInt: kCVPixelFormatType_32BGRA), String(kCVPixelBufferWidthKey) : Int(currentVideoDimensions!.width),
                String(kCVPixelBufferHeightKey) : Int(currentVideoDimensions!.height)]
            
            self.avAssetWriterPixelBufferInput = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: assetWriterVideoInput, sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
            
            //audio
            let audioSettings: [String: AnyObject]? = nil
            
            let assetWriterAudioInput = AVAssetWriterInput(mediaType: AVMediaTypeAudio, outputSettings: audioSettings)
            assetWriterAudioInput.expectsMediaDataInRealTime = true
            
            
            
            
            if self.avAssetWriter!.canAddInput(assetWriterVideoInput) && self.avAssetWriter!.canAddInput(assetWriterAudioInput) {
                self.avAssetWriter!.addInput(assetWriterVideoInput)
                self.avAssetWriter!.addInput(assetWriterAudioInput)
            } else {
                print("不能添加视频writer的input \(assetWriterVideoInput), \(assetWriterAudioInput)")
            }
            
            
        }catch {
            print("create AVAssetWriter fail")
            print(error)
            return
        }
        
    }
    
    func startRecordVideo() {
        self.createAVAssetWriter()
        self.avAssetWriter?.startWriting()
        self.avAssetWriter?.startSessionAtSourceTime(currentSampleTime!)
        self.isRecord = true
    }
    
    func stopRecordVideo() {
        self.isRecord = false
        self.avAssetWriter?.finishWritingWithCompletionHandler({ () -> Void in
            print("錄製完成")
            Singleton.sharedInstance.saveVideoToCameraRoll(self.tempURL)
        })
    }
    
//CALayer
    func createTextCALayer(text: String) -> CALayer {
        let subtitle = CATextLayer()
        subtitle.font = UIFont.boldSystemFontOfSize(30)
        subtitle.frame  = CGRectMake(0, 0, self.view.frame.width, 50)
        subtitle.string = text
        subtitle.alignmentMode = kCAAlignmentCenter
        subtitle.foregroundColor = UIColor.redColor().CGColor
        
        return subtitle
    }
    
    func createUIImageCALayer(image: UIImage) -> CALayer {
        let newLayer = CALayer()
        newLayer.contents = image
        newLayer.frame = CGRectMake(0, 0, 100, 100)
        newLayer.masksToBounds = true
        
        return newLayer
    }
    
    
    
//File
    
    /*
    func saveVideoToCameraRoll(url: NSURL) {
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.Authorized {
            print("save video to camera roll")
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                let option: PHAssetResourceCreationOptions = PHAssetResourceCreationOptions()
                option.shouldMoveFile = true
                let changeRequest = PHAssetCreationRequest.creationRequestForAsset()
                changeRequest.addResourceWithType(PHAssetResourceType.Video, fileURL: url, options: option)
                
                }, completionHandler: { (result, error) -> Void in
                    if !result {
                        print("can't save video")
                        print(error)
                        self.alertError("Can't save video.")
                    }
            })
        }else {
            //user not allow access camera roll
            self.alertError("We can't access camera roll")
        }
    }*/
    
    
    
    
//alert
    func alertError(error: String) {
        print("alert error message: \(error)")
        let alert = UIAlertController(title: "Error", message: error, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
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
