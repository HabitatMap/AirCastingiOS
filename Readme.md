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
This lane is used for beta releases to the [Firebase Distribution](https://firebase.google.com/docs/app-distribution). In order to deploy a beta build:
1. `cd` into top project directory
2. make sure you'll on a `develop` branch and your git status is clean
3. run `fastlane beta`
4. after fastlane finsishes you'll find yourself on a version branch `beta/${new_version_number}`. Make a PR out of it and merge it immediately into `develop`  

### Release
The Release lane will build and release the app to the appstoreconnect and Firebase. Versions released this way will be marked as Release Candidate (RC). To run this lane:
1. `cd` into top project directory
2. make sure you're on a branch that follows the `release/X.Y.Z` scheme (replace X.Y.Z with version number, it needs to match the version specified in the project) and your git status is clean
3. run `fastlane release`
4. after fastlane finishes push the release branch to repo, but don't make a PR out of it
5. bump version number to the next one on `develop` 

### Integration
For the fastlane setup to work you'll need to obtain an `.env.default` file and place it inside Fastlane directory. It contains secret keys used for Firebase communication and appstore connect key details. 
If you want to integrate the app into your custom setup, provide this file using template:
```
FIREBASE_TOKEN = XYZ
APPSTORE_KEY_ID = XYZ
APPSTORE_ISSUER_ID = XYZ
```
And change the `app` identifier inside Fastfile.

You'll also need an `AuthKey.p8` (an appstoreconnect API key) file placed inside Fastlane directory

## Feature Flags
The app uses a concept called [feature flagging](https://martinfowler.com/articles/feature-toggles.html) to control which parts of code are ready to release and when. We're using [Firebase Remote Config](https://firebase.google.com/docs/remote-config) as a backend for those so we can adjust audiences on the fly not having to release new versions of the app. For beta testers there is a convenient AppSettings view which enables to manually flip any flag.
| Configuration  | Firebase | AppSettings |
| ------------- | ------------- | ------------- |
| `DEBUG` | 🛑 | ✅ |
| `BETA` | ✅ | ✅ |
| `RELEASE` | ✅ | 🛑 |
