# Version v5.0.0

This major v5.0.0 release brings a significant visual overhaul to Untis+, featuring a modern frosted glass design and an updated app icon. Beyond the fresh look, we've introduced powerful new capabilities, including direct integration for WebUntis homework and lesson notes, and experimental on-device AI models with chat functionality.

## What's New
*   Integrate homework and lesson notes directly from WebUntis, providing a more comprehensive overview of your academic tasks.
*   Introduce experimental on-device local AI models, complete with a dedicated download manager and streaming chat functionality, accessible via a new settings page.

## Improvements
*   Redesign the app's overall visual style with a modern "frosted glass" aesthetic, likely applied to elements like app bars and backgrounds.
*   Update the app icon for a fresh and contemporary look.
*   Implement a "day carousel" for improved navigation, likely within the main schedule or overview screen.
*   Enhance notifications with localization support, making them more relevant to your language settings.
*   Refine the user interface across various screens, including settings and main navigation, for a more polished experience.

## Technical Notes
*   Update various Android build configurations, Gradle properties, and wrapper settings, likely for improved compatibility and performance.
*   Adjust project dependencies in `pubspec.yaml` and `pubspec.lock`, supporting new features and ensuring stability.
*   Modify `analysis_options.yaml` to update code quality and linting rules.
*   Add or modify an internal `script.py` file, likely used for development or build automation tasks.
*   Update internal changelog files (`CHANGELOG.md`, `changelog.json`) and the `README.md` documentation.
*   Refine core UI components and design tokens (`lib/core/design_tokens.dart`, `lib/core/shared_ui.dart`) to support the new design language.

> **Why refactoring matters**
> The internal changes, dependency updates, and build configuration adjustments in this release are crucial for the long-term health of Untis+. By keeping our codebase modern and dependencies up-to-date, we ensure better performance, enhanced security, and a more stable foundation. This also makes it easier for us to introduce exciting new features and maintain the app efficiently in the future.
