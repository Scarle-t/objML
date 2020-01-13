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
    1.
