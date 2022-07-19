// Created by Lunar on 23/06/2021.
//
import SwiftUI

/// NSLocalizedString is used here, to easly localize every string that is used inside AirCasting app. This allows XCode to identify every string and export all of them in one file.
/// Please, always use below convention:
/// EXAMPLE:
/// static let [name of variable]: String = NSLocalizedString("[Text here]",
///                                             comment: " ")
struct Strings {
    enum Commons {
        static let cancel: String = NSLocalizedString("Cancel",
                                                      comment: "")
        static let ok: String = NSLocalizedString("OK",
                                                  comment: "")
        static let myAccount: String = NSLocalizedString("My account"
                                                         , comment: "")
        static let `continue`: String = NSLocalizedString("Continue",
                                                          comment: "")
        static let gotIt: String = NSLocalizedString("Got it!",
                                                     comment: "")
        static let note: String = NSLocalizedString("Note",
                                                    comment: "")
    }
    
    enum Settings {
        static let title: String = NSLocalizedString("Settings",
                                                     comment: "")
        static let myAccount: String = NSLocalizedString("My Account",
                                                         comment: "")
        static let crowdMap: String = NSLocalizedString("Contribute to CrowdMap",
                                                        comment: "")
        static let crowdMapDescription: String = NSLocalizedString("Data contributed to the CrowdMap is publicly available at aircasting.org", comment: "")
        static let disableMapping: String = NSLocalizedString("Disable Mapping",
                                                              comment: "")
        static let disableMappingDescription: String = NSLocalizedString("Turns off GPS tracking & session syncing. Use \"Share file\" to retrieve your measurements via email.",
                                                                         comment: "")
        static let temperature = NSLocalizedString("Temperature Units",
                                                   comment: "")
        static let celsiusDescription = NSLocalizedString("Use Celsius",
                                                          comment: "")
        static let backendSettings: String = NSLocalizedString("Backend settings",
                                                               comment: "")
        static let settingsHelp: String = NSLocalizedString("Help",
                                                            comment: "")
        static let hardwareDevelopers: String = NSLocalizedString("Hardware developers",
                                                                  comment: "")
        static let about: String = NSLocalizedString("About AirCasting",
                                                     comment: "")
        static let keepScreenTitle = NSLocalizedString("Keep screen on",
                                                       comment: "")
        static let clearSDTitle = NSLocalizedString("Clear SD card",
                                                    comment: "")
        static let appInfoTitle = NSLocalizedString("AirCasting App v",
                                                    comment: "")
        static let buildText = NSLocalizedString("build",
                                                 comment: "")
        static let satelliteMap = NSLocalizedString("Satellite map",
                                                       comment: "")
        static let twentyFourHourFormat = NSLocalizedString("Use 24-hour format",
                                                       comment: "")
        static let syncOnlyThroughWifi = NSLocalizedString("Sync only through Wi-Fi", comment: "")
        static let crashlyticsSectionTitle = "Crashlytics integration testing:"
        
        static let appConfig = "App config"
        
        static let shareLogs = "Share logs"
        
        static let crashTheApp = "Crash the app"
        
        static let generateError = "Generate error"
        
        static let betaBuild = "Beta build"
        
        static let debugBuild = "Debug build"
    }
    
    enum BackendSettings {
        static let backendSettings: String = NSLocalizedString("Backend settings",
                                                               comment: "")
        static let alertTitle: String = NSLocalizedString("Logout Alert",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("Something went wrong, when logging out.",
                                                            comment: "")
        static let currentURL: String = NSLocalizedString("current url",
                                                          comment: "")
        static let currentPort: String = NSLocalizedString("current port",
                                                           comment: "")
    }
    
    enum MyAccountSettings {
        static let notLogged: String = NSLocalizedString("You aren’t currently logged in",
                                                         comment: "")
        static let createAccount: String = NSLocalizedString("Create an account",
                                                             comment: "")
        static let logIn: String = NSLocalizedString("Log In",
                                                     comment: "")
    }
    
    enum SignOutSettings {
        static let logged: String = NSLocalizedString("You are currently logged in as ",
                                                      comment: "")
        static let signOut: String = NSLocalizedString("Sign Out",
                                                       comment: "")
        static let deleteAccount: String = NSLocalizedString("Delete Account",
                                                             comment: "")
    }
    
    enum ForgotPassword {
        static let title = NSLocalizedString("Forgot Password",
                                             comment: "")
        static let emailInputTitle = NSLocalizedString("email or username",
                                                       comment: "")
        static let newPasswordSuccessMessage = NSLocalizedString("Email was sent. Please check your inbox for the details.",
                                                                 comment: "")
        static let newPasswordSuccessTitle = NSLocalizedString("Email response",
                                                               comment: "")
        static let newPasswordFailureMessage = NSLocalizedString("Something went wrong, please try again",
                                                                 comment: "")
        static let newPasswordFailureTitle = NSLocalizedString("Email response",
                                                               comment: "")
    }
    
    enum SignInView {
        static let signIn_1 = NSLocalizedString("Sign in",
                                                comment: "It consists of few parts. Please consider them together. Whole text is following: Sign In to record and map your environment")
        static let signIn_2 = NSLocalizedString("to record and map your environment",
                                                comment: "")
        static let usernameField = NSLocalizedString("Profile name",
                                                     comment: "")
        static let passwordField = NSLocalizedString("Password",
                                                     comment: "")
        static let forgotPasswordButton = NSLocalizedString("Forgot password?",
                                                            comment: "")
        static let signUpButton_1 = NSLocalizedString("First time here? ",
                                                      comment: "It consists of few parts. Please consider them together. Whole text is following: First time here? Create an account")
        static let signUpButton_2 = NSLocalizedString("Create an account",
                                                      comment: "")
        static let alertTitle = NSLocalizedString("Login Error",
                                                  comment: "")
        static let alertComment = NSLocalizedString("Login Error alert title",
                                                    comment: "")
        static let InvalidCredentialText = NSLocalizedString("The profile name or password is incorrect. Please try again. ",
                                                             comment: "")
        static let noConnectionTitle = NSLocalizedString("No Internet Connection",
                                                         comment: "")
        static let noConnectionText = NSLocalizedString("Please make sure your device is connected to the internet.",
                                                        comment: "")
        static let loggingOutInBackground: String = NSLocalizedString("Currently logging out in the background. You can fill out credentials.", comment:  "")
    }
    
