 # Train model with Apple Turi Create
  iOS app can utilize Core ML to update model on the fly, however it still need a starting ground. This readme will demonstrate how to create a model and how to use in XCode.

# Preparation
*Software*
- coreml-training-tools
- Turi Create
- [ImageNet](http://www.image-net.org)

# Setup

- Download Image from ImageNet
    1. Clone [jigsawxyz/coreml-training-tools](https://github.com/jigsawxyz/coreml-training-tools)
    1. Extract the file
    1. Open Terminal
    1. on Finder, Navigate to `coreml-training-tools-master > download-images` and copy as pathname
    1. Back to Terminal, `cd` to the path and run `npm install`
        - In some case, it will show 'Permission denied'. Run `sudo npm install` instead

- Model Training
    1. First install virtual environment
       1. Open Terminal, type `pip install virtualenv`
          - In some case, it will show 'Permission denied'. Run `sudo pip install virtualenv` instead
          - If Terminal returns pip is not install, run `sudo easy_install pip` first
       1. Once completed, run `cd ~` following with `virtualenv venv` to create the virtual environment
       1. Then run `source ~/venv/bin/activate` to start the virtual environment
       1. Terminal will become this
       ![](https://i.imgur.com/Z1bRS1H.png)
     1. Then install Turi Create in the virtual environment by running `pip install -U turicreate`
        - Make sure you are inside virtual evironment by checking `(venv)` is shown next to your username
        - e.g.: **(venv)** user@macbook ~ %
        
 
# Usage

- ImageNet and download image in batch
   - Search for a training category like chair or plant
   - Select a suitable synset
   - Inside the synset, go to Downloads tab, click on URLs
   - You will see a list of urls, these are image URLs in the synset
   - Copy the URL of this page (not the list of URLs)
     - e.g.: `http://www.image-net.org/api/text/imagenet.synset.geturls?wnid=n03376595`
   - Open Terminal, `cd` into 'download-images'
   - Run `node download-imagenet-files '*link*' *category*`
     - *link*: The ImageNet URL copied beofre
     - *category* Training category created by yourself
     - e.g.: `node download-imagenet-files.js 'http://www.image-net.org/api/text/imagenet.synset.geturls?wnid=n03376595' chair`
   - Wait for the download and repeat the step for false images (non-chair), category name needs to be different

- Create Core ML Model
   - Start vitural environment in Terminal
   - `cd` to 'train-model'
   - Run `python train-model.py` to start creating the model
   - Once complete, go to 'train-model' folder and you will find `Classifier.mlmodel` file (not folder)

- Xcode Usage
   - Drag the 'Classifier.mlmodel' into XCode Project navigator under project root
     - Options
     ![](https://i.imgur.com/3rh9EUy.png)
     ![](https://i.imgur.com/uJZuLkX.png)
   - Select the model in XCode, a Class should be automatically generated
     - It includes multiple predict functions, we will focus on 
     ```swift 
     func prediction(image: CVPixelBuffer) throws -> ClassifierOutput
     ```
   - Select the model file to see what is the input and output
     - However, CVPixelBuffer is used in image-based model, passing an Image directly into the model resulting in errors
   - For image-based model, the predictions are as follows
   
   Type | Data
   ----- | -----
   Input | Image (CVPixelBuffer, 224x224 Color image)
   Output | Probability (String -> Double)
   Output | Label (Category trained previously)
