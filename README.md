# SaveAKRecordings
Swift Xcode Project that demonstrates how to record, save, and send audio files, via [AudioKit](http://audiokit.io/).

## Share your audio with:
1. AudioShare SDK
2. Email Composer
3. Messenger
4. AirDrop
5. iTunes File Sharing

## Installation:
1. Within Terminal, run `git clone git@github.com:markjeschke/SaveAKRecordings.git` in the command line, or download the [zip](https://github.com/markjeschke/SaveAKRecordings/archive/master.zip) to your local drive.
2. If you have CocoaPods already installed, run `pod install` to install the AudioKit framework.
3. Open the `SaveAKRecording.xcworkspace` source, and build the app to your iPhone or iPad.

### If you don't have CocoaPods installed, please follow these directions:

1. Within Terminal, enter `$ sudo gem install cocoapods` in the command line.
2. Change directory, so that you'll be in the root directory of this "SaveAKRecording" Xcode project. 
3. Run `pod install` to install the pods that are listed in the Podfile.
4. Once the installation has completed, open the project by clicking to open `SaveAKRecording.xcworkspace` – not the `SaveAKRecording.xcodeproj`.

If you're having trouble installing CocoaPods, please refer to their [installation instructions](https://cocoapods.org/#install).

### Note:
You must deploy to an actual device in order to view multiple document files within "Show Recordings."
