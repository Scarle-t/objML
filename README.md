# objML
**This Project contains basic *Proof-of-concept* code with Google ML Kit Vision API, demonstrating how Object Detection/ Tracking and Image Labeling can be implemented together**

*Some files are intentionally left out, this only contains the code of the app*

# Preparation
**Hardware**
- device with macOS (iMac, Macbook)
- iOS device with camera, iPhone X and newer is preferred.

**Software**
- XCode
- CocoaPods

**Online**
1. Go to [Firebase](https://firebase.google.com) and create a new project
1. No need to follow the guidelines one-by-one, this readme contains all information you need
1. When creating a new project for iOS, it may ask you to verify the connection, skip if for now
1. Download the GoogleService-Info.plist it generated, it will be used later
1. Decide upgrade to Blaze for Cloud API or not. [*See Pricing*](https://firebase.google.com/pricing)

Spark Plan (Free) | Blaze Plan (Pay as you use)
------------ | -------------
on Device Vision API (Object detection and tracking, image labeling) | Cloud API (Precise image labeling)

**Local**
1. Get CocoaPods
    - Open Terminal, type ``` sudo gem install cocoapods ```
    - Enter Super User password, it should be the same with your macOS account password
    - Wait for the installation
1. Create a new XCode Project
    - Choose Single View App under iOS tab
    - Configure as following

Field | Value
------------ | -------------
Product Name | *Create your own*
Language | Swift
User Interface | Storyboard

  - And leave these options unchecked
  - [ ] Use Core Data
  - [ ] Include Unit Test
  - [ ] Include UI Tes
  
    - When creating a new project, copy the Bundle ID from Firebase you created earlier.
    ![](https://i.imgur.com/AmO52sK.png)
  - Your project configuration will look like this
  ![](https://i.imgur.com/xhsG6bc.png)
  - After the project has been created, close XCode
3. Prepare for CocoaPods
    - Open Finder, navigate to the XCode project directory created earlier
    - In the Finder Window, find a gear icon on the top, click it and choose ```copy ... as Pathname```
    ![](https://i.imgur.com/3Je7TNA.png)
    - Go back to Terminal, type ``` cd "..."``` then paste the path you copied before inside the qoute
    - *(eg: ```cd "/Users/scarlet/Documents/App/visionAPITest"``` )*
    - You will see the directory name appear on the left
    ![](https://i.imgur.com/8NNphvb.png)
    - Type ``` pod init``` to initiate CocoaPods
    - After it has finished, type ```nano Podfile``` to open the Podfile Cocoapods created during initialzation
    - Terminal window will change to nano editor, copy and paste the following under the line ``` # Pods for ...```
    ```Ruby
    pod 'Firebase/Analytics'
    pod 'Firebase/MLVision'
    pod 'Firebase/MLVisionLabelModel'
    pod 'Firebase/MLVisionObjectDetection'
    ```
    - These are Pods for Google Firebase Vision API, including ML Kit Vision Image Label (Both on device and Cloud) and on device ML Kit Vision Object Detection. New pods can be added when needed using same method
    - Your nano will look like this
    -![](https://i.imgur.com/p8RZhsl.png)
    - Once finish, press control-O to write to file, Return to confirm and control-X to leave nano
    - Back to Terminal, type ```pod install``` to download and install the Pods we specific in the Podfile
    - After all Pods have been downloaded, CocoaPods will create a ```.xcworkspace``` file, always open this Workspace file when working with this project, otherwise Firebase will not be loaded correctly.
4. Add Firebase to project
    - Open the workspace file, drag the GoogleService-Info.plist file into the root of Project Navigator
    ![](https://i.imgur.com/X8RYguX.png)
    - Follow these options
    ![](https://i.imgur.com/PSK5oT3.png)
    - Open `AppDelegate.swift`
    - Under
    ```Swift
    import UIKit
    ```
    - Add
    ```Swift
    import Firebase
    ```
    - Any other Swift file needs this line if Vision API if needed
    - Then, inside the function
    ```Swift
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    ```
    - Add
    ```Swift
    FirebaseApp.configure()
    ```
    - before ```return true```
    - Your ```AppDelegate.swift``` will look like this
  ```Swift
  //
//  AppDelegate.swift
//  visionAPITest
//
//  Created by Scarlet on A2020/J/7.
//  Copyright © 2020 Scarlet. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}
```
 
 
*All preparation have been completed*
