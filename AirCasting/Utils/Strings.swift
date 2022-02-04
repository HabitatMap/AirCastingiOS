// Created by Lunar on 23/06/2021.
//

import SwiftUI

struct Strings {
    enum Commons {
        static let cancel: String = LocalizedStringKey("Cancel").stringKey
        static let ok: String = LocalizedStringKey("OK").stringKey
        static let myAccount: String = LocalizedStringKey("My account").stringKey
        static let `continue`: String = LocalizedStringKey("Continue").stringKey
        static let gotIt: String = LocalizedStringKey("Got it!").stringKey
        static let note: String = LocalizedStringKey("Note").stringKey
    }

    enum Settings {
        static let title: String = LocalizedStringKey("Settings").stringKey
        static let myAccount: String = LocalizedStringKey("My Account").stringKey
        static let crowdMap: String = LocalizedStringKey("Contribute to CrowdMap").stringKey
        static let crowdMapDescription: String = LocalizedStringKey("Data contributed to the CrowdMap is publicly available at aircasting.org").stringKey
        static let disableMapping: String = LocalizedStringKey("Disable Mapping").stringKey
        static let disableMappingDescription: String = LocalizedStringKey("Turns off GPS tracking & session syncing. Use \"Share file\" to retrieve your measurements via email.").stringKey
        static let temperature = LocalizedStringKey("Temperature Units").stringKey
        static let celsiusDescription = LocalizedStringKey("Use Celsius").stringKey
        static let backendSettings: String = LocalizedStringKey("Backend settings").stringKey
        static let settingsHelp: String = LocalizedStringKey("Help").stringKey
        static let hardwareDevelopers: String = LocalizedStringKey("Hardware developers").stringKey
        static let about: String = LocalizedStringKey("About AirCasting").stringKey
        static let keepScreenTitle = LocalizedStringKey("Keep screen on").stringKey
        static let clearSDTitle = LocalizedStringKey("Clear SD card").stringKey
        static let appInfoTitle = LocalizedStringKey("AirCasting App v").stringKey
        static let buildText = LocalizedStringKey("build").stringKey
        static let betaBuild = LocalizedStringKey("Beta build").stringKey
        static let debugBuild = LocalizedStringKey("Debug build").stringKey
    }

    enum BackendSettings {
        static let backendSettings: String = LocalizedStringKey("Backend settings").stringKey
        static let alertTitle: String = LocalizedStringKey("Logout Alert").stringKey
        static let alertMessage: String = LocalizedStringKey("Something went wrong, when logging out.").stringKey
        static let currentURL: String = LocalizedStringKey("current url").stringKey
        static let currentPort: String = LocalizedStringKey("current port").stringKey
    }

    enum MyAccountSettings {
        static let notLogged: String = LocalizedStringKey("You aren’t currently logged in").stringKey
        static let createAccount: String = LocalizedStringKey("Create an account").stringKey
        static let logIn: String = LocalizedStringKey("Log In").stringKey
    }

    enum SignOutSettings {
        static let logged: String = LocalizedStringKey("You are currently logged in as ").stringKey
        static let signOut: String = LocalizedStringKey("Sign Out").stringKey
    }

    enum ForgotPassword {
        static let title = LocalizedStringKey("Forgot Password").stringKey
        static let emailInputTitle = LocalizedStringKey("email or username").stringKey
        static let newPasswordSuccessMessage = LocalizedStringKey("Email was sent. Please check your inbox for the details.").stringKey
        static let newPasswordSuccessTitle = LocalizedStringKey("Email response").stringKey
        static let newPasswordFailureMessage = LocalizedStringKey("Something went wrong, please try again").stringKey
        static let newPasswordFailureTitle = LocalizedStringKey("Email response").stringKey
    }

