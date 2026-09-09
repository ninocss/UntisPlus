# Material 3 Expressive: Schritt 1

Stand: 2026-09-09, Branch `material-3-expressive-preview`. Kein Commit erstellt.
Der Arbeitsbaum war zu Beginn sauber. Keine AGENTS.md im Repository oder in
seinen Elternverzeichnissen gefunden. `Zielbild-des-Plans.md` wurde berücksichtigt.
Eine während der Arbeit extern entstandene Änderung an
`lib/screens/main_navigation_screen.dart` bleibt erhalten.

## Implementierung

- Stabile AppFontId-Werte googleSansFlex, outfit, robotoFlex; app-weite
  Einstellung appFontFamily mit synchroner Notifier-Aktualisierung,
  Persistenz, Start-Laden und Restore-Synchronisierung. Fehlende/unbekannte
  Werte fallen auf Google Sans Flex zurück.
- Drei lokale variable Fonts samt OFL und LicenseRegistry; siehe
  `assets/fonts/README.md` und `axes.json` für Quellen, Hashes und echte Achsen.
  Kein Laufzeitdownload. Noch nicht migrierte GoogleFonts-Aufrufe erhalten
  lokale, hashgeprüfte Legacy-Assets. Schriftdateien insgesamt ca. 15 MB.
- Schriftwahl mit drei nativen RadioListTiles, Tastatur-/Semantik-Unterstützung
  und individuellen Vorschauen in DE/EN/FR/ES.
- Alle 15 TextTheme-Rollen und die ThemeData-Fontbasis verwenden die Auswahl.
  Die Default-Hierarchie betont Überschriften; variable Achsen werden zentral
  gesetzt. Andere Themes erhalten keine neuen Formen, Größen oder Motion-Regeln.
- Default-Fallback-Farbschema ist expressive; Android Dynamic Color bleibt
  vorrangig. AMOLED wird unverändert vom finalen Dark-Scheme abgeleitet.
- UntisThemeTokens.expressive ist nur für Default verfügbar, getrennt von
  Vivids bereits vorhandener supportsExpressiveComponents-Capability.
  Zentrale Form-, Aktionsgrößen- und Motion-Tokens inklusive Reduced Motion
  bereiten die folgenden Migrationsschritte vor.
- Zentrale Outfit-Aufrufe in Theme, Shared UI und Settings Hub migriert.
  Screen-spezifische direkte Aufrufe bleiben für die folgenden Schritte bestehen.

## Prüfung

`flutter analyze --no-pub`: letzter Lauf ohne Befunde. Die zuvor gemeldete
badgeCount-Warnung verschwand durch die separat eingegangene Navigationsänderung.
`git diff --check`: bestanden. Nur geänderte Dart-Dateien wurden formatiert;
unbeteiligte Formatter-Änderungen in main.dart wurden wieder entfernt.
Font-fvar-Tabellen direkt gelesen und alle 48 Legacy-Dateihashes verifiziert.

Neue Tests in `test/app_font_test.dart`: ID/Fallback, sofortiger Notifier-Wechsel,
Persistenz/Start-Laden, Backup-Roundtrip, 15 Textrollen für alle Themes und
Helligkeiten, expressive Fallback-Farben, Default-Gating, Light/Dark-App-Wechsel,
AMOLED, lokalisierte Schriftwahl mit 1.6-facher Textskalierung und echte Fontachsen.

Ausgeführt:

```text
flutter test --no-pub test/app_font_test.dart test/app_theme_test.dart test/widget_test.dart
```

Die Tests wurden vor ihrem Start durch den nativen fllama-Build blockiert:

```text
CMake Error at CMakeLists.txt:6 (project):
  Generator

    NMake Makefiles

  does not support platform specification, but platform

    x64

  was specified.

CMake Error: CMAKE_CXX_COMPILER not set, after EnableLanguage
Building native assets failed. See the logs for more details.
```

Der fllama-Hook übergibt `-A x64` an CMake 4.1.2, das `NMake Makefiles`
verwendet. Kein Widget-/Theme-Test-Erfolg und keine visuelle Geräteprüfung
werden behauptet. Laufzeitprüfung bleibt auf funktionierendem Toolchain-Setup nötig.
