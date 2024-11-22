# location_verification_app
Setup Instructions

Prerequisites:

-Install Flutter and configure it on your system.

-Install Android Studio and/or Xcode if running on iOS.

-Set up a virtual emulator or connect a physical device for testing.

* Step 1: Clone the Repository

Clone the repository and navigate into the project directory:

"git clone https://github.com/AlvinsGitHubb/Location-Verification-App"

"cd Location-Verification-App"

* Step 2: Install Dependencies

Fetch all required dependencies using the following Flutter command:

"flutter pub get"

* Step 3: Configure Google Maps API Key

Obtain an API Key

Go to the Google Cloud Console.

Create a new project or select an existing one.

Enable the "Google Maps SDK for Android" and "Google Maps SDK for iOS".

Generate an API key for your project.

Add API Key to the Project

Android:
Add your API key in android/app/src/main/AndroidManifest.xml:
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>

iOS:
Add your API key in ios/Runner/AppDelegate.swift:
GMSServices.provideAPIKey("YOUR_API_KEY")

* Step 4: iOS-Specific Setup

Open the iOS project in Xcode:

open ios/Runner.xcworkspace

Set a unique Bundle Identifier in the Xcode project settings.

Enable background location updates by editing the Info.plist file:

<key>UIBackgroundModes</key>
<array>
    <string>location</string>
</array>

Run pod install to set up dependencies:

"cd ios"

"pod install"

"cd .."

* Step 5: Running the App

Android:
Run the app on an Android emulator or device:
"flutter run"

iOS:
Run the app on an iOS device:
"flutter run --no-sound-null-safety"

Flutter Commands for Maintenance

Clean the project:
"flutter clean"

Upgrade dependencies:
"flutter pub upgrade"

Analyze the codebase for issues:
"flutter analyze"

Build APK (Android Release):
"flutter build apk --release"
