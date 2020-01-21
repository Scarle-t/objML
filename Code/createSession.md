# The Code

```Swift
    let queue = DispatchQueue(label: "video-frame-sampler")
    
    var session: AVCaptureSession!
    var device: AVCaptureDevice?
    var input: AVCaptureDeviceInput?
    var videoOutput: AVCaptureVideoDataOutput!
    var output: AVCaptureMetadataOutput?
    
    .
    .
    .

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
        
        camview.addSubview(croppedView)
        
        session.startRunning()
    }
```

# Explain

This long code is responsible for the live view we see on screen, and provide the image data we need for ML Kit to work.
Lets break this down.

0. To get all this working, `AVFoundation` must be imported at the top first.
1. In iOS, using camera and getting its data are managed by `AVCaptureSession` (simply called: `session`).
```Swift
/*Global, can pause the session somewhere within the class
You can also do it in a single line if you don't plan to call it somewhere else
*/

var session: AVCaptureSession!

session = AVCaptureSession()
```
2. Once we created a session, we can add inputs and outputs to it.
    - But before adding input, we need to ask the phone 'Do you have capture device available?'
    - So we will get the video deivce by doing `device = AVCaptureDevice.default(for: AVMediaType.video)`
    - This will give us the default rear camera for use, save it as `device` for later use
    
3. To add input, we need to do it the safe way, as some iOS deivces may not have cameras (ie: early iPod and iPad)
    - By using `do...catch` statement we can ensure the app doesn't crash if it cannot use the device
    ```Swift
    do{
        input = try AVCaptureDeviceInput(device: device!)
    }catch{
        print(error.localizedDescription)
        return
    }
    ```

4. After we get the input, we can add it to the `session`
    - This code unwraps the optional `input` and use it safely
    ```Swift
    if let input = input {
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    ```

5. Okay, time to setup the output
    ```Swift
    videoOutput = AVCaptureVideoDataOutput()
    ```

6. The following are video output options that can be work with both ML Kit and CoreML API
    ```Swift
    videoOutput.alwaysDiscardLateVideoFrames = true
    videoOutput.videoSettings = [
          String(kCVPixelBufferPixelFormatTypeKey) : NSNumber(value: kCVPixelFormatType_32BGRA)
                                ]
    ```
    - videoSettings breakdown:
        - `kCVPixelBufferPixelFormatTypeKey`: Key for Pixel Buffer Format Type
        - `kCVPixelFormatType_32BGRA`: Pixel Format Type is 32bit BGRA
        
7. To get the video output and work with it, we need to add `AVCaptureVideoDataOutputSampleBufferDelegate` to our class
    - This delegate comes with some methods for handling output, we will discuss it separately.
    ```Swift
    class YourViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate{ ... }
    ```
    
8. Then we need to bind the delegate to the `videoOutput` by
      ```Swift
      let queue = DispatchQueue(label: "video-frame-sampler")
      .
      .
      .
      videoOutput!.setSampleBufferDelegate(self, queue: queue)
      ```
    - DispatchQueue is like Threads, we do not want to process image data on Main thread, this will show down the app significantly.
    - By doing the heavy lifting on separate thread, we can ensure user gets a smooth UI and not to worry.
    
9. All set, time to add the output safely
      ```Swift
      if session.canAddOutput(videoOutput) {
          session.addOutput(videoOutput)
      }
      ```
      
10. If we run the app now, we will see the video feed is upside down. To fix this, we need to add this
      ```Swift
      session.connections.forEach({$0.videoOrientation = .portrait})
      ```
      - *Breakdown: For each session connections, specify the video orientation to protrait.*

11. Now, we can start the session
    ```Swift
    session.startRunning()
    ```
