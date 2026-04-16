<p align="center">
	<img src="assets/github/banner.png" alt="Untis+ Banner" width="100%" />
</p>

<h1 align="center">Untis+</h1>

<p align="center">
	Modern Flutter client for WebUntis with timetable, exams, free room search,
	school announcements, widgets, and an optional AI assistant.
</p>

<p align="center">
	<a href="https://github.com/ninocss/UntisPlus/releases"><img src="https://img.shields.io/github/v/release/ninocss/UntisPlus?label=Release" alt="Latest Release" /></a>
	<img src="https://img.shields.io/badge/Platform-Android-3DDC84" alt="Android" />
	<img src="https://img.shields.io/badge/Flutter-3.11%2B-02569B" alt="Flutter" />
	<img src="https://img.shields.io/badge/Privacy-Local%20first-success" alt="Privacy" />
</p>

<p align="center">
	<strong>Privacy by default:</strong> Your data stays on your device.
	AI features are optional and use your own Gemini API key.
</p>

## Table of Contents

- [Why Untis+?](#why-untis)
- [Installation](#installation)
- [Features](#features)
- [Screenshots](#screenshots)
- [AI Assistant (Gemini)](#ai-assistant-gemini)
- [Widgets and Notifications](#widgets-and-notifications)
- [Privacy](#privacy)
- [Requirements](#requirements)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Disclaimer](#disclaimer)

## Why Untis+?

Untis+ is designed for a fast, clean, and practical school experience:

- Clean daily and weekly timetable views
- Exam overview with custom entries and import/export
- Free room search and school announcements in one app
- Reliable widgets with background refresh
- Optional AI assistant for quick school-related questions

## Installation

1. Download the latest APK from [GitHub Releases](https://github.com/ninocss/UntisPlus/releases).
2. Install the APK on your Android device.
3. Sign in with your WebUntis account or start in demo mode.

## Features

| Area | Description |
| --- | --- |
| Timetable | Daily and weekly view, absences, cancellations, custom colors |
| Exams | Exam overview, custom exams, import/export |
| Free Rooms | Quickly see which rooms are currently available |
| School Announcements | Feed for school updates |
| Widgets | Home screen widgets with current data |
| Notifications | Persistent "Current lesson" notification |
| AI (optional) | Gemini integration with your own API key |
| Demo Mode | Try the app without a WebUntis login |
| Languages | German, English, French, Spanish, Greek |
| Themes | Light, dark, system + animated backgrounds |

## Screenshots

### Timetable

<table>
	<tr>
		<td align="center"><img src="assets/github/timetable_weekly.png" width="320" alt="Weekly timetable" /><br />Weekly timetable</td>
		<td align="center"><img src="assets/github/timetable_daily.png" width="320" alt="Daily timetable" /><br />Daily timetable</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/timetable_daily_dark_mode.png" width="320" alt="Daily timetable dark mode" /><br />Daily timetable, dark mode</td>
		<td align="center"></td>
	</tr>
</table>

### Exams, free rooms, and school setup

<table>
	<tr>
		<td align="center"><img src="assets/github/exams.png" width="320" alt="Exams" /><br />Exams</td>
		<td align="center"><img src="assets/github/exams_dark_mode.png" width="320" alt="Exams dark mode" /><br />Exams, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/free_rooms.png" width="320" alt="Free rooms" /><br />Free rooms</td>
		<td align="center"><img src="assets/github/free_rooms_dark_mode.png" width="320" alt="Free rooms dark mode" /><br />Free rooms, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/school_info.png" width="320" alt="School announcements" /><br />School announcements</td>
		<td align="center"><img src="assets/github/school_info_dark_mode.png" width="320" alt="School announcements dark mode" /><br />School announcements, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/select_class.png" width="320" alt="Select class" /><br />Select class</td>
		<td align="center"><img src="assets/github/select_class_dark_mode.png" width="320" alt="Select class dark mode" /><br />Select class, dark mode</td>
	</tr>
</table>

### AI Assistant

<table>
	<tr>
		<td align="center"><img src="assets/github/ai_assistant.png" width="320" alt="AI assistant" /><br />AI assistant</td>
		<td align="center"><img src="assets/github/ai_assistant_dark_mode.png" width="320" alt="AI assistant dark mode" /><br />AI assistant, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/details_dark_mode.png" width="320" alt="Details dark mode" /><br />Details, dark mode</td>
		<td align="center"></td>
	</tr>
</table>

## AI Assistant (Gemini)

The AI assistant becomes available after you add your own Gemini API key:

1. Open [Google AI Studio](https://aistudio.google.com/).
2. Create a new API key.
3. Add the key in the app under **Settings > AI Assistant > Gemini API Key**.

The API key is stored locally on your device.

## Widgets and Notifications

Untis+ can refresh data in the background to keep widgets and notifications up to date.

- Enable the persistent "Current lesson" notification in **Settings > Progressive push notification**.
- Widgets and notifications update automatically when Android allows background updates.
- After the first login, data is fetched immediately so widgets can show content right away.

If Android asks for notification or background permissions, allow them so these features work correctly.

## Privacy

Untis+ stores data locally on your device, including:

- Session-ID
- Session ID
- School server and school name
- Username and password
- App settings
- Gemini API key (if configured)

Data is sent only to:

- Your WebUntis server for authentication and timetable/exam data
- Google Gemini API, only if the AI assistant is enabled

Untis+ does not use analytics or tracking.

## Requirements

- Flutter SDK 3.11 or newer
- A WebUntis account from your school
- Optional: Gemini API key for AI features

## Development Setup

Install dependencies:

```bash
flutter pub get
```

Run the app on a device or emulator:

```bash
flutter run
```

Build a release APK:

```bash
flutter build apk --release
```

## Project Structure

- [lib/main.dart](lib/main.dart) - App entry point
- [lib/l10n.dart](lib/l10n.dart) - Localization strings (DE, EN, FR, ES, EL)
- [lib/app/untis_plus_app.dart](lib/app/untis_plus_app.dart) - App shell and theme setup
- [lib/screens/main_navigation_screen.dart](lib/screens/main_navigation_screen.dart) - Main navigation
- [lib/screens/onboarding_flow.dart](lib/screens/onboarding_flow.dart) - Login and school setup
- [lib/services/background_service.dart](lib/services/background_service.dart) - Background refresh
- [lib/services/notification_service.dart](lib/services/notification_service.dart) - Persistent notifications
- [lib/services/widget_service.dart](lib/services/widget_service.dart) - Home screen widgets
- [lib/services/demo_mode_service.dart](lib/services/demo_mode_service.dart) - Demo data

## Contributing

Issues and pull requests are welcome.

- Describe expected and actual behavior.
- Include screenshots when UI behavior changes.
- Keep changes focused and consistent with the existing code style.

## Disclaimer

Untis+ is not affiliated with, endorsed by, or connected to WebUntis or its respective owners.