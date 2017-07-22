# SaveAKRecordings
Swift Xcode Project that demonstrates how to record, save, and send audio files, via [AudioKit](http://audiokit.io/).

## Share your audio with:
1. AudioShare SDK
2. Email Composer
3. Messenger
4. AirDrop
5. iTunes File Sharing

## Installation

The AudioKit framework in this project was installed using [Carthage](https://github.com/Carthage/Carthage), but it wasn't included in this repo. In order to install AudioKit to run and build this project successfully, please run the following command in Terminal:

```
cd <path/to/the/SaveAKRecordings repo>
```
**Step 1** - Install Homebrew, if it isn't already installed on your computer

[Homebrew](http://brew.sh/) 

**Step 2** - Install Carthage

```language-powerbash
brew install carthage
```

**Step 3** - Install libraries and frameworks

```language-powerbash
carthage update --platform ios
```
Launch the SaveAKRecordings.xcodeproj file, build, and run the project.

### Note:
You must deploy to an actual device in order to view multiple document files within "Show Recordings."