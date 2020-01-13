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

/// Library for Vision API, install through Cocoapods, Third-party
import Firebase

class ViewController: UIViewController,
                AVCaptureVideoDataOutputSampleBufferDelegate{
    
    //MARK: - VARIABLE
    
    
    //MARK: LET
    /// DispatchQueue, just like Thread
    let queue = DispatchQueue(label: "video-frame-sampler")
    
    let screenBound = UIScreen.main.bounds
    let highlightView = UIView()
    
    //MARK: VAR
    /// AVFoundation stuff
    var prevLayer: AVCaptureVideoPreviewLayer!
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
    var boundRatio = CGFloat.zero
    
    //MARK: -
    //MARK: - IBOUTLET
    
    
    //MARK: - IBACTION
    
    
    //MARK: - DELEGATION
    /** AVCaptureVideoDataOutputSampleBufferDelegate
            Get video buffer from phone's camera, and do Vision API Magic
     */
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        /// Turn CMSmapleBuffer Data into UIImage
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let imagei : UIImage = self.convert(cmage: ciimage)
        
        /// Create a Google Vision API -compitable Image Format
        let image = VisionImage(image: imagei)
        
        ///Object Detection and Tracking - onDevice Vision API
        objectDetector.process(image) { detectedObjects, error in
            /// Error
            guard error == nil else { return }
            
            /// Not Detected, either object nolonger in sight or no recognizable object detected
            guard let detectedObjects = detectedObjects, !detectedObjects.isEmpty else {
                print("Not detected")
                self.hightlighting = false
                self.highlightView.alpha = 0
                return
            }
            
            /// Object Found, perform bounding box drawing and give it label information
            print("detected")
            for obj in detectedObjects {
                let bounds = obj.frame
                
                /// Perform bounding box resize
                let ratio = self.boundRatio * (bounds.height / bounds.width)
                let widthX = bounds.width * ratio
                let widthY = widthX * ratio * (bounds.height / bounds.width)
                let frameBound = CGRect(x: bounds.minX * ratio,
                                        y: bounds.minY * ratio,
                                        width: widthX,
                                        height: widthY)
                
                self.highlightView.frame = frameBound
                if !self.hightlighting{
                    self.highlightView.alpha = 0.4
                    self.hightlighting = true
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
                    labeler.process(image) { labels, error in
                        guard error == nil, let labels = labels else { return }
                        self.lbl.frame.origin.x = self.highlightView.frame.minX
                        self.lbl.frame.origin.y = self.highlightView.frame.minY
                        self.lbl.text = labels.first?.text
                    }
                    self.currentTrackingID = trackingID
                    print("Input image size: \(imagei.size) \n\nobj bounds: \(bounds) \nratio: \(ratio) \nframeBound: \(frameBound) \n\nDetected Object: \(String(describing: self.lbl.text))")
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

        prevLayer = AVCaptureVideoPreviewLayer(session: session)
        prevLayer.frame.size = view.frame.size
        prevLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        view.layer.addSublayer(prevLayer!)
        highlightView.addSubview(lbl)
        view.addSubview(highlightView)
        
        session.startRunning()
    }
    
    //MARK: - VIEW ROUTINE
    func delegate(){
        
    }
    func layout(){
        highlightView.backgroundColor = .systemYellow
        highlightView.alpha = 0
        lbl = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 45))
    }
    func setup(){
        boundRatio = screenBound.width / screenBound.height
        let options = VisionObjectDetectorOptions()
        options.detectorMode = .stream
        options.shouldEnableMultipleObjects = false
        objectDetector = Vision.vision().objectDetector(options: options)
        prevLayer?.frame.size = view.frame.size
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