    enum SessionShare {
        static let title: String = NSLocalizedString("Share session",
                                                     comment: "")
        static let description: String = NSLocalizedString("Select a stream to share",
                                                           comment: "")
        static let locationlessDescription: String = NSLocalizedString("Generate a CSV file with your session data",
                                                                       comment: "")
        static let emailDescription: String = NSLocalizedString("Or email a CSV file with your session data",
                                                                comment: "")
        static let emailPlaceholder: String = NSLocalizedString("Email",
                                                                comment: "")
        static let linkSharingAlertTitle: String = NSLocalizedString("Sharing failed",
                                                                     comment: "")
        static let linkSharingAlertMessage: String = NSLocalizedString("Try again later",
                                                                       comment: "")
        static let emailSharingAlertTitle: String = NSLocalizedString("Request failed",
                                                                      comment: "")
        static let emailSharingAlertMessage: String = NSLocalizedString("Please try again later",
                                                                        comment: "")
        static let shareLinkButton: String = NSLocalizedString("Share link",
                                                               comment: "")
        static let shareFileButton: String = NSLocalizedString("Share file",
                                                               comment: "")
        static let loadingFile: String = NSLocalizedString("Generating file",
                                                           comment: "")
        static let invalidEmailLabel: String = NSLocalizedString("This email is invalid",
                                                                 comment: "")
        static let sharedEmailText: String = NSLocalizedString("View my AirCasting session", comment: "")
    }
    
    enum LoadingSession {
        static let title: String = NSLocalizedString("Your AirBeam is gathering data.",
                                                     comment: "")
        static let description: String = NSLocalizedString("Measurements will appear in 3 minutes.",
                                                           comment: "")
    }
    
    struct SessionCartView {
        static let map: String = NSLocalizedString("map",
                                                   comment: "")
        static let graph: String = NSLocalizedString("graph",
                                                     comment: "")
        static let follow: String = NSLocalizedString("follow",
                                                      comment: "")
        static let unfollow: String = NSLocalizedString("unfollow",
                                                        comment: "")
        static let avgSessionH: String = NSLocalizedString("1 hr avg -",
                                                           comment: "")
        static let avgSessionMin: String = NSLocalizedString("1 min avg -",
                                                             comment: "")
    }
    
    struct SingleMeasurementView {
        static let microphoneUnit: String = NSLocalizedString("dB",
                                                              comment: "")
        static let celsiusUnit: String = NSLocalizedString("C",
                                                           comment: "")
        static let fahrenheitUnit: String = NSLocalizedString("F",
                                                              comment: "")
    }
    
    enum SelectPeripheralView {
        static let airBeamsText: String = NSLocalizedString("AirBeams",
                                                            comment: "")
        static let otherText: String = NSLocalizedString("Other devices",
                                                         comment: "")
        static let alertTitle: String = NSLocalizedString("Connection error",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("Bluetooth connection failed. Please toggle the power on your device and try again.",
                                                            comment: "")
        static let titleLabel: String = NSLocalizedString("Choose the device you'd like to record with",
                                                          comment: "")
        static let titleSyncLabel: String = NSLocalizedString("Select the device you'd like to sync",
                                                              comment: "")
        static let titleSDClearLabel: String = NSLocalizedString("Select the device you'd like to clear",
                                                                 comment: "")
        static let refreshButton: String = NSLocalizedString("Don't see a device? Refresh scanning.",
                                                             comment: "")
        static let connectText: String = NSLocalizedString("Connect",
                                                           comment: "")
    }
    
    enum SessionCart {
        static let measurementsTitle: String = NSLocalizedString("Last second measurement:",
                                                                 comment: "")
        static let dormantMeasurementsTitle: String = NSLocalizedString("Avg value:",
                                                                        comment: "")
        static let heatmapSettingsTitle: String = NSLocalizedString("Heatmap settings",
                                                                    comment: "")
        static let heatmapSettingsdescription: String = NSLocalizedString("Values beyond Min and Max will not be displayed.",
                                                                          comment: "")
        static let saveChangesButton: String = NSLocalizedString("Save changes",
                                                                 comment: "")
        static let resetChangesButton: String = NSLocalizedString("Reset to default",
                                                                  comment: "")
        static let parametersText: String = NSLocalizedString("Parameters:",
                                                              comment: "")
        static let lastMinuteMeasurement: String = NSLocalizedString("Last minute measurement",
                                                                     comment: "")
        static let keyboardToolbarDoneButton: String = NSLocalizedString("Done", comment: "")
    }
    
    enum Thresholds {
        static let veryHigh: String = NSLocalizedString("Max",
                                                        comment: "")
        static let high: String = NSLocalizedString("High",
                                                    comment: "")
        static let medium: String = NSLocalizedString("Medium",
                                                      comment: "")
        static let low: String = NSLocalizedString("Low",
                                                   comment: "")
        static let veryLow: String = NSLocalizedString("Min",
                                                       comment: "")
    }
    
    enum WifiPopupView {
        static let wifiPlaceholder: String = NSLocalizedString("Wi-Fi name",
                                                               comment: "")
        static let passwordPlaceholder: String = NSLocalizedString("Password",
                                                                   comment: "")
        static let connectButton: String = NSLocalizedString("Connect",
                                                             comment: "")
        static let passwordTitle: String = NSLocalizedString("WiFi network name & password:",
                                                             comment: "")
        static let nameAndPasswordTitle: String = NSLocalizedString("Password for %@ network",
                                                                      comment: "")
        static let differentNetwork: String = NSLocalizedString("Connect to a different WiFi network.",
                                                                comment: "")
    }
    
    enum OnboardingGetStarted {
        static let description: String = NSLocalizedString("record and map measurements from health and environmental monitoring devices",
                                                           comment: "")
        static let getStarted: String = NSLocalizedString("Get started",
                                                          comment: "")
    }
    
    enum OnboardingNearAir {
        static let title: String = NSLocalizedString("How’s the air near you?",
                                                     comment: "")
        static let description: String = NSLocalizedString("Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now.",
                                                           comment: "")
    }
    
    enum OnboardingAirBeam {
        static let title: String = NSLocalizedString("Measure and map your exposure to air pollution",
                                                     comment: "")
        static let description: String = NSLocalizedString("Connect AirBeam to measure air quality humidity, and temperature.",
                                                           comment: "")
        static let sheetButton: String = NSLocalizedString("Learn More",
                                                           comment: "")
    }
    
    enum OnboardingAirBeamSheet {
        static let sheetTitle: String = NSLocalizedString("How AirBeam works?",
                                                          comment: "")
        static let sheetDescription_1: String = NSLocalizedString("In mobile mode, the AirBeam captures personal exposures. In fixed mode, it can be installed indoors or outdoors to keep tabs on pollution levels in your home, office, backyard, or neighborhood 24/7.",
                                                                  comment: "")
        static let mobile: String = NSLocalizedString("mobile",
                                                      comment: "")
        static let fixed: String = NSLocalizedString("fixed",
                                                      comment: "")
        static let sheetDescription_3: String = NSLocalizedString("mode, the AirBeam captures personal exposures. In ",
                                                                  comment: "")
        static let sheetDescription_4: String = NSLocalizedString("fixed ",
                                                                  comment: "")
        static let sheetDescription_5: String = NSLocalizedString("mode, it can be installed indoors or outdoors to keep tabs on pollution levels in your home, office, backyard, or neighborhood 24/7.",
                                                                  comment: "")
    }
    
