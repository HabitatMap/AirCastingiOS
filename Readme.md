# AirCasting
[![Testing](https://github.com/HabitatMap/AirCastingiOS/actions/workflows/tests.yml/badge.svg)](https://github.com/HabitatMap/AirCastingiOS/actions/workflows/tests.yml)
[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-green.svg)](https://swift.org)
[![Xcode 12.4](https://img.shields.io/badge/Xcode-12.4-green.svg)](https://developer.apple.com/xcode/)
[![iOS 14.0](https://img.shields.io/badge/iOS-14.0-green.svg)](https://developer.apple.com/ios/)

- [AirCasting](#aircasting)
  * [Fastlane](#fastlane)
    + [Beta](#beta)
    + [Release](#release)
  * [Feature Flags](#feature-flags)
## Fastlane
We use [fastlane](https://fastlane.tools) to automate building and releasing our app. Currently we're using 2 paths of release:
### Beta
This lane is used for beta releases to the [Firebase Distribution](https://firebase.google.com/docs/app-distribution). For this to work you'll need to obtain an `.env.default` file and place it inside Fastlane directory. It contains secret keys used for Firebase communication. 
If you want to integrate the app into your custom setup, provide this file using template:
```
FIREBASE_TOKEN = XXXXX
```
And change the `app` identifier inside Fastfile

### Release
The Release lane will build and release app to the appstoreconnect and Firebase. Versions released this way will be marked as Release Candidate. To run this lane please make sure you're on a branch that follows the `release/X.Y.Z` scheme (replace X.Y.Z with version number, it needs to match the version specified in the project). For firebase release details please refer to the Beta lane documentation.

## Feature Flags
The app uses a concept called [feature flagging](https://martinfowler.com/articles/feature-toggles.html) to control which parts of code are ready to release and when. We're using [Firebase Remote Config](https://firebase.google.com/docs/remote-config) as a backend for those so we can adjust audiences on the fly not having to release new versions of the app. For beta testers there is a convenient AppSettings view which enables to manually flip any flag.
| Configuration  | Firebase | AppSettings |
| ------------- | ------------- | ------------- |
| `DEBUG` | 🛑 | ✅ |
| `BETA` | ✅ | ✅ |
| `RELEASE` | ✅ | 🛑 |
