// Created by Lunar on 23/06/2021.
//

import Foundation

struct Strings {
    enum Commons {
        static let cancel: String = "Cancel"
        static let ok: String = "OK"
        static let myAccount: String = "My account"
        static let `continue`: String = "Continue"
        static let gotIt: String = "Got it!"
        static let note: String = "Note"
    }

    enum Settings {
        static let title: String = "Settings"
        static let myAccount: String = "My Account"
        static let crowdMap: String = "Contribute to CrowdMap"
        static let crowdMapDescription: String = "Data contributed to the CrowdMap is publicly available at aircasting.org"
        static let disableMapping: String = "Disable Mapping"
        static let disableMappingDescription: String = "Turns off GPS tracking & session syncing. Use \"Share file\" to retrieve your measurements via email."
        static let temperature = "Temperature Units"
        static let celsiusDescription = "Use Celsius"
        static let backendSettings: String = "Backend settings"
        static let settingsHelp: String = "Help"
        static let hardwareDevelopers: String = "Hardware developers"
        static let about: String = "About AirCasting"
        static let keepScreenTitle = "Keep screen on"
        static let clearSDTitle = "Clear SD card"
        static let appInfoTitle = "AirCasting App v"
        static let buildText = "build"
        static let betaBuild = "Beta build"
        static let debugBuild = "Debug build"
    }

    enum BackendSettings {
        static let backendSettings: String = "Backend settings"
        static let alertTitle: String = "Logout Alert"
        static let alertMessage: String = "Something went wrong, when logging out."
        static let currentURL: String = "current url"
        static let currentPort: String = "current port"
    }

    enum MyAccountSettings {
        static let notLogged: String = "You aren’t currently logged in"
        static let createAccount: String = "Create an account"
        static let logIn: String = "Log In"
    }

    enum SignOutSettings {
        static let logged: String = "You are currently logged in as "
        static let signOut: String = "Sign Out"
    }

    enum ForgotPassword {
        static let title = "Forgot Password"
        static let emailInputTitle = "email or username"
        static let newPasswordSuccessMessage = "Email was sent. Please check your inbox for the details."
        static let newPasswordSuccessTitle = "Email response"
        static let newPasswordFailureMessage = "Something went wrong, please try again"
        static let newPasswordFailureTitle = "Email response"
    }

    enum SignInView {
        static let title_2 = "to record and map your environment"
        static let usernameField = "Profile name"
        static let passwordField = "Password"
        static let forgotPasswordButton = "Forgot password?"
        static let signIn = "Sign in"
        static let signUpButton_1 = "First time here? "
        static let signUpButton_2 = "Create an account"
        static let alertTitle = "Login Error"
        static let alertComment = "Login Error alert title"
        static let InvalidCredentialText = "The profile name or password is incorrect. Please try again. "
        static let noConnectionTitle = "No Internet Connection"
        static let noConnectionText = "Please make sure your device is connected to the internet."
    }

    enum SessionShare {
        static let title: String = "Share session"
        static let description: String = "Select a stream to share"
        static let locationlessDescription: String = "Generate a CSV file with your session data"
        static let emailDescription: String = "Or email a CSV file with your session data"
        static let emailPlaceholder: String = "Email"
        static let linkSharingAlertTitle: String = "Sharing failed"
        static let linkSharingAlertMessage: String = "Try again later"
        static let emailSharingAlertTitle: String = "Request failed"
        static let emailSharingAlertMessage: String = "Please try again later"
        static let shareLinkButton: String = "Share link"
        static let shareFileButton: String = "Share file"
        static let loadingFile: String = "Generating file"
        static let invalidEmailLabel: String = "This email is invalid"
    }

    enum LoadingSession {
        static let title: String = "Your AirBeam is gathering data."
        static let description: String = "Measurements will appear in 3 minutes."
    }

    struct SessionCartView {
        static let map: String = "map"
        static let graph: String = "graph"
        static let follow: String = "follow"
        static let unfollow: String = "unfollow"
        static let avgSessionH: String = "1 hr avg -"
        static let avgSessionMin: String = "1 min avg -"
    }

    struct SingleMeasurementView {
        static let microphoneUnit: String = "dB"
        static let celsiusUnit: String = "C"
        static let fahrenheitUnit: String = "F"
    }

    enum SelectPeripheralView {
        static let airBeamsText: String = "AirBeams"
        static let otherText: String = "Other devices"
        static let alertTitle: String = "Connection error"
        static let alertMessage: String = "Bluetooth connection failed. Please toggle the power on your device and try again."
        static let titleLabel: String = "Choose the device you'd like to record with"
        static let titleSyncLabel: String = "Select the device you'd like to sync"
        static let titleSDClearLabel: String = "Select the device you'd like to clear"
        static let refreshButton: String = "Don't see a device? Refresh scanning."
        static let connectText: String = "Connect"
    }

