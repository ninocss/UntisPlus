# Version v4.2.0

This release introduces a convenient new way to view updates directly within the app, alongside a refreshed design and smoother animations. We've also improved how events and holidays are handled, making your schedule even clearer. Under the hood, significant technical improvements ensure a more stable and performant experience.

## What's New
*   Access an in-app changelog viewer directly from the settings, allowing you to easily see what's new in each update.

## Improvements
*   Enhanced the handling of events and holidays, likely leading to more accurate or comprehensive display within the app.
*   Refined the overall app design and theming for a fresh, modern look and feel. ✨
*   Updated app icons, providing new visual options or a refreshed appearance.
*   Improved animations, particularly within the onboarding flow, for a smoother and more engaging user experience.
*   Optimized internal caching mechanisms, which may lead to faster data loading and improved overall performance.

## Fixes
*   No explicit bug fixes were identified in this release.

## Technical Notes
*   Updated the project's `README.md` documentation.
*   Refactored internal class management, particularly around application state and main initialization, to improve code organization and maintainability.
*   Updated various dependencies and build configurations for Android, including `build.gradle.kts` and `AndroidManifest.xml`.
*   Updated localization files (`l10n.dart`), likely adding new strings or refining existing translations.
*   Adjusted the background service configuration, potentially improving its reliability or efficiency.
*   Implemented and refined GitHub Actions workflows for automated changelog generation and Dart build processes.
*   Performed multiple automated updates to the internal `changelog.json` file.

> **Why refactoring matters**
> This release includes several internal code improvements and refactorings, such as better class management and optimized caching. These changes are crucial for the long-term health of Untis+. They make the codebase easier to understand and maintain, which means we can develop new features faster and fix issues more efficiently in the future. Ultimately, this leads to a more stable, performant, and feature-rich app for you.