    enum SignInView {
        static let title_2 = LocalizedStringKey("to record and map your environment").stringKey
        static let usernameField = LocalizedStringKey("Profile name").stringKey
        static let passwordField = LocalizedStringKey("Password").stringKey
        static let forgotPasswordButton = LocalizedStringKey("Forgot password?").stringKey
        static let signIn = LocalizedStringKey("Sign in").stringKey
        static let signUpButton_1 = LocalizedStringKey("First time here? ").stringKey
        static let signUpButton_2 = LocalizedStringKey("Create an account").stringKey
        static let alertTitle = LocalizedStringKey("Login Error").stringKey
        static let alertComment = LocalizedStringKey("Login Error alert title").stringKey
        static let InvalidCredentialText = LocalizedStringKey("The profile name or password is incorrect. Please try again. ").stringKey
        static let noConnectionTitle = LocalizedStringKey("No Internet Connection").stringKey
        static let noConnectionText = LocalizedStringKey("Please make sure your device is connected to the internet.").stringKey
    }

    enum SessionShare {
        static let title: String = LocalizedStringKey("Share session").stringKey
        static let description: String = LocalizedStringKey("Select a stream to share").stringKey
        static let locationlessDescription: String = LocalizedStringKey("Generate a CSV file with your session data").stringKey
        static let emailDescription: String = LocalizedStringKey("Or email a CSV file with your session data").stringKey
        static let emailPlaceholder: String = LocalizedStringKey("Email").stringKey
        static let linkSharingAlertTitle: String = LocalizedStringKey("Sharing failed").stringKey
        static let linkSharingAlertMessage: String = LocalizedStringKey("Try again later").stringKey
        static let emailSharingAlertTitle: String = LocalizedStringKey("Request failed").stringKey
        static let emailSharingAlertMessage: String = LocalizedStringKey("Please try again later").stringKey
        static let shareLinkButton: String = LocalizedStringKey("Share link").stringKey
        static let shareFileButton: String = LocalizedStringKey("Share file").stringKey
        static let loadingFile: String = LocalizedStringKey("Generating file").stringKey
        static let invalidEmailLabel: String = LocalizedStringKey("This email is invalid").stringKey
    }

    enum LoadingSession {
        static let title: String = LocalizedStringKey("Your AirBeam is gathering data.").stringKey
        static let description: String = LocalizedStringKey("Measurements will appear in 3 minutes.").stringKey
    }

    struct SessionCartView {
        static let map: String = LocalizedStringKey("map").stringKey
        static let graph: String = LocalizedStringKey("graph").stringKey
        static let follow: String = LocalizedStringKey("follow").stringKey
        static let unfollow: String = LocalizedStringKey("unfollow").stringKey
        static let avgSessionH: String = LocalizedStringKey("1 hr avg -").stringKey
        static let avgSessionMin: String = LocalizedStringKey("1 min avg -").stringKey
    }

    struct SingleMeasurementView {
        static let microphoneUnit: String = LocalizedStringKey("dB").stringKey
        static let celsiusUnit: String = LocalizedStringKey("C").stringKey
        static let fahrenheitUnit: String = LocalizedStringKey("F").stringKey
    }

    enum SelectPeripheralView {
        static let airBeamsText: String = LocalizedStringKey("AirBeams").stringKey
        static let otherText: String = LocalizedStringKey("Other devices").stringKey
        static let alertTitle: String = LocalizedStringKey("Connection error").stringKey
        static let alertMessage: String = LocalizedStringKey("Bluetooth connection failed. Please toggle the power on your device and try again.").stringKey
        static let titleLabel: String = LocalizedStringKey("Choose the device you'd like to record with").stringKey
        static let titleSyncLabel: String = LocalizedStringKey("Select the device you'd like to sync").stringKey
        static let titleSDClearLabel: String = LocalizedStringKey("Select the device you'd like to clear").stringKey
        static let refreshButton: String = LocalizedStringKey("Don't see a device? Refresh scanning.").stringKey
        static let connectText: String = LocalizedStringKey("Connect").stringKey
    }

    enum SessionCart {
        static let measurementsTitle: String = LocalizedStringKey("Last second measurement:").stringKey
        static let dormantMeasurementsTitle: String = LocalizedStringKey("Avg value:").stringKey
        static let heatmapSettingsTitle: String = LocalizedStringKey("Heatmap settings").stringKey
        static let heatmapSettingsdescription: String = LocalizedStringKey("Values beyond Min and Max will not be displayed.").stringKey
        static let saveChangesButton: String = LocalizedStringKey("Save changes").stringKey
        static let resetChangesButton: String = LocalizedStringKey("Reset to default").stringKey
        static let parametersText: String = LocalizedStringKey("Parameters:").stringKey
        static let lastMinuteMeasurement: String = LocalizedStringKey("Last minute measurement").stringKey
    }