    enum SessionCart {
        static let measurementsTitle: String = "Last second measurement:"
        static let dormantMeasurementsTitle: String = "Avg value:"
        static let heatmapSettingsTitle: String = "Heatmap settings"
        static let heatmapSettingsdescription: String = "Values beyond Min and Max will not be displayed."
        static let saveChangesButton: String = "Save changes"
        static let resetChangesButton: String = "Reset to default"
        static let parametersText: String = "Parameters:"
        static let lastMinuteMeasurement: String = "Last minute measurement"
    }

    enum Thresholds {
        static let veryHigh: String = "Max"
        static let high: String = "High"
        static let medium: String = "Medium"
        static let low: String = "Low"
        static let veryLow: String = "Min"
    }

    enum WifiPopupView {
        static let wifiPlaceholder: String = "Wi-Fi name"
        static let passwordPlaceholder: String = "Password"
        static let connectButton: String = "Connect"
        static let passwordTitle: String = "WiFi network name & password:"
        static let nameAndPasswordTitle_1: String = "Password for "
        static let nameAndPasswordTitle_2: String = " network:"
        static let differentNetwork: String = "Connect to a different WiFi network."
    }

    enum OnboardingGetStarted {
        static let description: String = "record and map measurements from health and environmental monitoring devices"
        static let getStarted: String = "Get started"
    }

    enum OnboardingNearAir {
        static let title: String = "How’s the air \nnear you?"
        static let description: String = "Find and follow a fixed air quality monitor near you and know how clean or polluted your air is right now."
        static let continueButton: String = "How’s the air \nnear you?"
    }

    enum OnboardingAirBeam {
        static let title: String = "Measure and map \nyour exposure \nto air pollution"
        static let description: String = "Connect AirBeam to measure air quality humidity, and temperature."
        static let sheetButton: String = "Learn More"
    }

    enum OnboardingAirBeamSheet {
        static let sheetTitle: String = "How AirBeam \nworks?"
        static let sheetDescription_1: String = "In "
        static let sheetDescription_2: String = "mobile "
        static let sheetDescription_3: String = "mode, the AirBeam \ncaptures personal exposures.\n\nIn "
        static let sheetDescription_4: String = "fixed "
        static let sheetDescription_5: String = "mode, it can be \ninstalled indoors or outdoors to \nkeep tabs on pollution levels in \nyour home, office, backyard, or \nneighborhood 24/7."
    }

    enum OnboardingPrivacy {
        static let title: String = "Your privacy"
        static let description: String = "Review our commitment to preserving your privacy and accept our privacy policy."
        static let continueButton: String = "Accept"
        static let sheetButton: String = "Learn More"
    }

    enum OnboardingPrivacySheet {
        static let title: String = "Our privacy policy"
        static let description: String = """
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

 """
    }

    enum EmptyDashboardMobile {
        static let title: String = "Start recording a \nmobile session"
        static let description: String = "If you plan on moving around \nwhile recording measurements."
        static let buttonMobile: String = "Record mobile session"
        static let buttonFixed: String = "Record new session"
        static let airBeamDescriptionText: String = "Did you know?"
        static let airBeamDescriptionDescription: String = "AirBeam3 is weather resistant. To keep tabs on your outdoor air quality 24/7, hang one outside your home and record a fixed session."
        static let fetchingText: String = "Fetching..."
    }

    enum EmptyDashboardFixed {
        static let title: String = "Ready to get started?"
        static let description: String = "Record a new session to monitor\n your health & environment."
        static let newSession: String = "Record new session"
        static let fetchingText: String = "Fetching..."
    }
    
    enum ReorderingDashboard {
        static let navigationTitle: String = NSLocalizedString("Reordering", comment: "Navigation title in reordering sessions view")
    }

    enum PowerABView {
        static let alertTitle: String = "Location alert"
        static let alertMessage: String = "Please go to settings and allow location first."
        static let alertSettings: String = "Settings"
        static let title: String = "Power on your AirBeam"
        static let messageText: String = "Wait for the conncection indicator to change from red to green before continuing."
    }

    enum SelectDeviceView {
        static let alertTitle: String = "Location alert"
        static let alertMessage: String = "Please go to settings and allow location first."
        static let alertSettings: String = "Settings"
        static let title: String = "What device are you using to record this session?"
        static let bluetoothLabel_1: String = "Bluetooth device"
        static let bluetoothLabel_2: String = "for example AirBeam"
        static let micLabel_1: String = "Phone microphone"
        static let micLabel_2: String = "to measure sound level"
        static let chooseButton: String = "Choose"
    }