    enum OnboardingPrivacy {
        static let title: String = NSLocalizedString("Your privacy",
                                                     comment: "")
        static let description: String = NSLocalizedString("Review our commitment to preserving your privacy and accept our privacy policy.",
                                                           comment: "")
        static let continueButton: String = NSLocalizedString("Accept",
                                                              comment: "")
        static let sheetButton: String = NSLocalizedString("Learn More",
                                                           comment: "")
    }
    
    enum OnboardingPrivacySheet {
        static let title: String = NSLocalizedString("Our privacy policy",
                                                     comment: "")
        static let description: String = NSLocalizedString("""
        HabitatMap protects the personal data of AirCasting mobile application users, and fulfills conditions deriving from the law, especially from the Regulation (EU) 2016/679 of the European Parliament and of the Council of 27 April 2016 on the protection of natural persons with regard to the processing of personal data and on the free movement of such data, and repealing Directive 95/46/EC (GDPR). HabitatMap protects the security of the data of AirCasting app users using appropriate technical, logistical, administrative, and physical protection measures. AirCasting ensures that its employees and contractors are given training in protection of personal data.
            This privacy policy sets out the rules for HabitatMap’s processing of your data, including personal data, in relation to your use of the AirCasting mobile application.
 
            Personal Data Controller
            The controller of your personal data is HabitatMap Incorporated, with its registered office located at 34A St Marks Avenue, Brooklyn, NY 11217 USA
 
            Contact Details of the Personal Data Controller
            You can contact the data controller:
            postal address: 34A St Marks Avenue, Brooklyn, NY 11217 USA
            e-mail address: info@habitatmap.org
 
            Categories of Personal Data
            1. Data Obtained Directly from Users of the AirCasting App
 
            HabitatMap controls the personal data that you provide when using the AirCasting mobile app, including the following types of data:
            E-mail address;
            Information regarding your request to receive email newsletters;
            Any data you provide when communicating with HabitatMap via email;
            Location data;
 
            Providing the above mentioned data is voluntary. In addition, you can modify your location sharing settings and withdraw the consent to receive email newsletters at any time.
 
            HabitatMap’s AirCasting app and AirCasting website neither request any personally identifiable information nor require any personally identifiable information. Before using the AirCasting app, you must create a profile name and provide an email address. Neither your profile name nor email address need to include information that identifies you personally. In addition, we do not verify email addresses, so the email address provided need not be valid. Though it should be noted, an invalid email address will prevent you from recovering your account in the event you forget your password.
 
            Location: The AirCasting app collects location data to enable geolocation of your health and environmental monitoring measurements. When recording a mobile session, the app will track your location even when the app is closed or not in use. The AirCasting app has several features that enable location data to remain private. AirCasters can “disable maps” in the app settings, which turns off GPS tracking. When AirCasters record data with the GPS disabled, the data never leaves the Android device and is never synced to our servers. AirCasters can elect to save their data to the AirCasting server but not contribute it to the “CrowdMap”. This means the data can only be viewed on the website via a link that you generate inside the app when signed in. AirCasters can also elect to send the data from the app directly to their own server, entirely bypassing the AirCasting server. In addition, when recording fixed indoor sessions, GPS coordinates are never logged.
 
            Microphone: To record sound level measurements, the AirCasting app requests permission to access your microphone. The raw audio captured by AirCasters’ microphones is never recorded; rather the audio signal is immediately converted to a sound level measurement before it is stored on the phone and communicated to the AirCasting server.
 
            Phone Status: To record sound level measurements, the AirCasting app requests permission to read your phone’s state. Knowing the state of an AirCaster’s phone allows the app to temporarily suspend the recording of sound level measurements during phone calls.
 
            USB Storage: To attach photos to notes, the AirCasting app requests permission to read the contents of your USB storage.
 
            2. Data Received by HabitatMap from Third Parties
 
            HabitatMap may also be considered as the controller of the personal data you provide to the operators of the systems you use that are integrated into the AirCasting app, e.g. Android (Google LLC). This may include data such as your IP address or your device identifier. Despite being considered as the data controller, HabitatMap has no direct access to this data, meaning the data are not visible to HabitatMap. However, the processing of this data is necessary to enable the proper functioning of the HabitatMap AirCasting mobile app.
 
            HabitatMap may also have access to data that may (but not necessarily) be considered personal data. In order to maintain, improve, and develop the app, and to customize some of the app content to your preferences, HabitatMap uses information received through or provided by third party tools, with similar functions to cookies. This may include information such as the identifiers of the mobile devices you use, the language of the device, the time the app is opened, and other data you have provided to the entity that owns such a tool (see below for more details about tracking tools).
 
            Providing this data is voluntary and does not affect your ability to use the AirCasting mobile application. The rules for sharing the concerned data are defined by the entities that own such tools (see below for more details on tracking tools).
 
            Purposes & Legal Basis for the Processing of Personal Data
            Your personal data may be processed for the purpose of:
 
            1. Performing a contract, or taking an action at your request prior to the conclusion of a contract, and for the purpose of pursuing claims under the contract (Article 6(1)(b) and (f) GDPR).
 
            HabitatMap processes your personal data to enable you to fully enjoy all the features of the AirCasting mobile app. Information, such as the fact of downloading the application and providing you with relevant content, may also be processed after the contract expiration (uninstallation of the app), among others, in the event of HabitatMap being accused of incorrect performance of its obligations.
 
            2. Providing you, upon your request, with information about the state of air quality at your location, which is in the exercise of HabitatMap’s legitimate interest (Article 6(1)(f) GDPR).
 
            At your request, HabitatMap processes geolocation data to allow you to see the status of air quality at your location in the AirCasting app.
 
            At your request, HabitatMap may also send you PUSH notifications about the air quality status at your location.
 
            Sending notifications and access to geolocation data is voluntary and takes place with your consent, which can be withdrawn at any time, without prejudice to the use of other application functions.
 
            3. Contacting you, at your request, and responding to your questions, which are in the exercise of HabitatMap’s legitimate interest (Article 6(1)(f) GDPR).
 
            HabitatMap allows you to send inquiries and suggestions for improvements to the app via email and will process the email address you provide for this purpose.
 
            4. Maintaining, improving, and developing the application, and customizing some of the app content to your preferences, which are in the exercise of HabitatMap’s legitimate interest (Article 6(1)(f) GDPR).
 
            HabitatMap processes information that may (but not necessarily) be considered personal data, using third-party-provided tools that perform similar functions to cookies to maintain, improve, and develop the app and to customize some of the content to your preferences.
 
            How HabitatMap collects your personal data?
 
            HabitatMap has direct access only to the personal data you have provided.
 
            Some of the information about you that may (but not necessarily) be considered personal data is processed by HabitatMap through the use of tools that perform similar functions to cookies, provided to HabitatMap by third-party providers (referred to below).
 
            Tracking Tools and Automated Decision-making
 
            HabitatMap uses the Firebase Analytics tool provided by Google LLC, which performs similar functions to cookies. In order to maintain, improve, and develop the app, and to customize some of the app content to your preferences, HabitatMap uses information provided by Firebase Analytics. This information may include the identifiers of the mobile devices you use, the language of the device, the time the app is opened, and other data you have provided to Google.
 
            HabitatMap is not able to recognize your identity from the data provided by Firebase Analytics. Information about Firebase Analytics and how it works can be found here: https://policies.google.com/technologies/ads and https://firebase.google.com/terms/.
 
            Data regarding your location may be used for the purpose of automated decision making, consisting in sending information regarding the current quality of air pollution in your location. Automated decision making for the purposes referred to above depends on your consent, which may be withdrawn at any time, without prejudice to the use of the other application functions.
 
            Categories of the Recipients of Personal Data
 
            For the purposes mentioned above and in particular to enable you to use the AirCasting mobile app, your data may be shared with HabitatMap’s trusted partners. HabitatMap will only share data that are necessary for the purposes of the processing indicated above and only for the fulfillment of these purposes. HabitatMap ensures that your data is shared with the third parties in compliance with the security rules provided by law (in particular the GDPR) as well as in accordance with the provisions of this Privacy Policy.
 
            Your personal data may be processed by entities such as:
            HabitatMap’s employees and/or contractors;
            legal and/or accounting services providers;
            hosting and/or cloud computing services providers;
            e-mail service providers;
            software as a service providers enabling HabitatMap internal communication, project, and task management;
            providers of tools that perform similar functions to cookies.
 
            Recipients of Personal Data Outside the European Economic Area
 
            In order to enable you to use the app, communicate with HabitatMap, send you notifications upon your request, and maintain, improve, and develop the app, and customize some of its content to your preferences, Google LLC, which is an entity located outside the European Economic Area (EEA), may be a recipient of your personal data.
 
            HabitatMap transfers personal data to recipients outside the European Economic Area (so-called recipients from third countries) with the principles set out in Chapter V of the GDPR. In connection with the above, the transfer of your personal data to a third country may take place on the basis of the following legal mechanisms:
            standard contractual clauses – HabitatMap transfers personal data to entities outside the EEA that have committed to use standard contractual clauses and ensure an adequate level of security of the personal data received. There are currently three decisions by the European Commission on standard contractual clauses: (i) Decision 2001/497/EC; (ii) Decision 2004/915/EC; (iii) Decision 2010/87/EU. The content of all decisions is available in the Database of European Union legal acts at http://eur-lex.europa.eu;
            performance of the contract – in some exceptional cases, when the recipient of the data from the third country has not committed to the application of standard contractual clauses, your data may be transferred if it is necessary for the performance of the contract between you and HabitatMap or for the implementation of pre-contractual measures taken on your request;
            your consent – if none of the above grounds for transferring data to a recipient outside the EEA is applicable, HabitatMap will transfer your data to a third-country recipient only with your express consent. However, we would like to inform you that in this case there is a risk of not ensuring adequate protection of your personal data, in connection with their transfer to a recipient outside the EEA.
 
            Period of Personal Data Storage
 
            Your personal data will be processed:
            no longer then until the execution of the agreement (i.e. until you uninstall the AirCasting app), and after its execution until the expiry of the statute of limitations for claims related to the agreement (as a rule, a three-year statute of limitations);
            in case of processing of personal data for the marketing purposes, until such processing is objected to (Article 21(1) of the GDPR) or until the withdrawn of the consent to receive information of a marketing nature;
            where the processing of personal data is based on your consent or permission (e.g. processing of your geo-location data) - until it is withdrawn.
 
            Rights of the Data Subject
 
            You have the right to:
            access to personal data – you can obtain information on, inter alia, what personal data are processed by HabitatMap, for what purposes, to whom they are made available, for what period of time they are processed, etc;
            rectify and delete the personal – you may request your data to be corrected if they are found to be inaccurate. You may also request the erasure of your personal data, inter alia, if the purpose of the processing ceases to exist or you have withdrawn your consent to the processing;
            restrict personal data processing – in certain situations (e.g. where you have alleged that your data is inaccurate) you may request that HabitatMap restricts the processing of your personal data, in which case HabitatMap will no longer process your data for any purpose other than the data storage;
            object to processing – in certain situations (e.g. where processing is based on a legitimate interest of the controller) you may object to the processing of your personal data;
            transmission of personal data – you may request to receive your personal data in a structured, commonly used, machine-readable format and to have that data sent to another controller. The above applies when data are processed upon your consent (Article 6(1)(a) GDPR) and/or upon contract (Article 6(1)(b) GDPR) and the data are processed by automated means;
            lodge a complaint to the President of the Office for Personal Data Protection – in the event of a breach by HabitatMap of the processing of your personal data, you may lodge a complaint with the relevant authority.
            You may contact HabitatMap with any request to exercise your rights by email or postal address shown at the beginning of this document or by other means of your choice. Details on how to file a complaint with the President of the Office of Personal Data Protection can be found at: https://uodo.gov.pl/pl/p/kontakt.
 
            Miscellaneous
 
            This Privacy Policy may be subject to updates and changes. In such case, HabitatMap will take steps to inform you of any such updates or changes by, for example, sending you a notification. Notwithstanding the foregoing, HabitatMap recommends that you review this page as often as possible.
 
 """,
                                                           comment: "")
    }
    
