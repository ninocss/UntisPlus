# Untis+ — Settings Redesign Plan (Material You Expressive)

Datum: 10.05.2026

## Ziele (was am Ende besser ist)
- Settings sind **klar in Kategorien** sortiert (je Kategorie eine eigene Seite).
- Navigation erfolgt über **Buttons** (Hub → Kategorie-Seite).
- UI ist konsistent in **Material 3 / Material You Expressive** (Tonals, Shapes, Typo, Motion).
- Neue Funktion: **„Alle App-Einstellungen exportieren/importieren“** (inkl. Klausuren + Custom Backgrounds + alle relevanten SharedPreferences).

## Ausgangslage (kurz, codebasiert)
- Der aktuelle Settings-Screen ist größtenteils in [lib/main.dart](../lib/main.dart) als `SettingsPage` implementiert (sehr lang, viele Sektionen).
- Es existiert zwar [lib/screens/settings_hub.dart](../lib/screens/settings_hub.dart), ist aber aktuell leer.
- Export/Import existiert bereits für:
  - **Klausuren**: `customExams` werden als JSON exportiert (Zwischenablage) und importiert (Scan/PDF/AI). Storage: SharedPreferences `customExams`.
  - **Custom Backgrounds**: Import/Export über Clipboard/File in [lib/screens/custom_background_editor_screen.dart](../lib/screens/custom_background_editor_screen.dart) und Persistenz in [lib/core/custom_backgrounds.dart](../lib/core/custom_backgrounds.dart) (Prefs `customBackgrounds` + `selectedCustomBackgroundId`).
- `backup_service.dart` existiert, ist aber leer → gute Stelle, um „All Settings Backup“ zentral zu implementieren.

## 1) Neue IA: Informationsarchitektur (Kategorien)

### 1.1 Settings Hub (neu)
**Neue Landing Page**: „Einstellungen“ zeigt **Kategorie-Buttons** und darunter optional „Zuletzt verwendet“.

**Layout (M3 Expressive, minimal):**
- Oben: `SliverAppBar`/`RoundedBlurAppBar` mit Titel.
- Darunter: Grid (2 Spalten) aus `FilledButton.tonalIcon` oder `Card` + `InkWell`.
- Jede Kategorie navigiert zu einer eigenen Seite.

**Kategorien (Vorschlag, passend zum aktuellen Funktionsumfang):**
1. **Stundenplan**
2. **Benachrichtigungen & Widgets**
3. **Design & Hintergrund**
4. **Fächer & Farben**
5. **KI-Assistent**
6. **Daten & Backup** (NEU: Export/Import All)
7. **Account & Demo**
8. **Updates & Über**

> Hinweis: „Klausuren“ selbst sind ein eigener Tab in der Bottom-Navigation. In Settings taucht deshalb nur **Klausur-Storage (Backup)** unter „Daten & Backup“ auf.

### 1.2 Kategorie-Seiten (neu)
Jede Kategorie ist eine **eigene Route** mit klarer, kurzer Liste.

**Prinzip:**
- Keine „Monster“-Seite mehr.
- Jede Seite hat 5–12 Items.
- Toggles bleiben sofort wirksam.
- Komplexe Editoren (z.B. Custom Backgrounds, AI Prompt) bleiben in ihren bestehenden Screens/Sheets.

#### A) Stundenplan
Inhalt:
- „Ausgefallene Stunden anzeigen“ (`showCancelled`)
- „Stundenplan jetzt aktualisieren“ (bestehende Action: `updateUntisData()`)
- Optional: Quicklink „Freie Räume / nächste Stunde“ nur, wenn es Settings dafür gibt (sonst weglassen).

#### B) Benachrichtigungen & Widgets
Inhalt:
- „Live Lesson Push“ (`progressivePush`)
- „Daily Briefing Push“ (`dailyBriefingPush`)
- „Wichtige Änderungen Push“ (`importantChangesPush`)

#### C) Design & Hintergrund
Inhalt:
- Theme Mode (`themeMode` SegmentedButton)
- Sprache (`appLocale`)
- Glass/Blur (`blurEnabled`)
- Background Animations (`backgroundAnimations`)
- Gyroscope (`backgroundGyroscope`)
- Background Style (`backgroundAnimationStyle`)
- Custom Backgrounds → Link zum bestehenden `CustomBackgroundEditorScreen`

#### D) Fächer & Farben
Inhalt:
- Fachfarben → `SubjectColorsPage`
- Ausgeblendete Fächer → `HiddenSubjectsPage`