    enum Thresholds {
        static let veryHigh: String = LocalizedStringKey("Max").stringKey
        static let high: String = LocalizedStringKey("High").stringKey
        static let medium: String = LocalizedStringKey("Medium").stringKey
        static let low: String = LocalizedStringKey("Low").stringKey
        static let veryLow: String = LocalizedStringKey("Min").stringKey
    }

    enum WifiPopupView {
        static let wifiPlaceholder: String = LocalizedStringKey("Wi-Fi name").stringKey
        static let passwordPlaceholder: String = LocalizedStringKey("Password").stringKey
        static let connectButton: String = LocalizedStringKey("Connect").stringKey
        static let passwordTitle: String = LocalizedStringKey("WiFi network name & password:").stringKey
        static let nameAndPasswordTitle_1: String = LocalizedStringKey("Password for ").stringKey
        static let nameAndPasswordTitle_2: String = LocalizedStringKey(" network:").stringKey
        static let differentNetwork: String = LocalizedStringKey("Connect to a different WiFi network.").stringKey
    }

    enum OnboardingGetStarted {
        static let description: String = LocalizedStringKey("record and map measurements from health and environmental monitoring devices").stringKey
        static let getStarted: String = LocalizedStringKey("Get started").stringKey
    }

    enum OnboardingNearAir {
        static let title: String = LocalizedStringKey("How’s the air \nnear you?").stringKey
        static let description: String = LocalizedStringKey("Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now.").stringKey
        static let continueButton: String = LocalizedStringKey("How’s the air \nnear you?").stringKey
    }

    enum OnboardingAirBeam {
        static let title: String = LocalizedStringKey("Measure and map \nyour exposure \nto air pollution").stringKey
        static let description: String = LocalizedStringKey("Connect AirBeam to measure air quality humidity, and temperature.").stringKey
        static let sheetButton: String = LocalizedStringKey("Learn More").stringKey
    }

    enum OnboardingAirBeamSheet {
        static let sheetTitle: String = LocalizedStringKey("How AirBeam \nworks?").stringKey
        static let sheetDescription_1: String = LocalizedStringKey("In ").stringKey
        static let sheetDescription_2: String = LocalizedStringKey("mobile ").stringKey
        static let sheetDescription_3: String = LocalizedStringKey("mode, the AirBeam \ncaptures personal exposures.\n\nIn ").stringKey
        static let sheetDescription_4: String = LocalizedStringKey("fixed ").stringKey
        static let sheetDescription_5: String = LocalizedStringKey("mode, it can be \ninstalled indoors or outdoors to \nkeep tabs on pollution levels in \nyour home, office, backyard, or \nneighborhood 24/7.").stringKey
    }

    enum OnboardingPrivacy {
        static let title: String = LocalizedStringKey("Your privacy").stringKey
        static let description: String = LocalizedStringKey("Review our commitment to preserving your privacy and accept our privacy policy.").stringKey
        static let continueButton: String = LocalizedStringKey("Accept").stringKey
        static let sheetButton: String = LocalizedStringKey("Learn More").stringKey
    }

    enum OnboardingPrivacySheet {
        static let title: String = LocalizedStringKey("Our privacy policy").stringKey
        static let description: String = LocalizedStringKey("""
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

 """).stringKey
    }

    enum EmptyDashboardMobile {
        static let title: String = LocalizedStringKey("Start recording a \nmobile session").stringKey
        static let description: String = LocalizedStringKey("If you plan on moving around \nwhile recording measurements.").stringKey
        static let buttonMobile: String = LocalizedStringKey("Record mobile session").stringKey
        static let buttonFixed: String = LocalizedStringKey("Record new session").stringKey
        static let airBeamDescriptionText: String = LocalizedStringKey("Did you know?").stringKey
        static let airBeamDescriptionDescription: String = LocalizedStringKey("AirBeam3 is weather resistant. To keep tabs on your outdoor air quality 24/7, hang one outside your home and record a fixed session.").stringKey
        static let fetchingText: String = LocalizedStringKey("Fetching...").stringKey
    }