    enum EmptyDashboardMobile {
        static let title: String = NSLocalizedString("Start recording a mobile session",
                                                     comment: "")
        static let titleDivider = NSLocalizedString("a",
                                                    comment: "In addition to: Start recording a mobile session")
        static let description: String = NSLocalizedString("If you plan on moving around while recording measurements.",
                                                           comment: "")
        static let buttonMobile: String = NSLocalizedString("Record mobile session",
                                                            comment: "")
        static let buttonFixed: String = NSLocalizedString("Record new session",
                                                           comment: "")
        static let airBeamDescriptionText: String = NSLocalizedString("Did you know?",
                                                                      comment: "")
        static let airBeamDescriptionDescription: String = NSLocalizedString("AirBeam3 is weather resistant. To keep tabs on your outdoor air quality 24/7, hang one outside your home and record a fixed session.",
                                                                             comment: "")
        static let fetchingText: String = NSLocalizedString("Fetching...", comment: "")
    }
    
    enum EmptyDashboardFixed {
        static let title: String = NSLocalizedString("Ready to get started?",
                                                     comment: "")
        static let description: String = NSLocalizedString("Record a new session to monitor your health & environment.",
                                                           comment: "")
        static let exploreSessionsDescription: String = NSLocalizedString("Explore & follow existing AirCasting sessions or use your own device to record a new session and monitor your health & environment.",
                                                                          comment: "")
        static let newSession: String = NSLocalizedString("Record new session",
                                                          comment: "")
        static let fetchingText: String = NSLocalizedString("Fetching...",
                                                            comment: "")
        static let exploreSessionsButton = NSLocalizedString("Explore existing sessions", comment: "")
    }

