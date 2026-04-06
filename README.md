<p align="center">
	<img src="assets/github/banner.png" alt="App_Banner" width="100%" />
</p>

<h1 align="center">Untis+</h1>

<p align="center">
	A Flutter client for WebUntis with a clean timetable, exam overview, room search, AI assistant, widgets, and background updates.
</p>

<p align="center">
	<strong>Private by default.</strong> Most settings stay on your device. Optional AI features use your own Gemini API key.
</p>

## Features

- Weekly and daily timetable views
- Exam overview and free room search
- School information and class selection flows
- Optional Gemini-powered AI assistant
- Persistent lesson notification and home widgets
- Cancelled lesson visibility, subject colors, and hidden subjects
- German, English, French, and Spanish
- Light, dark, and system themes

## Screenshots

### Timetable

<table>
	<tr>
		<td align="center"><img src="assets/github/timetable_weekly.png" width="320" alt="Weekly timetable" /><br />Weekly timetable</td>
		<td align="center"><img src="assets/github/timetable_daily.png" width="320" alt="Daily timetable" /><br />Daily timetable</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/timetable_daily_dark_mode.png" width="320" alt="Daily timetable in dark mode" /><br />Daily timetable, dark mode</td>
		<td align="center"></td>
	</tr>
</table>

### Exams, rooms, and school setup

<table>
	<tr>
		<td align="center"><img src="assets/github/exams.png" width="320" alt="Exams" /><br />Exams</td>
		<td align="center"><img src="assets/github/exams_dark_mode.png" width="320" alt="Exams in dark mode" /><br />Exams, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/free_rooms.png" width="320" alt="Free rooms" /><br />Free rooms</td>
		<td align="center"><img src="assets/github/free_rooms_dark_mode.png" width="320" alt="Free rooms in dark mode" /><br />Free rooms, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/school_info.png" width="320" alt="School info" /><br />School info</td>
		<td align="center"><img src="assets/github/school_info_dark_mode.png" width="320" alt="School info in dark mode" /><br />School info, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/select_class.png" width="320" alt="Select class" /><br />Select class</td>
		<td align="center"><img src="assets/github/select_class_dark_mode.png" width="320" alt="Select class in dark mode" /><br />Select class, dark mode</td>
	</tr>
</table>

### AI assistant

<table>
	<tr>
		<td align="center"><img src="assets/github/ai_assistant.png" width="320" alt="AI assistant" /><br />AI assistant</td>
		<td align="center"><img src="assets/github/ai_assistant_dark_mode.png" width="320" alt="AI assistant in dark mode" /><br />AI assistant, dark mode</td>
	</tr>
	<tr>
		<td align="center"><img src="assets/github/details_dark_mode.png" width="320" alt="Details in dark mode" /><br />Details, dark mode</td>
		<td align="center"></td>
	</tr>
</table>

## AI assistant (Gemini)

The AI assistant becomes available after you add your own Gemini API key.

1. Open Google AI Studio.
2. Create a new API key.
3. Copy the key into the app under **Settings > AI Assistant > Gemini API Key**.

The key is stored locally on your device. If you previously used an older OpenAI key, Untis+ migrates it automatically to `geminiApiKey` on startup.

## Notifications and widgets

Untis+ can refresh data in the background to keep widgets and notifications up to date.

- The current lesson notification can be enabled in settings.
- Widgets and notifications update automatically when the OS allows it.
- After the first login, data is loaded once immediately so widgets can show content right away.

If Android or iOS requests notification or background permissions, allow them so these features can work correctly.

## Privacy

Untis+ stores configuration data locally, including:

- Session ID
- School server and school name
- Username and password
- App settings
- Gemini API key, if configured

Data is sent only to:

- Your WebUntis server for authentication and timetable/exam data
- Google Gemini API, only if you enable the AI assistant

Untis+ does not use analytics or tracking.

## Requirements

- Flutter SDK 3.11 or newer
- A WebUntis account from your school
- Optional: a Gemini API key for AI features
- Notification permissions on Android or iOS for push features

## Development setup

Install dependencies:

```bash
flutter pub get
```

Run the app on a device or emulator:

```bash
flutter run
```

## Project structure

- [lib/main.dart](lib/main.dart) - entry point and main UI
- [lib/services/background_service.dart](lib/services/background_service.dart) - background updates for widgets and notifications
- [lib/services/notification_service.dart](lib/services/notification_service.dart) - local notifications
- [lib/services/widget_service.dart](lib/services/widget_service.dart) - widget data and widget updates

## Contributing

Issues and pull requests are welcome.

- Describe the expected and actual behavior.
- Include screenshots when UI changes are involved.
- Keep changes focused and consistent with the existing code style.

## Disclaimer

Untis+ is not affiliated with, endorsed by, or connected to WebUntis or its respective owners.