    enum EmptyDashboardFixed {
        static let title: String = LocalizedStringKey("Ready to get started?").stringKey
        static let description: String = LocalizedStringKey("Record a new session to monitor\n your health & environment.").stringKey
        static let newSession: String = LocalizedStringKey("Record new session").stringKey
        static let fetchingText: String = LocalizedStringKey("Fetching...").stringKey
    }

    enum ReorderingDashboard {
        static let navigationTitle: String = NSLocalizedString("Reordering", comment: "Navigation title in reordering sessions view")
    }

    enum PowerABView {
        static let alertTitle: String = LocalizedStringKey("Location alert").stringKey
        static let alertMessage: String = LocalizedStringKey("Please go to settings and allow location first.").stringKey
        static let alertSettings: String = LocalizedStringKey("Settings").stringKey
        static let title: String = LocalizedStringKey("Power on your AirBeam").stringKey
        static let messageText: String = LocalizedStringKey("Wait for the conncection indicator to change from red to green before continuing.").stringKey
    }

    enum SelectDeviceView {
        static let alertTitle: String = LocalizedStringKey("Location alert").stringKey
        static let alertMessage: String = LocalizedStringKey("Please go to settings and allow location first.").stringKey
        static let alertSettings: String = LocalizedStringKey("Settings").stringKey
        static let title: String = LocalizedStringKey("What device are you using to record this session?").stringKey
        static let bluetoothLabel_1: String = LocalizedStringKey("Bluetooth device").stringKey
        static let bluetoothLabel_2: String = LocalizedStringKey("for example AirBeam").stringKey
        static let micLabel_1: String = LocalizedStringKey("Phone microphone").stringKey
        static let micLabel_2: String = LocalizedStringKey("to measure sound level").stringKey
        static let chooseButton: String = LocalizedStringKey("Choose").stringKey
    }

    enum OfflineAlert {
        static let title = LocalizedStringKey("Device is offline").stringKey
        static let message = LocalizedStringKey("Could not finish session synchronization").stringKey
    }

    enum TurnOnBluetoothView {
        static let title: String = LocalizedStringKey("Turn on Bluetooth").stringKey
        static let messageText: String = LocalizedStringKey("Turn on Bluetooth to enable your phone to connect to the AirBeam").stringKey
    }

    enum TurnOnLocationView {
        static let title: String = LocalizedStringKey("Turn on location services").stringKey
        static let messageText: String = LocalizedStringKey("To map your measurements, turn on location services.").stringKey
        static let continueButton: String = LocalizedStringKey("Turn on").stringKey
    }

    enum DeleteSession {
        static let title: String = LocalizedStringKey("Delete this session").stringKey
        static let description: String = LocalizedStringKey("Which stream would you like to delete?").stringKey
        static let continueButton: String = LocalizedStringKey("Delete streams").stringKey
        static let deleteAlert: String = LocalizedStringKey("Are You sure?").stringKey
        static let deleteButton: String = LocalizedStringKey("Delete").stringKey
    }

    enum EditSession {
        static let title: String = LocalizedStringKey("Edit session details").stringKey
        static let namePlaceholder: String = LocalizedStringKey("Session name").stringKey
        static let tagPlaceholder: String = LocalizedStringKey("Session tags").stringKey
        static let buttonAccept: String = LocalizedStringKey("Accept").stringKey
        static let erorr: String = LocalizedStringKey("Session name can't be blank").stringKey
    }