#### E) KI-Assistent
Inhalt:
- Provider (`aiProvider`)
- Model (`aiModel`)
- (nur custom) Compatibility (`aiCustomCompatibility`)
- (nur custom) Base URL (`aiCustomBaseUrl`)
- API-Key (`geminiApiKey`/`openAiApiKey`/`mistralApiKey`/`customAiApiKey`)
- System Prompt (`aiSystemPromptTemplate`)
- Prompt Variables (Sheet)

#### F) Daten & Backup (NEU)
Inhalt:
- **Export All Settings** (Datei + optional Clipboard)
- **Import All Settings** (Datei + optional Clipboard)
- „Nur Design exportieren“ (optional, wenn gewünscht; sonst nicht)
- **Klausuren Export/Import Hinweis**: gehört ab jetzt hierher zusätzlich zu Exams-Tab (Exams-Tab darf bestehen bleiben, aber „All“ deckt es ab).

#### G) Account & Demo
Inhalt:
- Account-Karte (Username, Logout)
- Demo Mode (`demoMode`)

#### H) Updates & Über
Inhalt:
- GitHub Update Check
- Link Releases
- App Version/Build

## 2) Navigation/UX (Buttons → neue Page)

### 2.1 Routing
- Hub-Seite push’t Kategorie-Seiten via `Navigator.push`.
- Jede Kategorie-Seite ist ein eigener Widget-Screen unter `lib/screens/settings/`.

Empfohlene neue Dateien:
- `lib/screens/settings/settings_hub_page.dart`
- `lib/screens/settings/settings_timetable_page.dart`
- `lib/screens/settings/settings_notifications_page.dart`
- `lib/screens/settings/settings_appearance_page.dart`
- `lib/screens/settings/settings_subjects_page.dart`
- `lib/screens/settings/settings_ai_page.dart`
- `lib/screens/settings/settings_backup_page.dart`
- `lib/screens/settings/settings_account_page.dart`
- `lib/screens/settings/settings_about_updates_page.dart`

> Aktuell ist `lib/screens/settings/` leer – das passt perfekt.

### 2.2 „Buttons“ Design
- Hub: 2×N Grid Buttons.
- Pro Button:
  - Icon (M3 rounded)
  - Titel
  - 1 Subtitle-Zeile (z.B. „Theme, Sprache, Hintergrund“)

### 2.3 Konsistenz mit bestehendem Style
- Weiterhin `GoogleFonts.outfit` (bereits genutzt).
- Weiterhin `_AnimatedBackground` (wenn Performance ok) – aber **Tonals** statt harte Gradients.

## 3) Material You Expressive: Design-Regeln (konkret)

### 3.1 Komponenten
- Listen: `ListTile` + M3 `Switch`, `SegmentedButton`, `FilledButton.tonal`, `OutlinedButton`.
- Gruppierung: `Card.filled` (statt custom „Glass“ überall).
- Wichtig: gleiche Höhen (`minimumSize`), gleiche `shape` Radien aus `AppDesignTokens`.

### 3.2 Farb- & Tonal-Logik
- Nutze `ColorScheme.surfaceContainerLow/High/Highest` für Karten.
- Akzentfarbe nur für Icons/Badges, nicht als große Gradients.
- „Destructive“ Actions (Logout, Clear) mit `colorScheme.error`.

### 3.3 Typo
- Titel: 20–24, weight 800–900 (wie jetzt).
- Section Header: 12–13, weight 800, `onSurfaceVariant`.
- Body: 14–16.

### 3.4 Motion (Expressive)
- Kurze, federnde Übergänge (bestehende `_springEntry` Muster wiederverwenden).
- Hub Buttons: `InkResponse` + leichter Scale/Opacity.

## 4) Export/Import „ALLE SETTINGS“ (App-weit)

### 4.1 Was wird exportiert?
**Ziel:** Button exportiert ein JSON, das den kompletten Zustand für User-Settings wiederherstellt.

**SharedPreferences (relevant) – basierend auf vorhandenem Code:**
- UI/Locale/Theme: `appLocale`, `themeMode`, `blurEnabled`
- Timetable: `showCancelled`
- Background: `backgroundAnimations`, `backgroundAnimationStyle`, `backgroundGyroscope`
- Notifications: `progressivePush`, `dailyBriefingPush`, `importantChangesPush`
- Subjects: `hiddenSubjects` (StringList), `subjectColors` (JSON String)
- AI: `aiProvider`, `aiModel`, `aiCustomCompatibility`, `aiCustomBaseUrl`, `aiSystemPromptTemplate`, API-Keys
- Custom Background Library: `_kPrefsCustomBackgrounds` + `_kPrefsSelectedCustomBackgroundId` (aus `custom_backgrounds.dart`)
- Exams (Custom): `customExams` (StringList JSON)