    enum ReorderingDashboard {
        static let navigationTitle: String = NSLocalizedString("Reordering", comment: "Navigation title in reordering sessions view")
    }

    enum PowerABView {
        static let alertTitle: String = NSLocalizedString("Location alert",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("Please go to settings and allow location first.",
                                                            comment: "")
        static let alertSettings: String = NSLocalizedString("Settings",
                                                             comment: "")
        static let title: String = NSLocalizedString("Power on your AirBeam",
                                                     comment: "")
        static let messageText: String = NSLocalizedString("Wait for the conncection indicator to change from red to green before continuing.",
                                                           comment: "")
    }
    
    enum SelectDeviceView {
        static let alertTitle: String = NSLocalizedString("Location alert",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("Please go to settings and allow location first.",
                                                            comment: "")
        static let alertSettings: String = NSLocalizedString("Settings",
                                                             comment: "")
        static let title: String = NSLocalizedString("What device are you using to record this session?",
                                                     comment: "")
        static let bluetoothLabel: String = NSLocalizedString("Bluetooth device for example AirBeam",
                                                                comment: "")
        static let bluetoothDevice: String = NSLocalizedString("Bluetooth device",
                                                                comment: "")
        static let micLabel_1: String = NSLocalizedString("Phone microphone to measure sound level",
                                                          comment: "It consists of two parts. Please consider them together. Whole text is following: Phone microphone to measure sound level")
        static let phoneMicrophone: String = NSLocalizedString("Phone microphone",
                                                          comment: "")
        static let chooseButton: String = NSLocalizedString("Choose",
                                                            comment: "")
    }
    
    enum OfflineAlert {
        static let title = NSLocalizedString("Device is offline",
                                             comment: "")
        static let message = NSLocalizedString("Could not finish session synchronization",
                                               comment: "")
    }
    
    enum TurnOnBluetoothView {
        static let title: String = NSLocalizedString("Turn on Bluetooth",
                                                     comment: "")
        static let messageText: String = NSLocalizedString("Turn on Bluetooth to enable your phone to connect to the AirBeam",
                                                           comment: "")
    }
    
    enum TurnOnLocationView {
        static let title: String = NSLocalizedString("Turn on location services",
                                                     comment: "")
        static let messageText: String = NSLocalizedString("To map your measurements, turn on location services.",
                                                           comment: "")
        static let continueButton: String = NSLocalizedString("Turn on",
                                                              comment: "")
    }
    
    enum DeleteSession {
        static let title: String = NSLocalizedString("Delete this session", comment: "")
        static let description: String = NSLocalizedString("Which stream would you like to delete?", comment: "")
        static let continueButton: String = NSLocalizedString("Delete streams", comment: "")
        static let deleteAlert: String = NSLocalizedString("Are You sure?", comment: "")
        static let deleteButton: String = NSLocalizedString("Delete", comment: "")
    }
    
    enum EditSession {
        static let title: String = NSLocalizedString("Edit session details",
                                                     comment: "")
        static let sessionNamePlaceholder: String = NSLocalizedString("Session name",
                                                               comment: "")
        static let tagPlaceholder: String = NSLocalizedString("Tags",
                                                              comment: "")
        static let buttonAccept: String = NSLocalizedString("Accept",
                                                            comment: "")
        static let erorr: String = NSLocalizedString("Session name can't be blank",
                                                     comment: "")
        static let sessionTagsLabel: String = NSLocalizedString("Session tags",
                                                              comment: "")
        static let sessionNameLabel: String = NSLocalizedString("Session name",
                                                               comment: "")
    }
    
    enum SessionHeaderView {
        static let measurementsMicText: String = NSLocalizedString("Most recent measurement:",
                                                                   comment: "")
        static let stopButton: String = NSLocalizedString("Stop recording",
                                                          comment: "")
        static let editButton: String = NSLocalizedString("Edit session",
                                                          comment: "")
        static let shareButton: String = NSLocalizedString("Share session",
                                                           comment: "")
        static let deleteButton: String = NSLocalizedString("Delete session",
                                                            comment: "")
        static let stopRecordingButton: String = NSLocalizedString("Finish recording session",
                                                                   comment: "")
        static let enterStandaloneModeButton: String = NSLocalizedString("Enter standalone mode",
                                                                         comment: "")
        static let finishAlertTitleNoName: String = NSLocalizedString("Finish recording this session?",
                                                                comment: "")
        static let finishAlertTitleNamed: String = NSLocalizedString("Finish recording %@?",
                                                                comment: "")
        static let finishAlertTitleSYNCNoName: String = NSLocalizedString("Finish recording this session and sync from SD card?",
                                                                       comment: "")
        static let finishAlertTitleSYNCNamed: String = NSLocalizedString("Finish recording %@ and sync from SD card?",
                                                                       comment: "")
        
        static let finishAlertMessage: String = NSLocalizedString("The session will be moved to Mobile Dormant tab and you won't be able to add new measurement to it.",
                                                                  comment: "")
        static let finishAlertMessage_withSync: String = NSLocalizedString(" SD card will be cleared afterwards.",
                                                                           comment: "")
        static let finishAlertButton: String = NSLocalizedString("Finish recording",
                                                                 comment: "")
        static let shareFileAlertTitle: String = NSLocalizedString("Success!",
                                                                   comment: "")
        static let shareFileAlertMessage: String = NSLocalizedString("The session file was sent to provided email address",
                                                                     comment: "")
        static let airBeam3: String = NSLocalizedString("AirBeam3",
                                                        comment: "")
        static let airBeam2: String = NSLocalizedString("AirBeam2",
                                                        comment: "")
        static let airBeam1: String = NSLocalizedString("AirBeam1",
                                                        comment: "")
        static let mic: String = NSLocalizedString("Phone Mic",
                                                   comment: "")
        static let addNoteButton: String = NSLocalizedString("Add a note",
                                                             comment: "")
    }
    
    enum NetworkChecker {
        static let satisfiedPathText: String = NSLocalizedString("Current device has a network connection",
                                                                 comment: "")
        static let failurePathText: String = NSLocalizedString("Current device DOES NOT have a network connection",
                                                               comment: "")
    }
    