    enum SessionHeaderView {
        static let measurementsMicText: String = LocalizedStringKey("Most recent measurement:").stringKey
        static let stopButton: String = LocalizedStringKey("Stop recording").stringKey
        static let editButton: String = LocalizedStringKey("Edit session").stringKey
        static let shareButton: String = LocalizedStringKey("Share session").stringKey
        static let deleteButton: String = LocalizedStringKey("Delete session").stringKey
        static let stopRecordingButton: String = LocalizedStringKey("Finish recording session").stringKey
        static let enterStandaloneModeButton: String = LocalizedStringKey("Enter standalone mode").stringKey
        static let finishAlertTitle: String = LocalizedStringKey("Finish recording ").stringKey
        static let finishAlertTitle_2: String = LocalizedStringKey("this session").stringKey
        static let finishAlertTitle_3: String = LocalizedStringKey("?").stringKey
        static let finishAlertTitle_3_SYNC: String = LocalizedStringKey("and sync from SD card?").stringKey
        static let finishAlertMessage_1: String = LocalizedStringKey("The session will be moved to ").stringKey
        static let finishAlertMessage_2: String = LocalizedStringKey("Mobile Dormant").stringKey
        static let finishAlertMessage_3: String = LocalizedStringKey(" tab and you won't be able to add new measurement to it.").stringKey
        static let finishAlertMessage_4: String = LocalizedStringKey("\nSD card will be cleared afterwards").stringKey
        static let finishAlertButton: String = LocalizedStringKey("Finish recording").stringKey
        static let shareFileAlertTitle: String = LocalizedStringKey("Success!").stringKey
        static let shareFileAlertMessage: String = LocalizedStringKey("The session file was sent to provided email address").stringKey
        static let airBeam3: String = LocalizedStringKey("AirBeam3").stringKey
        static let airBeam2: String = LocalizedStringKey("AirBeam2").stringKey
        static let airBeam1: String = LocalizedStringKey("AirBeam1").stringKey
        static let mic: String = LocalizedStringKey("Phone Mic").stringKey
        static let addNoteButton: String = LocalizedStringKey("Add a note").stringKey
    }

    enum NetworkChecker {
        static let satisfiedPathText: String = LocalizedStringKey("Current device has a network connection").stringKey
        static let failurePathText: String = LocalizedStringKey("Current device DOES NOT have a network connection").stringKey
    }

    enum ChooseSessionTypeView {
        static let title: String = LocalizedStringKey("Let's begin").stringKey
        static let message: String = LocalizedStringKey("How would you like to add your session?").stringKey
        static let recordNew: String = LocalizedStringKey("Record a new session").stringKey
        static let moreInfo: String = LocalizedStringKey("more info").stringKey
        static let fixedLabel_1: String = LocalizedStringKey("Fixed session").stringKey
        static let fixedLabel_2: String = LocalizedStringKey("for measuring in one place").stringKey
        static let mobileLabel_1: String = LocalizedStringKey("Mobile session").stringKey
        static let mobileLabel_2: String = LocalizedStringKey("for moving\naround").stringKey
        static let orLabel: String = LocalizedStringKey("or").stringKey
        static let syncTitle: String = LocalizedStringKey("Sync data from \nAirBeam3").stringKey
        static let syncDescription: String = LocalizedStringKey("if you recorded with AirBeam3").stringKey

    }

    enum MoreInfoPopupView {
        static let text_1: String = LocalizedStringKey("Session types").stringKey
        static let text_2: String = LocalizedStringKey("If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second.").stringKey
        static let text_3: String = LocalizedStringKey("If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location.").stringKey
    }

    enum ConnectingABView {
        static let title: String = LocalizedStringKey("Connecting").stringKey
        static let message: String = LocalizedStringKey("This should take less than 10 seconds.").stringKey
        static let connect: String = LocalizedStringKey("Connect").stringKey
    }

    enum ABConnectedView {
        static let title: String = LocalizedStringKey("AirBeam connected").stringKey
        static let message: String = LocalizedStringKey("Your AirBeam is connected to your phone and ready to take some measurements.").stringKey
    }

    enum CreateSessionDetailsView {
        static let wifiAlertTitle: String = LocalizedStringKey("Wi-Fi credentials are empty ").stringKey
        static let wifiAlertMessage: String = LocalizedStringKey("Please, fill them up.").stringKey
        static let primaryWifiButton: String = LocalizedStringKey("Show Wi-fi screen").stringKey
        static let title: String = LocalizedStringKey("New session details").stringKey
        static let placementPicker_1: String = LocalizedStringKey("Where will you place your AirBeam?").stringKey
        static let placementPicker_2: String = LocalizedStringKey("Indoor").stringKey
        static let placementPicker_3: String = LocalizedStringKey("Outdoor").stringKey
        static let transmissionPicker: String = LocalizedStringKey("Data transmission:").stringKey
        static let cellularText: String = LocalizedStringKey("Cellular").stringKey
        static let wifiText: String = LocalizedStringKey("Wi-Fi").stringKey
        static let sessionNamePlaceholder: String = LocalizedStringKey("Session name").stringKey
        static let sessionTagPlaceholder: String = LocalizedStringKey("Tags").stringKey
    }

