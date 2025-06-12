# AirCasting
[![Testing](https://github.com/HabitatMap/AirCastingiOS/actions/workflows/tests.yml/badge.svg)](https://github.com/HabitatMap/AirCastingiOS/actions/workflows/tests.yml)
[![Swift 5.3](https://img.shields.io/badge/Swift-5.3-green.svg)](https://swift.org)
[![Xcode 12.4](https://img.shields.io/badge/Xcode-12.4-green.svg)](https://developer.apple.com/xcode/)
[![iOS 14.0](https://img.shields.io/badge/iOS-14.0-green.svg)](https://developer.apple.com/ios/)

- [AirCasting](#aircasting)
  * [Conventions](#conventions)
    + [Marking technical debt](#marking-technical-debt)
  * [SwiftLint](#swiftlint)
  * [Distributing builds](#Distributing builds)
    + [Certificates and Profiles setup](#certificates-and-profiles-setup)
    + [Releasing a Beta build](#releasing-a-beta-build)
    + [Release](#releasing-an-app-store-build)
  * [Feature Flags](#feature-flags)
  
## Conventions
<a id="tech-debit-marking"></a>
### Marking technical debt
For potential bugs or severe code quality issues:
1. Place warnings in places that can potentially cause a bug (or bugs), and are too big to resolve ad hoc.
2. When placing a warning, add a comprehensive explanation of the issue in the comment. Also link the ticket from `3)` in this comment.
3. Add a ticket to github issues section with correct tag:
    + A "warning" tag for every warning related issue
    + An "AirBeam needed" tag for issues that require an AirBeam to resolve/reproduce

For less severe stuff like minor code quality issues
1. When the problem is not causing bug-level issues, but is too big to resolve ad hoc, add a `// FIXME:` marking in code and explain it **really well**, so that someone with more time that stumbles across this will be able to fully understand and refactor/fix. Also link the ticket from `2)` in this comment.
2. Add a ticket to github issues section with correct tag:
    * A "code quality" tag for quality issues
    * An "AirBeam needed" tag for issues that require an AirBeam to resolve/reproduce

## SwiftLint
We use [swiftlint](https://github.com/realm/SwiftLint) to preserve clean code.
Please, install it first using Homebrew: `brew install swiftlint`

## Distributing builds
### Certificates and Profiles setup
Once your Apple ID is added to the project:
1. Create, download and install (by clicking the downloaded file) into your keychain two types of [certificates](https://developer.apple.com/account/resources/certificates/list):
   - Apple Development
   - Apple Distribution
2. Create, download and install (by clicking the downloaded file) two types of [profiles](https://developer.apple.com/account/resources/profiles/list):
   - AD Hoc Distribution (connect the aforementioned Apple distribution certificate by selecting it from the list)
   - App Store distribution
### Releasing a Beta build
1. In XCode project navigator select **AirCasting** > **Signing & Capabilities** > **Signing**, verify that the Ad Hoc Distribution provisioning profile is selected
   * Potential issues
       - You might need to uncheck **Automatically manage signing** checkbox
       - You might need to download the profile by going to **XCode** > **Settings** > **Accounts** > **Download Manual Profiles** for HabitatMap Inc.
2. Set scheme to Beta (**Product** > **Scheme** > **Edit Scheme** > **Archive** > **Build configuration**)
3. Generate Archive (**Product** > **Archive**)
4. Go to Archive window, select the generated archive and click **Distribute App** > **Custom** > **Release testing**, go through the wizard, navigate to the generated folder, upload the IPA file to [Firebase distribution](https://console.firebase.google.com/u/0/project/ios-aircasting-app/appdistribution/app/ios:org.habitatmap.AirCasting/releases)
### Releasing an App Store build
1. In XCode project navigator select **AirCasting** > **Signing & Capabilities** > **Signing**, verify that the Ad Hoc Distribution provisioning profile is selected
    * Potential issues
        - You might need to uncheck **Automatically manage signing** checkbox
        - You might need to download the profile by going to **XCode** > **Settings** > **Accounts** > **Download Manual Profiles** for HabitatMap Inc.
2. Set scheme to Release (**Product** > **Scheme** > **Edit Scheme** > **Archive** > **Build configuration**)
3. Generate Archive (**Product** > **Archive**)
4. Go to Archive window, select the generated archive and click **Distribute App** > **App Store Connect**, go through the wizard
5. Select the newly distributed build in [App Store Connect Distribution](https://appstoreconnect.apple.com/apps/1587685281/distribution/ios/version/inflight) and release it

## Feature Flags
The app uses a concept called [feature flagging](https://martinfowler.com/articles/feature-toggles.html) to control which parts of code are ready to release and when. We're using [Firebase Remote Config](https://firebase.google.com/docs/remote-config) as a backend for those so we can adjust audiences on the fly not having to release new versions of the app. For beta testers there is a convenient AppSettings view which enables to manually flip any flag.
| Configuration  | Firebase | AppSettings |
| ------------- | ------------- | ------------- |
| `DEBUG` | 🛑 | ✅ |
| `BETA` | ✅ | ✅ |
| `RELEASE` | ✅ | 🛑 |