    enum OfflineAlert {
        static let title = "Device is offline"
        static let message = "Could not finish session synchronization"
    }

    enum TurnOnBluetoothView {
        static let title: String = "Turn on Bluetooth"
        static let messageText: String = "Turn on Bluetooth to enable your phone to connect to the AirBeam"
    }

    enum TurnOnLocationView {
        static let title: String = "Turn on location services"
        static let messageText: String = "To map your measurements, turn on location services."
        static let continueButton: String = "Turn on"
    }

    enum DeleteSession {
        static let title: String = "Delete this session"
        static let description: String = "Which stream would you like to delete?"
        static let continueButton: String = "Delete streams"
        static let deleteAlert: String = "Are You sure?"
        static let deleteButton: String = "Delete"
    }

    enum EditSession {
        static let title: String = "Edit session details"
        static let namePlaceholder: String = "Session name"
        static let tagPlaceholder: String = "Session tags"
        static let buttonAccept: String = "Accept"
        static let erorr: String = "Session name can't be blank"
    }

    enum SessionHeaderView {
        static let measurementsMicText: String = "Most recent measurement:"
        static let stopButton: String = "Stop recording"
        static let editButton: String = "Edit session"
        static let shareButton: String = "Share session"
        static let deleteButton: String = "Delete session"
        static let stopRecordingButton: String = "Finish recording session"
        static let enterStandaloneModeButton: String = "Enter standalone mode"
        static let finishAlertTitle: String = "Finish recording "
        static let finishAlertTitle_2: String = "this session"
        static let finishAlertTitle_3: String = "?"
        static let finishAlertTitle_3_SYNC: String = "and sync from SD card?"
        static let finishAlertMessage_1: String = "The session will be moved to "
        static let finishAlertMessage_2: String = "Mobile Dormant"
        static let finishAlertMessage_3: String = " tab and you won't be able to add new measurement to it."
        static let finishAlertMessage_4: String = "\nSD card will be cleared afterwards"
        static let finishAlertButton: String = "Finish recording"
        static let shareFileAlertTitle: String = "Success!"
        static let shareFileAlertMessage: String = "The session file was sent to provided email address"
        static let airBeam3: String = "AirBeam3"
        static let airBeam2: String = "AirBeam2"
        static let airBeam1: String = "AirBeam1"
        static let mic: String = "Phone Mic"
        static let addNoteButton: String = "Add a note"
    }

    enum NetworkChecker {
        static let satisfiedPathText: String = "Current device has a network connection"
        static let failurePathText: String = "Current device DOES NOT have a network connection"
    }

    enum ChooseSessionTypeView {
        static let title: String = "Let's begin"
        static let message: String = "How would you like to add your session?"
        static let recordNew: String = "Record a new session"
        static let moreInfo: String = "more info"
        static let fixedLabel_1: String = "Fixed session"
        static let fixedLabel_2: String = "for measuring in one place"
        static let mobileLabel_1: String = "Mobile session"
        static let mobileLabel_2: String = "for moving\naround"
        static let orLabel: String = "or"
        static let syncTitle: String = "Sync data from \nAirBeam3"
        static let syncDescription: String = "if you recorded with AirBeam3"

    }

    enum MoreInfoPopupView {
        static let text_1: String = "Session types"
        static let text_2: String = "If you plan on moving around with the AirBeam3 while recording air quality measurement, configure the AirBeam to record a mobile session. When recording a mobile AirCasting session, measurements are created, timestamped, and geolocated once per second."
        static let text_3: String = "If you plan to leave the AirBeam3 indoors or hang it outside then configure it to record a fixed session. When recording fixed AirCasting sessions, measurements are created and timestamped once per minute, and geocoordinates are fixed to a set location."
    }

    enum ConnectingABView {
        static let title: String = "Connecting"
        static let message: String = "This should take less than 10 seconds."
        static let connect: String = "Connect"
    }

    enum ABConnectedView {
        static let title: String = "AirBeam connected"
        static let message: String = "Your AirBeam is connected to your phone and ready to take some measurements."
    }

    enum CreateSessionDetailsView {
        static let wifiAlertTitle: String = "Wi-Fi credentials are empty "
        static let wifiAlertMessage: String = "Please, fill them up."
        static let primaryWifiButton: String = "Show Wi-fi screen"
        static let title: String = "New session details"
        static let placementPicker_1: String = "Where will you place your AirBeam?"
        static let placementPicker_2: String = "Indoor"
        static let placementPicker_3: String = "Outdoor"
        static let transmissionPicker: String = "Data transmission:"
        static let cellularText: String = "Cellular"
        static let wifiText: String = "Wi-Fi"
        static let sessionNamePlaceholder: String = "Session name"
        static let sessionTagPlaceholder: String = "Tags"
    }