    enum AirBeamConnector {
        static let connectionTimeoutTitle: String = LocalizedStringKey("Connection error").stringKey
        static let connectionTimeoutDescription: String = LocalizedStringKey("Bluetooth connection failed. Please toggle the power on your device and try again.").stringKey
    }

    enum ConfirmCreatingSessionView {
        static let alertTitle: String = LocalizedStringKey("Failure").stringKey
        static let alertMessage: String = LocalizedStringKey("Failed to create session").stringKey
        static let contentViewTitle: String = LocalizedStringKey("Are you ready?").stringKey
        static let contentViewText_1: String = LocalizedStringKey("Your ").stringKey
        static let contentViewText_2: String = LocalizedStringKey(" session ").stringKey
        static let contentViewText_3: String = LocalizedStringKey(" is ready to start gathering data.\n\n").stringKey
        static let contentViewText_4: String = LocalizedStringKey("Hang your AirBeam in a secure position, then press the start recording button below.").stringKey
        static let contentViewText_4Mobile: String = LocalizedStringKey("Move to your starting location, confirm your location is accurate on the map, then press the start recording button below.").stringKey
        static let startRecording: String = LocalizedStringKey("Start recording").stringKey
    }

    enum ChooseCustomLocationView {
        static let sessionLocation: String = LocalizedStringKey("Session location").stringKey
        static let titleLabel: String = LocalizedStringKey("Search the address and adjust the marker to indicate an exact placement of Your AirBeam").stringKey
    }

    enum MainTabBarView {
        static let homeIcon: String = "home"
        static let homeBlueIcon: String = "bluehome"
        static let plusIcon: String = "plus"
        static let plusBlueIcon: String = "blueplus"
        static let settingsIcon: String = "settings"
        static let settingsBlueIcon: String = "bluesettings"
        static let loggingOut: String = "Logging out, please wait..."
        static let finished: String = NSLocalizedString("Finished", comment: "")
    }

    enum DashboardView {
        static let dashboardText: String = LocalizedStringKey("Dashboard").stringKey
        static let following: String = NSLocalizedString("Following", comment: "")
        static let homeIcon: String = LocalizedStringKey("home").stringKey
        static let homeBlueIcon: String = LocalizedStringKey("bluehome").stringKey
        static let plusIcon: String = LocalizedStringKey("plus").stringKey
        static let plusBlueIcon: String = LocalizedStringKey("blueplus").stringKey
        static let settingsIcon: String = LocalizedStringKey("settings").stringKey
        static let settingsBlueIcon: String = LocalizedStringKey("bluesettings").stringKey
        static let loggingOut: String = LocalizedStringKey("Logging out, please wait...").stringKey
    }

    enum RefreshControl {
        static let progressViewTest: String = LocalizedStringKey("Syncing...").stringKey
    }

    enum StandaloneSessionCardView {
        static let heading = LocalizedStringKey("Your AirBeam3 is now in stand-alone mode").stringKey
        static let description = LocalizedStringKey("AirBeam3 is now recording using its SD card. The measurements will be displayed here after syncing.").stringKey
        static let finishAndSyncButtonLabel = LocalizedStringKey("Finish recording & sync").stringKey
        static let finishAndDontSyncButtonLabel = LocalizedStringKey("Finish recording & don't sync").stringKey
    }

    enum SDSyncRootView {
        static let title: String = LocalizedStringKey("Updating sessions").stringKey
        static let message: String = LocalizedStringKey("Sessions must be updated prior to syncing SD card. Make sure your device is connected to the Internet.").stringKey
    }

    enum SDSyncSuccessView {
        static let title: String = LocalizedStringKey("Success").stringKey
        static let message: String = LocalizedStringKey("Sessions were updated successfully").stringKey
    }

    enum UnplugAirbeamView {
        static let title: String = LocalizedStringKey("Unplug your AirBeam").stringKey
        static let message: String = LocalizedStringKey("Keep it unplugged for the duration of the sync.").stringKey
    }

