# UntisPlus

![GitHub stars](https://img.shields.io/github/stars/ninocss/UntisPlus?style=for-the-badge&logo=github) ![GitHub forks](https://img.shields.io/github/forks/ninocss/UntisPlus?style=for-the-badge&logo=github) ![GitHub issues](https://img.shields.io/github/issues/ninocss/UntisPlus?style=for-the-badge&logo=github) ![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)

## 📑 Table of Contents

- [Description](#description)
- [Quick Start](#quick-start)
- [Key Dependencies](#key-dependencies)
- [Screenshots](#screenshots)
- [Project Structure](#project-structure)
- [Development Setup](#development-setup)
- [Contributing](#contributing)

## 📝 Description

UntisPlus is a modern, privacy-focused Flutter client for WebUntis, designed to provide a seamless and intuitive experience for students and teachers. Beyond a standard timetable, UntisPlus offers a comprehensive suite of tools including a detailed exam overview, a convenient free room search, and direct access to school announcements. Stay organized with customizable home screen widgets and reliable background updates that keep your schedule synchronized. Leveraging the power of an integrated AI assistant, UntisPlus helps you navigate your academic life with ease. Committed to your security, the app is private by default, ensuring all your data remains stored locally on your device rather than on a server.

## 📸 Screenshots

<table>
  <tr>
    <td align="center"><img src="assets/github/welcome.png" width="320" alt="Onboarding" /><br />Onboarding</td>
    <td align="center"><img src="assets/github/timetable.png" width="320" alt="Timetable" /><br />Timetable</td>
  </tr>
  <tr>
    <td align="center"><img src="assets/github/details.png" width="320" alt="Lesson details" /><br />Lesson details</td>
    <td align="center"><img src="assets/github/exams.png" width="320" alt="Exams" /><br />Exams</td>
  </tr>
  <tr>
    <td align="center"><img src="assets/github/school%20info.png" width="320" alt="School info" /><br />School info</td>
    <td align="center"><img src="assets/github/settings.png" width="320" alt="Settings" /><br />Settings</td>
  </tr>
</table>

## Roadmap
- [X] Redesign the App for a more modern and user-friendly interface, enhancing the overall user experience.
- [X] Implement a new, more intuitive onboarding flow to improve the initial user experience.
- [ ] Support multiple WebUntis accounts, allowing users to easily switch between different schools or profiles.
- [ ] Add a widget that displays the next upcoming lesson, providing quick access to essential information.
- [ ] Support Local AI models, enabling users to leverage AI capabilities without relying on external servers, thus enhancing privacy and performance.
- [ ] Implementing a function to automatically set a alarm matching to wake up the next day!

## ⚡ Quick Start

```bash

# Clone the repository
git clone https://github.com/ninocss/UntisPlus.git

# Get packages and run
flutter pub get && flutter run
```

## 📦 Key Dependencies

```
name: untisplus
description: "A Flutter application for managing and viewing school schedules, homework, and other related information. It provides features such as timetable management, homework tracking, and notifications to help students stay organized and on top of their academic responsibilities."
publish_to: 'none'
version: 4.0.1+1
sdk: flutter
http: ^1.6.0
google_fonts: ^8.1.0
intl: ^0.20.2
shared_preferences: ^2.5.5
dynamic_color: ^1.8.1
flutter_launcher_icons: ^0.14.4
cupertino_icons: ^1.0.8
simple_animations: ^5.2.0
home_widget: ^0.9.1
flutter_local_notifications: ^21.0.0
```

## 📁 Project Structure

```
.
├── analysis_options.yaml
├── assets
│   ├── github
│   │   ├── ai.png
│   │   ├── banner.png
│   │   ├── details.png
│   │   ├── exams.png
│   │   ├── school info.png
│   │   ├── settings.png
│   │   ├── timetable.png
│   │   └── welcome.png
│   ├── icon.png
│   └── icon_with_bg.png
├── devtools_options.yaml
├── lib
│   ├── app
│   │   └── untis_plus_app.dart
│   ├── core
│   │   ├── app_state.dart
│   │   ├── custom_backgrounds.dart
│   │   ├── design_tokens.dart
│   │   ├── school_models.dart
│   │   ├── shared_ui.dart
│   │   └── time_utils.dart
│   ├── l10n.dart
│   ├── main.dart
│   ├── screens
│   │   ├── custom_background_editor_screen.dart
│   │   ├── main_navigation_screen.dart
│   │   ├── onboarding_flow.dart
│   │   ├── settings
│   │   │   ├── settings_about_updates_page.dart
│   │   │   ├── settings_account_page.dart
│   │   │   ├── settings_ai_page.dart
│   │   │   ├── settings_appearance_page.dart
│   │   │   ├── settings_backup_page.dart
│   │   │   ├── settings_notifications_page.dart
│   │   │   ├── settings_subjects_page.dart
│   │   │   └── settings_timetable_page.dart
│   │   └── settings_hub.dart
│   ├── services
│   │   ├── background_service.dart
│   │   ├── backup_service.dart
│   │   ├── demo_mode_service.dart
│   │   ├── notification_service.dart
│   │   └── widget_service.dart
│   ├── web
│   │   ├── file_download_helper.dart
│   │   └── file_download_helper_stub.dart
│   └── widgets
│       ├── animated_background.dart
│       ├── custom_background_view.dart
│       └── rounded_blur_app_bar.dart
├── pubspec.lock
├── pubspec.yaml
└── web
    ├── favicon.png
    ├── icons
    │   ├── Icon-192.png
    │   ├── Icon-512.png
    │   ├── Icon-maskable-192.png
    │   └── Icon-maskable-512.png
    ├── index.html
    └── manifest.json
```

## 🛠️ Development Setup

### Flutter Setup
1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
2. Run: `flutter pub get`
3. Start the app: `flutter run`

## 👥 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Clone** your fork: `git clone https://github.com/ninocss/UntisPlus.git`
3. **Create** a new branch: `git checkout -b feature/your-feature`
4. **Commit** your changes: `git commit -am 'Add some feature'`
5. **Push** to your branch: `git push origin feature/your-feature`
6. **Open** a pull request

Please ensure your code follows the project's style guidelines and includes tests where applicable.

## Disclaimer

Untis+ is not affiliated with, endorsed by, or connected to WebUntis or its respective owners.