    enum AirBeamConnector {
        static let connectionTimeoutTitle: String = "Connection error"
        static let connectionTimeoutDescription: String = "Bluetooth connection failed. Please toggle the power on your device and try again."
    }

    enum ConfirmCreatingSessionView {
        static let alertTitle: String = "Failure"
        static let alertMessage: String = "Failed to create session"
        static let contentViewTitle: String = "Are you ready?"
        static let contentViewText_1: String = "Your "
        static let contentViewText_2: String = " session "
        static let contentViewText_3: String = " is ready to start gathering data.\n\n"
        static let contentViewText_4: String = "Hang your AirBeam in a secure position, then press the start recording button below."
        static let contentViewText_4Mobile: String = "Move to your starting location, confirm your location is accurate on the map, then press the start recording button below."
        static let startRecording: String = "Start recording"
    }

    enum ChooseCustomLocationView {
        static let sessionLocation: String = "Session location"
        static let titleLabel: String = "Search the address and adjust the marker to indicate an exact placement of Your AirBeam"
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
        static let dashboardText: String = "Dashboard"
        static let following: String = NSLocalizedString("Following", comment: "")
    }

    enum RefreshControl {
        static let progressViewTest: String = "Syncing..."
    }

    enum StandaloneSessionCardView {
        static let heading = "Your AirBeam3 is now in stand-alone mode"
        static let description = "AirBeam3 is now recording using its SD card. The measurements will be displayed here after syncing."
        static let finishAndSyncButtonLabel = "Finish recording & sync"
        static let finishAndDontSyncButtonLabel = "Finish recording & don't sync"
    }

    enum SDSyncRootView {
        static let title: String = "Updating sessions"
        static let message: String = "Sessions must be updated prior to syncing SD card. Make sure your device is connected to the Internet."
    }

    enum SDSyncSuccessView {
        static let title: String = "Success"
        static let message: String = "Sessions were updated successfully"
    }

    enum UnplugAirbeamView {
        static let title: String = "Unplug your AirBeam"
        static let message: String = "Keep it unplugged for the duration of the sync."
    }

    enum SDRestartABView {
        static let title: String = "Restart your AirBeam"
        static let message: String = "Turn your AirBeam off and then back on."
    }

    enum SyncingABView {
        static let message: String = "Keep your AirBeam unplugged and close to your iPhone"
        static let alertTitle: String = "SD card sync failed"
        static let alertMessage: String = "We're sorry, something unexpected caused the SD card sync to fail. Please try again"
        static let startingSyncTitle: String = "Syncing..."
        static let finishingSyncTitle: String = "Finalizing..."
    }

    enum SDSyncCompleteView {
        static let title: String = "Sync complete"
        static let message: String = "The data from your AirBeam3 was synchronized successfully to the app. The SD card was cleared."
        static let SDClearTitle: String = "SD card cleared"
        static let SDClearMessage: String = "SD inside your AirBeam was cleared sucesfully"
    }

    enum ClearingSDCardView {
        static let title: String = "Clearing SD card"
        static let message: String = "This should take less then 10 seconds."
        static let failedClearingAlertTitle: String = "Failed to clead SD card"
        static let failedClearingAlertMessage: String = "Try again later"
    }

    enum DefaultDeleteSessionViewModel {
        static let all: String = "All"
    }

    enum DeviceHandler {
        static let alertTitle = "Not supported device"
        static let alertMessage = "To use the AirBeam3 in standalone mode and sync the SD card, an iPhone8 or higher is required"
    }

    enum NetworkAlert {
        static let alertTitle: String = "No internet connection"
        static let alertMessage: String = "You need to have internet connection to continue"
    }

    enum MicrophoneAlert {
        static let title: String = "Allow AirCasting to record audio"
        static let message: String = "To record sound level measurements, the app needs access to your microhpone."
    }

    enum InAppAlerts {
        static let assertError: String = "Unsupported button count! For SwiftUI implementation max of 2 buttons is supported"
        static let unableToLogOutTitle: String = "No internet connection"
        static let unableToLogOutMessage: String = "To sign out, you must be connected to the Internet."
        static let unableToLogOutButton: String = "Got it!"
    }

    enum AddNoteView {
        static let title: String = "Add a note"
        static let description: String = "Your note will be timestamped and displayed on the AirCasting map"
        static let placeholder: String = "Note"
        static let continueButton: String = "Add a note"
        static let cancelButton: String = "Cancel"
    }

    enum EditNoteView {
        static let title: String = "Edit this note"
        static let description: String = "You can edit your note here"
        static let placeholder: String = "Note"
        static let saveButton: String = "Save changes"
        static let deleteButton: String = "Delete note"
        static let cancelButton: String = "Cancel"
    }
}