    enum ChooseSessionTypeView {
        static let title: String = NSLocalizedString("Let's begin",
                                                     comment: "")
        static let message: String = NSLocalizedString("How would you like to add your session?",
                                                       comment: "")
        static let recordNew: String = NSLocalizedString("Record a new session",
                                                         comment: "")
        static let moreInfo: String = NSLocalizedString("more info",
                                                        comment: "")
        
        static let fixedLabel: String = NSLocalizedString("Fixed session for measuring in one place",
                                                            comment: "")
        static let fixedSession: String = NSLocalizedString("Fixed session",
                                                            comment: "")
        
        static let mobileLabel: String = NSLocalizedString("Mobile session for moving around",
                                                             comment: "")
        static let mobileSession: String = NSLocalizedString("Mobile session",
                                                             comment: "")
        static let orLabel: String = NSLocalizedString("or",
                                                       comment: "")
        
        static let syncTitle: String = NSLocalizedString("Sync data from AirBeam3 if you recorded with AirBeam3",
                                                         comment: "")
        
        static let syncData: String = NSLocalizedString("Sync data from AirBeam3",
                                                               comment: "")
        static let followButtonTitle: String = NSLocalizedString("Follow session search & follow fixed sessions",
                                                                 comment: "")
        static let followSession: String = NSLocalizedString("Follow session",
                                                                       comment: "")
    }
    
    enum MoreInfoPopupView {
        static let text_1: String = NSLocalizedString("Session types",
                                                      comment: "")
        static let text_2: String = NSLocalizedString("If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second.",
                                                      comment: "")
        static let text_3: String = NSLocalizedString("If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location.",
                                                      comment: "")
        static let mobile: String = NSLocalizedString("mobile",
                                                      comment: "")
        static let fixed: String = NSLocalizedString("fixed",
                                                      comment: "")
    }
    
    enum ConnectingABView {
        static let title: String = NSLocalizedString("Connecting",
                                                     comment: "")
        static let message: String = NSLocalizedString("This should take less than 10 seconds.",
                                                       comment: "")
        static let connect: String = NSLocalizedString("Connect",
                                                       comment: "")
    }
    
    enum ABConnectedView {
        static let title: String = NSLocalizedString("AirBeam connected",
                                                     comment: "")
        static let message: String = NSLocalizedString("Your AirBeam is connected to your phone and ready to take some measurements.",
                                                       comment: "")
    }
    
    enum CreateSessionDetailsView {
        static let wifiAlertTitle: String = NSLocalizedString("Wi-Fi credentials are empty ",
                                                              comment: "")
        static let wifiAlertMessage: String = NSLocalizedString("Please, fill them up.",
                                                                comment: "")
        static let primaryWifiButton: String = NSLocalizedString("Show Wi-fi screen",
                                                                 comment: "")
        static let title: String = NSLocalizedString("New session details",
                                                     comment: "")
        static let placementPicker_1: String = NSLocalizedString("Where will you place your AirBeam?",
                                                                 comment: "")
        static let placementPicker_2: String = NSLocalizedString("Indoor",
                                                                 comment: "")
        static let placementPicker_3: String = NSLocalizedString("Outdoor",
                                                                 comment: "")
        static let transmissionPicker: String = NSLocalizedString("Data transmission:",
                                                                  comment: "")
        static let cellularText: String = NSLocalizedString("Cellular",
                                                            comment: "")
        static let wifiText: String = NSLocalizedString("Wi-Fi",
                                                        comment: "")
        static let sessionNamePlaceholder: String = NSLocalizedString("Session name",
                                                                      comment: "")
        static let sessionTagPlaceholder: String = NSLocalizedString("Tags",
                                                                     comment: "")
    }
    
    enum AirBeamConnector {
        static let connectionTimeoutTitle: String = NSLocalizedString("Connection error",
                                                                      comment: "")
        static let connectionTimeoutDescription: String = NSLocalizedString("Bluetooth connection failed. Please toggle the power on your device and try again.",
                                                                            comment: "")
    }
    
    enum ConfirmCreatingSessionView {
        static let alertTitle: String = NSLocalizedString("Failure",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("Failed to create session",
                                                            comment: "")
        static let contentViewTitle: String = NSLocalizedString("Are you ready?",
                                                                comment: "")
        
        static let contentViewText: String = NSLocalizedString("Your %@ session %@ is ready to start gathering data.",
                                                                 comment: "")
        
        static let contentViewTextEnd: String = NSLocalizedString("Hang your AirBeam in a secure position, then press the start recording button below.",
                                                                 comment: "")
        static let contentViewTextEndMobile: String = NSLocalizedString("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.",
                                                                       comment: "")
        static let startRecording: String = NSLocalizedString("Start recording",
                                                              comment: "")
    }
    
    enum ChooseCustomLocationView {
        static let sessionLocation: String = NSLocalizedString("Session location",
                                                               comment: "")
        static let titleLabel: String = NSLocalizedString("Search the address and adjust the marker to indicate an exact placement of Your AirBeam",
                                                          comment: "")
    }
    
    enum MainTabBarView {
        static let loggingOut: String = NSLocalizedString("Logging out, please wait...",
                                                          comment: "")
        static let deletingAccount: String = NSLocalizedString("Deleting account, please wait...",
                                                             comment: "")
        static let finished: String = NSLocalizedString("Finished", comment: "")
        static let homeIcon: String = "home"
        static let homeBlueIcon: String = "bluehome"
        static let plusIcon: String = "plus"
        static let plusBlueIcon: String = "blueplus"
        static let settingsIcon: String = "settings"
        static let settingsBlueIcon: String = "bluesettings"
    }
    
    enum DashboardView {
        static let dashboardText: String = NSLocalizedString("Dashboard",
                                                             comment: "")
        static let following: String = NSLocalizedString("Following", comment: "")
    }
    
    enum Chart {
        static let emptyChartMessage = NSLocalizedString("Waiting for the first average value", comment: "")
    }

    enum RefreshControl {
        static let progressViewTest: String = NSLocalizedString("Syncing...",
                                                                comment: "")
    }
    
    enum StandaloneSessionCardView {
        static let heading = NSLocalizedString("Your AirBeam3 is now in standalone mode",
                                               comment: "")
        static let description = NSLocalizedString("AirBeam3 is now recording using its SD card. The measurements will be displayed here after syncing.",
                                                   comment: "")
        static let finishAndSyncButtonLabel = NSLocalizedString("Finish recording & sync",
                                                                comment: "")
        static let finishAndDontSyncButtonLabel = NSLocalizedString("Finish recording & don't sync",
                                                                    comment: "")
    }
    
    enum SDSyncRootView {
        static let title: String = NSLocalizedString("Updating sessions",
                                                     comment: "")
        static let message: String = NSLocalizedString("Sessions must be updated prior to syncing SD card. Make sure your device is connected to the Internet.",
                                                       comment: "")
    }
    
