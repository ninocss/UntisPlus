# UntisPlus

<p align="center">
  <img src="assets/icon.png" alt="UntisPlus Logo" width="120" style="border-radius: 24px;"/>
</p>

<p align="center">
  <strong>A sleek, privacy-first companion app for WebUntis.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/ninocss/untisplus?style=for-the-badge&logo=github&color=3182ce" alt="GitHub stars">
  <img src="https://img.shields.io/github/forks/ninocss/untisplus?style=for-the-badge&logo=github&color=3182ce" alt="GitHub forks">
  <img src="https://img.shields.io/github/issues/ninocss/untisplus?style=for-the-badge&logo=github&color=e53e3e" alt="GitHub issues">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
</p>

---

## Overview

UntisPlus is a modern, secure, and intuitive Flutter client for students and teachers to manage school schedules, tasks, and communications. Built with privacy as the default: all authentication details, credentials, and schedule data stay strictly on your local device — nothing is ever shared with central servers.

| Aspect | Specification |
| :--- | :--- |
| **Data Policy** | Private by default. Credentials and schedule data never leave your device. |
| **Current Version** | `5.0.1` |
| **Target Platforms** | Android |

---

## Features

* **Advanced Timetable** — Fast, fluid, and optimized navigation for daily and weekly class schedules.
* **Exam & Info Tracker** — Consolidated overview of upcoming exams and direct broadcast announcements from your school.
* **Homework & Lesson Notes** — Seamless integration of homework and notes straight from WebUntis.
* **Smart Utilities** — Built-in free room finder and home screen widgets for immediate status checks.
* **Local Intelligence** — On-device assistive AI features that manage workflows privately, without sending data to the cloud.

---

## Screenshots

| Welcome | Timetable | Lesson Details |
| :---: | :---: | :---: |
| <img src="assets/github/welcome.png" width="240" alt="Welcome" /> | <img src="assets/github/timetable.png" width="240" alt="Timetable" /> | <img src="assets/github/lesson_inspect.png" width="240" alt="Lesson details" /> |

| AI Assistant | Appearance | Ready to Go |
| :---: | :---: | :---: |
| <img src="assets/github/AI_assistant.png" width="240" alt="AI assistant" /> | <img src="assets/github/Appearance.png" width="240" alt="Appearance settings" /> | <img src="assets/github/Ready_to_go.png" width="240" alt="Ready to go" /> |

---

## Roadmap

| Feature / Goal | Status |
| :--- | :---: |
| UI Refactor (Modernized aesthetics and enhanced user experience) | Done |
| Streamlined Onboarding Flow | Done |
| Homework & Lesson Notes Integration | Done |
| Multi-Account / Multi-School Support | Planned |
| Dynamic Lockscreen & Next-Lesson Widgets | Planned |
| Native Offline/Local AI Model Integration | Done |
| Dynamic Smart Alarm Sync (Wake up based on timetable changes) | Planned |

---

## Tech Stack & Key Dependencies

| Dependency | Purpose |
| :--- | :--- |
| **`http`** | WebUntis API communication |
| **`shared_preferences`** | Encrypted local token and setting persistence |
| **`dynamic_color`** | Material You dynamic theme integration |
| **`home_widget`** | Native Android and iOS widget connectivity |
| **`flutter_local_notifications`** | Time-critical lesson alerts and schedule update tracking |

---

## Project Structure

```
.
├── assets/                    # Graphic elements and app icons
├── lib/
│   ├── app/                   # Central application routing configuration
│   ├── core/                  # State engines, themes, and time utilities
│   ├── screens/               # System views, settings hub, and setup guides
│   ├── services/              # Notification, background sync, and backup engines
│   ├── web/                   # Web-specific platform adaptions
│   └── widgets/               # Reusable UI elements and background filters
└── pubspec.yaml               # Package definitions and metadata
```

---

## Development Setup

### System Prerequisites

Ensure the Flutter SDK is installed and configured in your environment variable path.

### Execution

```bash
# Clone the codebase
git clone https://github.com/ninocss/untisplus.git

# Navigate into the project folder
cd untisplus

# Resolve project dependencies
flutter pub get

# Launch the application in debug mode
flutter run
```

---

## Contributing

1. Fork the repository.
2. Clone your fork: `git clone https://github.com/your-username/untisplus.git`
3. Create a feature branch: `git checkout -b feature/your-feature`
4. Commit changes with clear messages: `git commit -am 'Add explicit feature description'`
5. Push to the branch: `git push origin feature/your-feature`
6. Open a Pull Request against the `main` branch.

Please give credits to UntisPlus (or your forked repo) in your work! ❤️

---

## Disclaimer

UntisPlus is an independent developer project. It is not affiliated, associated, authorized, endorsed by, or in any way officially connected with WebUntis or any of its subsidiaries or affiliates.
