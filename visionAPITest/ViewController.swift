//
//  ViewController.swift
//  visionAPITest
//
//  Created by Scarlet on A2020/J/8.
//  Copyright © 2020 Scarlet. All rights reserved.
//

/// Library for entire UI-related stuff, 'Foundation' included, Swift Standard Library, must-have for iOS development
import UIKit
/// Library for AVCaptureSession and related Classes, Swift
import AVFoundation
///Library for Core ML model predictions
import CoreML

/// Library for Vision API, install through Cocoapods, Third-party
import Firebase

class ViewController: UIViewController,
                AVCaptureVideoDataOutputSampleBufferDelegate{
    
    //MARK: - VARIABLE
    
    
    //MARK: LET
    /// DispatchQueue, just like Thread
    let queue = DispatchQueue(label: "video-frame-sampler")
    let objQueue = DispatchQueue(label: "objQueue")
    
    let model = Classifier()
    
    let croppedView = UIImageView()
    
    //MARK: VAR
    /// AVFoundation stuff
//    var prevLayer: AVCaptureVideoPreviewLayer!
    var session: AVCaptureSession!
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var videoOutput: AVCaptureVideoDataOutput!
    var output: AVCaptureMetadataOutput?
    /// Vision API Object Detector
    var objectDetector = Vision.vision().objectDetector()
    
    var lbl = UILabel()
    var count = 0
    var currentTrackingID = -1
    var hightlighting = false
    
    //MARK: -
    //MARK: - IBOUTLET
    @IBOutlet weak var camview: UIImageView!
    @IBOutlet weak var unfreezeBtn: UIButton!
    @IBOutlet weak var actInd: UIActivityIndicatorView!
    @IBOutlet weak var loadingView: UIView!
    
    
    //MARK: - IBACTION
    @IBAction func unfreeze(_ sender: UIButton) {
        loadingView.alpha = 0
        croppedView.alpha = 0
        hightlighting = false
        session.startRunning()
        objQueue.async {
            sleep(1)
        }
    }
    
    
    //MARK: - DELEGATION
    /** AVCaptureVideoDataOutputSampleBufferDelegate
            Get video buffer from phone's camera, and do Vision API Magic
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        /// Turn CMSmapleBuffer Data into UIImage
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let imagei : UIImage = self.convert(cmage: ciimage)
        
        DispatchQueue.main.async {
            self.camview.image = imagei
        }
        
        /// Create a Google Vision API -compitable Image Format
        
        let image = VisionImage(image: imagei)
        
        ///Object Detection and Tracking - onDevice Vision API
        self.objectDetector.process(image) { detectedObjects, error in
            /// Error
            guard error == nil else { return }
            
            /// Not Detected, either object nolonger in sight or no recognizable object detected
            guard let detectedObjects = detectedObjects, !detectedObjects.isEmpty else {
                print("Not detected")
                self.hightlighting = false
                self.session.startRunning()
                return
            }
            
            /// Object Found, perform bounding box drawing and give it label information
            print("detected")
            self.objQueue.async{
                DispatchQueue.main.async {
                    self.loadingView.alpha = 0.3
                }
                self.session.stopRunning()
                for obj in detectedObjects {
                    let bounds = obj.frame
                    
                    /// Perform bounding box resize
                    
                    let cropped = self.cropImageToBars(image: imagei, frame: bounds)
                    let croppedVision = VisionImage(image: cropped)
                    DispatchQueue.main.async {
                        let ratioX = self.camview.frame.width / imagei.size.width
                        let ratioY = self.camview.frame.height / imagei.size.height
                        let frameBound = CGRect(x: bounds.minX * ratioX,
                                                y: bounds.minY * ratioY,
                                                width: bounds.width * ratioX,
                                                height: bounds.height * ratioY)
                        
                        if !self.hightlighting{
                            self.croppedView.alpha = 1
                            self.hightlighting = true
                        }
                        self.croppedView.image = cropped
                        self.croppedView.frame = frameBound
                        self.lbl.frame = CGRect(x: self.croppedView.frame.minX, y: self.croppedView.frame.minY, width: self.croppedView.frame.width, height: 30)
                        self.loadingView.alpha = 0
                    }
                    
                    /// Check for repeating object, skip labeler to save energy if same object in frame
                    let trackingID = Int(truncating: obj.trackingID!)
                    if self.currentTrackingID != trackingID {
                        print("Running Labeler for ID \(trackingID)")
                        /** Labeler - onDevice Vision API
                         currently listing all results from onDevice Labeler for debug purpose,
                         can switch to Cloud Vision API for more accurate label (Cost money)
                         */
                        let labeler = Vision.vision().onDeviceImageLabeler()
                        labeler.process(croppedVision) { labels, error in
                            guard error == nil, let labels = labels else { return }
                            self.lbl.text = labels.first?.text
                        }
                        self.currentTrackingID = trackingID
                    }
                }
            }
        }
    }
    
    //MARK: - OBJC FUNC
    
    
    //MARK: - FUNC
    /// Helper function to convert CIImage to UIImage, for use with CMSampleBuffer
    func convert(cmage:CIImage) -> UIImage {
         let context:CIContext = CIContext.init(options: nil)
         let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
         let image:UIImage = UIImage.init(cgImage: cgImage)
         return image
    }
    
    /// Helper function to convert UIImage to CVPixelBuffer
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    
    /// Helper function to crop image suitable for Core ML Input
    func cropImageToBars(image: UIImage, frame: CGRect = CGRect(x: 0, y: 224, width: 224, height: 224)) -> UIImage {

        let rect = frame

        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        defer{
          UIGraphicsEndImageContext()
        }
        flipContextVertically(contentSize: rect.size)

        let cgImage = image.cgImage!.cropping(to: rect)!
        return UIImage(cgImage: cgImage)
    }
    
    /// Helper function to filp the UIGraphicsContext into correct orientation
    func flipContextVertically(contentSize:CGSize){
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -contentSize.height)

        UIGraphicsGetCurrentContext()!.concatenate(transform)
    }
    
    /** Responsibile for the live video feed to work.
        All it does is:
        - Initiate AVCaptureSession
        - Get available device input
        - Bind the Back Camera (Standard Wide-angle lens for multi-lens phone) as the Session input
        - Setup Output parameters
        - Bind Output to the Session such that the above Delegate method can be called
        - Create and display a video preview layer
    */
    func createSession() {
        session = AVCaptureSession()
        device = AVCaptureDevice.default(for: AVMediaType.video)

        do{
            input = try AVCaptureDeviceInput(device: device!)
        }
        catch{
            print(error.localizedDescription)
            return
        }

        if let input = input {
            if session.canAddInput(input) {
                session.addInput(input)
            }
        }

        videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput!.setSampleBufferDelegate(self, queue: queue)
        videoOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.connections.forEach({$0.videoOrientation = .portrait})
        
        croppedView.addSubview(lbl)
        camview.addSubview(croppedView)
        
        session.startRunning()
    }
    
    //MARK: - VIEW ROUTINE
    func delegate(){
        
    }
    func layout(){
        lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 45))
        lbl.backgroundColor = .white
        lbl.textColor = .black
        lbl.adjustsFontSizeToFitWidth = true
        lbl.minimumScaleFactor = 0.5
        lbl.textAlignment = .center
        lbl.layer.cornerRadius = 7
        croppedView.layer.cornerRadius = 12
        croppedView.layer.borderWidth = 7
        croppedView.layer.borderColor = UIColor.white.cgColor
        croppedView.alpha = 0
        croppedView.contentMode = .scaleAspectFill
        unfreezeBtn.layer.cornerRadius = unfreezeBtn.frame.width / 2
        actInd.layer.cornerRadius = 15
    }
    func setup(){
        let options = VisionObjectDetectorOptions()
        options.detectorMode = .stream
        options.shouldEnableMultipleObjects = false
        objectDetector = Vision.vision().objectDetector(options: options)
//        prevLayer?.frame.size = camview.frame.size
        createSession()
    }
    
    //MARK: - VIEW CONTROLLER
    override func viewDidLoad(){
        super.viewDidLoad()
        
        delegate()
        layout()
        setup()
        
    }
    
}