    enum SDSyncSuccessView {
        static let title: String = NSLocalizedString("Success",
                                                     comment: "")
        static let message: String = NSLocalizedString("Sessions were updated successfully",
                                                       comment: "")
    }
    
    enum UnplugAirbeamView {
        static let title: String = NSLocalizedString("Unplug your AirBeam",
                                                     comment: "")
        static let message: String = NSLocalizedString("Keep it unplugged for the duration of the sync.",
                                                       comment: "")
    }
    
    enum SDRestartABView {
        static let title: String = NSLocalizedString("Restart your AirBeam",
                                                     comment: "")
        static let message: String = NSLocalizedString("Turn your AirBeam off and then back on.",
                                                       comment: "")
    }
    
    enum SyncingABView {
        static let message: String = NSLocalizedString("Keep your AirBeam unplugged and close to your iPhone",
                                                       comment: "")
        static let alertTitle: String = NSLocalizedString("SD card sync failed",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("We're sorry, something unexpected caused the SD card sync to fail. Please try again", comment: "")
        static let startingSyncTitle: String = NSLocalizedString("Syncing...",
                                                                 comment: "")
        static let finishingSyncTitle: String = NSLocalizedString("Finalizing...",
                                                                  comment: "")
    }
    
    enum SDSyncCompleteView {
        static let title: String = NSLocalizedString("Sync complete",
                                                     comment: "")
        static let message: String = NSLocalizedString("The data from your AirBeam3 was synchronized successfully to the app. The SD card was cleared.",
                                                       comment: "")
        static let SDClearTitle: String = NSLocalizedString("SD card cleared",
                                                            comment: "")
        static let SDClearMessage: String = NSLocalizedString("SD inside your AirBeam was cleared sucesfully",
                                                              comment: "")
    }
    
    enum ClearingSDCardView {
        static let title: String = NSLocalizedString("Clearing SD card",
                                                     comment: "")
        static let message: String = NSLocalizedString("This should take less then 10 seconds.",
                                                       comment: "")
        static let failedClearingAlertTitle: String = NSLocalizedString("Failed to clear SD card",
                                                                        comment: "")
        static let failedClearingAlertMessage: String = NSLocalizedString("Try again later",
                                                                          comment: "")
    }
    
    enum DefaultDeleteSessionViewModel {
        static let all: String = NSLocalizedString("All",
                                                   comment: "")
    }
    
    enum DeviceHandler {
        static let alertTitle = NSLocalizedString("Unsupprted device",
                                                  comment: "")
        static let alertMessage = NSLocalizedString("To use the AirBeam3 in standalone mode and sync the SD card, an iPhone8 or higher is required",
                                                    comment: "")
    }
    
    enum NetworkAlert {
        static let alertTitle: String = NSLocalizedString("No internet connection",
                                                          comment: "")
        static let alertMessage: String = NSLocalizedString("You need to have internet connection to continue.",
                                                            comment: "")
    }
    
    enum MicrophoneAlert {
        static let title: String = NSLocalizedString("Allow AirCasting to record audio",
                                                     comment: "")
        static let message: String = NSLocalizedString("To record sound level measurements, the app needs access to your microhpone.",
                                                       comment: "")
    }
    
    enum MicrophoneSessionAlreadyRecordingAlert {
        static let title: String = NSLocalizedString("There is already a microphone session in progress",
                                                     comment: "")
        static let message: String = NSLocalizedString("You can record only one microphone session at once.",
                                                       comment: "")
    }
    
    enum InAppAlerts {
        static let noInternetConnectionTitle: String = NSLocalizedString("No internet connection",
                                                                   comment: "")
        static let noInternetConnectionMessage: String = NSLocalizedString("To sign out, you must be connected to the Internet.",
                                                                     comment: "")
        static let noInternetConnectionButton: String = NSLocalizedString("Got it!",
                                                                    comment: "")
        static let failedTitle: String = NSLocalizedString("Failed",
                                                                    comment: "")
        static let downloadingFailedMessage: String = NSLocalizedString("Cannot download sessions at this moment. Please try again in a moment.",
                                                                        comment: "")
        static let failedDownloadTitle: String = NSLocalizedString("Connection failure",
                                                                   comment: "")
        static let failedDownloadMessage: String = NSLocalizedString("Something went wrong when downloading most recent session data. Please try again later.",
                                                                     comment: "")
        static let failedDownloadButton: String = NSLocalizedString("Got it!",
                                                                    comment: "")
        static let failedSavingTitle: String = NSLocalizedString("Request failed",
                                                                   comment: "")
        static let failedSavingMessage: String = NSLocalizedString("New data couldn't be saved. Please try again later.",
                                                                     comment: "")
        static let failedSavingButton: String = NSLocalizedString("Got it!",
                                                                    comment: "")
        static let firstDeletingAccountTitle: String = NSLocalizedString("Delete account?",
                                                                    comment: "")
        static let firstDeletingAccountMessage: String = NSLocalizedString("Would you like to delete your account?",
                                                                      comment: "")
        static let firstConfirmingDeletingButton: String = NSLocalizedString("Confirm",
                                                                          comment: "")
        static let secondDeletingAccountTitle: String = NSLocalizedString("Delete confirmation",
                                                                          comment: "")
        static let secondDeletingAccountMessage: String = NSLocalizedString("You will lose all your sessions and data. Are you sure to delete the account?",
                                                                            comment: "")
        static let secondConfirmingDeletingButton: String = NSLocalizedString("Delete",
                                                                              comment: "")
        static let failedDeletingAccountErrorMessage: String = NSLocalizedString("Something went wrong deleting the account. Please try again later.",
                                                                     comment: "")
        static let unableToConnectTitle: String = NSLocalizedString("No Internet connection",
                                                                  comment: "")
        static let unableToConnectMessage: String = NSLocalizedString("To sign out, you must be connected to the Internet",
                                                                    comment: "")
        static let accountDeletionSuccessTitle: String = NSLocalizedString("Success",
                                                                   comment: "")
        static let accountDeletionSuccessMessage: String = NSLocalizedString("Your account has been deleted.",
                                                                   comment: "")
        static let thresholdsValuesSettingsTitle: String = NSLocalizedString("Wrong values", comment: "")
        static let thresholdsValuesSettingsMessage: String = NSLocalizedString("The lowest threshold value has to be smaller than the highest threshold value", comment: "")
        static let logoutWarningTitle: String = NSLocalizedString("Are you sure?",
                                                                   comment: "")
        static let logoutWarningMessage: String = NSLocalizedString("You will lose sessions recorded with disabled location.",
                                                                   comment: "")
        static let logoutWarningConfirmButton: String = NSLocalizedString("Confirm",
                                                                          comment: "")
        static let fetchingDataFailedMessage: String = NSLocalizedString("Something went wrong. Please try again later.", comment: "")
    }
    