**Nicht exportieren (Security/Privacy, default):**
- `password`, `sessionId`, Login-Credentials, Server auth cookies
- Alles, was als „Session“/Auth gilt

> Optional: Eine Checkbox „Login-Daten einbeziehen“ wäre möglich, aber nur nach expliziter Bestätigung. Default: AUS.

### 4.2 JSON Schema (versioniert)
Empfohlenes Format (stabil, updatefähig):
```json
{
  "schemaVersion": 1,
  "createdAt": "2026-05-10T12:00:00Z",
  "app": { "name": "Untis+", "version": "...", "build": "..." },
  "prefs": {
    "bool": { "showCancelled": true, "blurEnabled": true },
    "int": { "themeMode": 1, "backgroundAnimationStyle": 0 },
    "string": { "appLocale": "de", "aiProvider": "gemini" },
    "stringList": { "hiddenSubjects": ["..."], "customExams": ["{...}"] }
  }
}
```

Warum so?
- Typ-sicher (keine Dart-`dynamic` Überraschungen)
- Leicht migrierbar (`schemaVersion`)

### 4.3 Export Flow (UX)
- Button „Alle Einstellungen exportieren“ → Sheet mit Optionen:
  - Export als Datei (`FilePicker` save) **oder** Share/Clipboard (optional)
  - Toggle: „API Keys einschließen“ (Default: EIN oder AUS? Empfehlung: AUS, weil sensibel)
- Nach Export: SnackBar „Backup gespeichert“.

### 4.4 Import Flow (UX)
- Button „Alle Einstellungen importieren“ → Sheet:
  - „Aus Datei“ (FilePicker)
  - „Aus Zwischenablage“
- Validierung:
  - JSON parse
  - `schemaVersion` prüfen
  - Key-Typen prüfen
- Confirm Dialog:
  - Warnung: „Überschreibt Einstellungen, App startet ggf. neu“
- Apply:
  - SharedPreferences set…
  - Notifier synchronisieren (`themeModeNotifier`, `appLocaleNotifier`, etc.)
  - Custom backgrounds reload (`loadCustomBackgroundsFromPrefs`)

### 4.5 Implementierung (Code-Struktur)
Empfohlen:
- Neue Service-Klasse in `lib/services/backup_service.dart` (die Datei ist leer):
  - `Future<String> exportAllToJsonText({bool includeApiKeys = false})`
  - `Future<void> importAllFromJsonText(String json)`
  - Helper: `_readPrefsByWhitelist()` / `_applyPrefs()`

**Whitelist statt „prefs.getKeys()“**
- verhindert, dass zufällig Auth-Tokens, zukünftige Keys oder Debug-Flags im Backup landen.

### 4.6 Klausuren-Spezialfall
- `customExams` ist schon ein StringList (JSON pro Exam). Export/Import ist trivial.
- Der Exams-Tab darf seinen Export (Clipboard) behalten.
- „All Settings“ muss `customExams` **immer** enthalten (außer User schaltet „Klausuren einschließen“ aus).

## 5) Schritt-für-Schritt Umsetzung (konkret)

### Phase 1 — Refactor: Settings aus `main.dart` lösen
1. `SettingsPage` in eine neue Datei verschieben oder ersetzen durch `SettingsHubPage`.
2. Kategorie-Seiten als neue Widgets anlegen.
3. Bestehende Unterseiten (`SubjectColorsPage`, `HiddenSubjectsPage`, `CustomBackgroundEditorScreen`) weiterverwenden.

### Phase 2 — UX/Design auf M3 Expressive
1. Hub-Grid Buttons bauen.
2. Kategorie-Seiten mit `Card.filled` + `ListTile` bauen.
3. Einheitliche Radien (`AppDesignTokens`) nutzen.

### Phase 3 — All Settings Backup
1. `backup_service.dart` implementieren (Export/Import JSON).
2. Neue „Daten & Backup“-Seite mit 2 Primary Actions.
3. Tests/Smoke:
   - Export → clear prefs → Import → UI Zustand stimmt.

## 6) Abnahmekriterien (Definition of Done)
- Hub zeigt Kategorien als Buttons, Navigation funktioniert.
- Jede Kategorie hat eine eigene Seite mit passenden Settings.
- UI wirkt wie Material 3 Expressive (Tonals, Consistency, keine wild gemischten Styles).
- „Export All“ erzeugt JSON Datei.
- „Import All“ stellt Theme/Language/Notifications/Backgrounds/Hidden Subjects/Subject colors/AI + Custom Exams wieder her.
- Keine Credentials werden ohne explizite Zustimmung exportiert.