    enum SDRestartABView {
        static let title: String = LocalizedStringKey("Restart your AirBeam").stringKey
        static let message: String = LocalizedStringKey("Turn your AirBeam off and then back on.").stringKey
    }

    enum SyncingABView {
        static let message: String = LocalizedStringKey("Keep your AirBeam unplugged and close to your iPhone").stringKey
        static let alertTitle: String = LocalizedStringKey("SD card sync failed").stringKey
        static let alertMessage: String = LocalizedStringKey("We're sorry, something unexpected caused the SD card sync to fail. Please try again").stringKey
        static let startingSyncTitle: String = LocalizedStringKey("Syncing...").stringKey
        static let finishingSyncTitle: String = LocalizedStringKey("Finalizing...").stringKey
    }

    enum SDSyncCompleteView {
        static let title: String = LocalizedStringKey("Sync complete").stringKey
        static let message: String = LocalizedStringKey("The data from your AirBeam3 was synchronized successfully to the app. The SD card was cleared.").stringKey
        static let SDClearTitle: String = LocalizedStringKey("SD card cleared").stringKey
        static let SDClearMessage: String = LocalizedStringKey("SD inside your AirBeam was cleared sucesfully").stringKey
    }

    enum ClearingSDCardView {
        static let title: String = LocalizedStringKey("Clearing SD card").stringKey
        static let message: String = LocalizedStringKey("This should take less then 10 seconds.").stringKey
        static let failedClearingAlertTitle: String = LocalizedStringKey("Failed to clead SD card").stringKey
        static let failedClearingAlertMessage: String = LocalizedStringKey("Try again later").stringKey
    }

    enum DefaultDeleteSessionViewModel {
        static let all: String = LocalizedStringKey("All").stringKey
    }

    enum DeviceHandler {
        static let alertTitle = LocalizedStringKey("Not supported device").stringKey
        static let alertMessage = LocalizedStringKey("To use the AirBeam3 in standalone mode and sync the SD card, an iPhone8 or higher is required").stringKey
    }

    enum NetworkAlert {
        static let alertTitle: String = LocalizedStringKey("No internet connection").stringKey
        static let alertMessage: String = LocalizedStringKey("You need to have internet connection to continue").stringKey
    }

    enum MicrophoneAlert {
        static let title: String = LocalizedStringKey("Allow AirCasting to record audio").stringKey
        static let message: String = LocalizedStringKey("To record sound level measurements, the app needs access to your microhpone.").stringKey
    }

    enum InAppAlerts {
        static let assertError: String = LocalizedStringKey("Unsupported button count! For SwiftUI implementation max of 2 buttons is supported").stringKey
        static let unableToLogOutTitle: String = LocalizedStringKey("No internet connection").stringKey
        static let unableToLogOutMessage: String = LocalizedStringKey("To sign out, you must be connected to the Internet.").stringKey
        static let unableToLogOutButton: String = LocalizedStringKey("Got it!").stringKey
    }

    enum AddNoteView {
        static let title: String = LocalizedStringKey("Add a note").stringKey
        static let description: String = LocalizedStringKey("Your note will be timestamped and displayed on the AirCasting map").stringKey
        static let placeholder: String = LocalizedStringKey("Note").stringKey
        static let continueButton: String = LocalizedStringKey("Add a note").stringKey
        static let cancelButton: String = LocalizedStringKey("Cancel").stringKey
    }

    enum EditNoteView {
        static let title: String = LocalizedStringKey("Edit this note").stringKey
        static let description: String = LocalizedStringKey("You can edit your note here").stringKey
        static let placeholder: String = LocalizedStringKey("Note").stringKey
        static let saveButton: String = LocalizedStringKey("Save changes").stringKey
        static let deleteButton: String = LocalizedStringKey("Delete note").stringKey
        static let cancelButton: String = LocalizedStringKey("Cancel").stringKey
    }
}

// Extension allows us to preserve current Strings system and allow XCode to detect strings and then we are able to export then easly.
extension LocalizedStringKey {
    var stringKey: String {
        let description = "\(self)"
        let components = description.components(separatedBy: "key: \"").map { $0.components(separatedBy: "\",") }
        return components[1][0]
    }
}