    enum AddNoteView {
        static let title: String = NSLocalizedString("Add a note",
                                                     comment: "")
        static let description: String = NSLocalizedString("Your note will be timestamped and displayed on the AirCasting map",
                                                           comment: "")
        static let photoButton = NSLocalizedString("Tap to add picture", comment: "")
        static let retakePhotoButton = NSLocalizedString("Retake a picture", comment: "")
        static let placeholder: String = NSLocalizedString("Note",
                                                           comment: "")
        static let continueButton: String = NSLocalizedString("Add a note",
                                                              comment: "")
        static let cancelButton: String = NSLocalizedString("Cancel",
                                                            comment: "")
    }

    enum SearchView {
        static let title: String = NSLocalizedString("Search fixed sessions", comment: "")
        static let placeholder: String = NSLocalizedString("Session location", comment: "")
        static let parametersQuestion: String = NSLocalizedString("Which parameter are you intrested in?", comment: "")
        static let sensorQuestion: String = NSLocalizedString("Which sensor are you intrested in?", comment: "")
        static let ozoneText: String = NSLocalizedString("Ozone", comment: "")
        static let particularMatterText: String = NSLocalizedString("Particular matter", comment: "")
    }
    
    enum SearchFollowSensorNames {
        static let AirBeam3and2: String = NSLocalizedString("AirBeam", comment: "")
        static let openAQ: String = NSLocalizedString("OpenAQ", comment: "")
        static let purpleAir: String = NSLocalizedString("PurpleAir", comment: "")
        static let openAQOzone: String = NSLocalizedString("OpenAQ", comment: "")
    }
    
    enum SearchFollowParamNames {
        static let particulateMatter: String = NSLocalizedString("Particulate Matter", comment: "")
        static let ozone: String = NSLocalizedString("Ozone", comment: "")
    }
    
    enum CompleteSearchView {
        static let map: String = NSLocalizedString("map", comment: "")
        static let chart: String = NSLocalizedString("chart", comment: "")
        static let lastMeasurement = NSLocalizedString("Last measurement", comment: "")
        static let followButtonTitle: String = NSLocalizedString("Follow Session", comment: "")
        static let unfollowButtonTitle: String = NSLocalizedString("Unfollow Session", comment: "")
        static let ownSessionButtonTitle: String = NSLocalizedString("Your session", comment: "")
        static let followingSessionButtonTitle: String = NSLocalizedString("Following...", comment: "")
        static let noStreamsDescription = NSLocalizedString("No streams available for this session", comment: "")
        static let failedDownloadAlertTitle = NSLocalizedString("Session download failed", comment: "")
        static let failedDownloadAlertMessage = NSLocalizedString("Please try again later.", comment: "")
    }
    
    enum EditNoteView {
        static let title: String = NSLocalizedString("Edit this note",
                                                     comment: "")
        static let description: String = NSLocalizedString("You can edit your note here",
                                                           comment: "")
        static let placeholder: String = NSLocalizedString("Note",
                                                           comment: "")
        static let saveButton: String = NSLocalizedString("Save changes",
                                                          comment: "")
        static let deleteButton: String = NSLocalizedString("Delete note",
                                                            comment: "")
        static let cancelButton: String = NSLocalizedString("Cancel",
                                                            comment: "")
    }
    
    enum SessionStruct {
        static let mobile: String = NSLocalizedString("Mobile",
                                                      comment: "Mobile session readable localized description")
        static let fixed: String = NSLocalizedString("Fixed",
                                                     comment: "Fixed session readable localized description")
        static let other: String = NSLocalizedString("Other",
                                                     comment: "Unknown session readable localized description")
    }
    
    enum AuthorizationAPI {
        static let otherError: String = NSLocalizedString("Unknown error occurred. Try again.",
                                                          comment: "Unknown login message failure")
        static let timeoutError: String = NSLocalizedString("It looks like the server is taking to long to respond. Try again later.",
                                                            comment: "time out login message failure")
        static let noConnectionError: String = NSLocalizedString("Please, make sure your device is connected to the internet.",
                                                                 comment: "connection failure login message failure")
        static let alreadyTakenError: String = NSLocalizedString("Email or profile name is already in use. Please try again.",
                                                                 comment: "connection failure login message failure")
    }
    
    enum CreateAccountView {
        static let createTitle_1: String = NSLocalizedString("Create account",
                                                             comment: "It consists of few parts. Please consider them together. Whole text is following: Create account to record and map your environment")
        static let createTitle_2: String = NSLocalizedString("to record and map your environment",
                                                             comment: "")
        static let email: String = NSLocalizedString("Email",
                                                     comment: "")
        static let profile: String = NSLocalizedString("Profile name",
                                                       comment: "")
        static let password: String = NSLocalizedString("Password",
                                                        comment: "")
        static let signIn_1: String = NSLocalizedString("Already have an account?",
                                                        comment: "")
        static let signIn_2: String = NSLocalizedString("Sign in",
                                                        comment: "")
        static let takenAndOtherTitle: String = NSLocalizedString("Cannot create account",
                                                                  comment:  "")
        static let noInternetTitle: String = NSLocalizedString("No Internet Connection"
                                                               , comment:  "")
        static let loggingOutInBackground: String = NSLocalizedString("Currently logging out in the background. You can fill out credentials.", comment:  "")
        
    }
    
    enum AuthErrors {
        static let passwordTooShort: String = NSLocalizedString("Password is too short (minimum is 8 characters)",
                                                                comment: "")
        static let incorrectEmail: String = NSLocalizedString("The email address is incorrect.",
                                                              comment: "")
        static let emptyTextfield: String = NSLocalizedString("This field cannot be left blank.",
                                                              comment: "")
    }
    
    enum SearchMapView {
        static let loadingText: String = NSLocalizedString("Loading sessions",
                                                              comment: "")
        static let parameterText: String = NSLocalizedString("Results for: %@",
                                                              comment: "")
        static let sensorText: String = NSLocalizedString("using: %@",
                                                              comment: "")
        static let redoText: String = NSLocalizedString("Redo Search in Map",
                                                              comment: "")
        static let cardsTitle: String = NSLocalizedString("Sessions showing %@ of %@ results",
                                                              comment: "")
        static let sessionsText: String = NSLocalizedString("Sessions",
                                                              comment: "")
        static let finishText: String = NSLocalizedString("Finish",
                                                              comment: "")
        static let noResults: String = NSLocalizedString("No results found within selected area.",
                                                              comment: "")
    }
    
    enum ProtectedScreen {
        static let title: String = NSLocalizedString("Please, do not force close the app while recording a session!", comment: "")
    }
    
    enum TextView {
        static let doneButton: String = NSLocalizedString("Done", comment: "")
    }
}
