# Untis+

Untis+ is a Flutter app for WebUntis, focused on quick access to the timetable, exams, notifications, and widgets. Most settings are stored locally on the device, and the app can also use a Gemini API key for the AI assistant.

## Features

- Log in against a WebUntis server
- Weekly and daily timetable views
- Exam overview
- Gemini-powered AI assistant
- Persistent push notification for the current lesson
- Home widgets for the current lesson and the daily schedule
- Show or hide cancelled lessons
- Customize subject colors
- Hide subjects
- Switch between German, English, French, and Spanish
- Light, dark, and system themes

## Set Up the Gemini API Key

The Gemini API key is used for the AI assistant in the timetable view.

### 1. Create an API key

1. Open Google AI Studio.
2. Create an API key there.
3. Copy the key.

Note: The app also shows the reference aistudio.google.com/app/apikey in the settings dialog.

### 2. Add it in the app

1. Open **Settings** in the app.
2. Open the **AI Assistant** section.
3. Tap **Gemini API Key**.
4. Paste the key and save it.

The key is stored locally. If you want to remove it, open the same dialog again and delete the key.

### 3. Important notes

- The AI assistant is not available without an API key.
- If you were using an older OpenAI key, the value is automatically migrated to `geminiApiKey`.
- The key is stored only locally on the device.

## Notifications and Widgets

Untis+ can load data in the background to keep notifications and widgets up to date.

- The progressive push notification can be enabled or disabled in settings.
- The app updates widgets and notifications automatically when possible.
- After the first login, data is loaded once immediately so widgets can show content right away.

If Android or iOS asks for permissions, grant them so notifications work correctly.

## In-App Settings

Under **Settings**, you can adjust among other things:

- Language
- Color scheme
- Display of cancelled lessons
- Background animations
- Progressive push notification
- Gemini API key
- Subject colors
- Hidden subjects

## Privacy and Storage

The app stores configuration data **locally** on the device, including:

- Session ID
- School server and school name
- Username and password
- App settings
- Gemini API key

No data is sent to any external server except the WebUntis server for authentication and timetable data, and the Gemini API for AI features if configured. The app does not use any analytics or tracking services. Everything is DsGVO compliant and made by a student for students.

## Requirements

- Flutter SDK 3.11 or newer
- A WebUntis account from your school
- A Gemini API key if you want to use the AI assistant
- Notification permissions on Android and iOS if you want push features to work

## Set Up the Project

1. Install dependencies:

```bash
flutter pub get
```

2. Start the app on a device or emulator:

```bash
flutter run
```

3. Optional: create a release build:

```bash
flutter build apk
```


## Project Structure

- [lib/main.dart](lib/main.dart) - Entry point and main UI
- [lib/services/background_service.dart](lib/services/background_service.dart) - Background updates for widgets and notifications
- [lib/services/notification_service.dart](lib/services/notification_service.dart) - Local notifications
- [lib/services/widget_service.dart](lib/services/widget_service.dart) - Widget data and widget updates

## Build Notes

The project uses Flutter and the packages defined in [pubspec.yaml](pubspec.yaml), including among others:

- http
- shared_preferences
- flutter_local_notifications
- workmanager
- home_widget
- dynamic_color

If you later need a short project description for a store listing or release file, I can also turn this README into a more compact marketing version.
