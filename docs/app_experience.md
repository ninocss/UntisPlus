# Untis+ – Performance, Bewegung und Expressive UI

## Bedienung und Migration

Unter **Einstellungen → Erscheinungsbild → Animationen & Effekte** stehen drei
manuelle Qualitätsprofile zur Verfügung. Es gibt keine automatische Anpassung.
Animationen der Bedienoberfläche und haptisches Feedback lassen sich separat
ausschalten. Die Systemoption für reduzierte Bewegung hat Vorrang.

| Verhalten | Vollständig | Ausgewogen | Reduziert |
| --- | --- | --- | --- |
| Unschärfe an Navigation und App-Bar | persönlicher Wert | maximal Sigma 12 | aus |
| Unschärfe an Karten, Unterricht und Seitenwechseln | persönlicher Wert | aus | aus |
| Glow und Gyroskop | persönliche Einstellung | aus | aus |
| Hintergrundbewegung | persönliche Einstellung | pausiert beim Scrollen | statisch |
| Bedienanimationen | gemeinsame Motion-Tokens | gemeinsame Motion-Tokens | maximal 180 ms, gedämpfte Feder |
| Haptik | eigener Schalter | eigener Schalter | eigener Schalter |

Ein unkonfigurierter Erststart erhält „Ausgewogen“. Installationen mit vorhandenen
Einstellungen erhalten bei der einmaligen Migration „Vollständig“, um ihre
bisherige Darstellung zu bewahren. `effectQualityV1` speichert die bewusste Wahl.
Ungültige Profilwerte fallen auf „Ausgewogen“ zurück. Die neuen Schalter heißen
`interactionAnimationsEnabledV1` und `hapticsEnabledV1`.

Die Profile überschreiben weder Blur-Stärke, Kartenstil und Opazität noch
Gyroskop-, Glow- oder Hintergrundpräferenzen. Zurückschalten auf „Vollständig“
aktiviert diese Werte wieder. Bei deaktivierter Unschärfe in den sparsameren
Profilen werden Kartenfarben auf eine deckende Tonfläche gerechnet. Manga,
Glass und Cyber behalten Formen, Farben und ihre eigenen Typografierollen.

## Architektur und Daten

- `core/app_experience.dart` löst die wirksamen Effekte ohne Änderungen an den
  gespeicherten Einzelwerten auf. Motion-Tokens bündeln 120/180/240-ms-Effekte
  und drei Federkonfigurationen.
- `AppExperienceScope` beobachtet Lebenszyklus und Scroll-Aktivität.
  `AppRouteActivity` pausiert Tickern auf überdeckten Routen. Nach Scroll-Ende
  werden ausgewogene Hintergründe nach 160 ms wieder zugelassen.
- `TimetableController` hält sichtbare Woche, Datum, Lade-, Cache- und Fehlerstatus
  getrennt. Identische Ladevorgänge teilen sich ein Future. Jede neue Anfrage
  erhält eine Generation; der Screen prüft zusätzlich Konto, Person und Datum.
  Ein Authentifizierungsversuch wird innerhalb der geteilten Operation einmal
  wiederholt, damit er nicht auf sein eigenes Future wartet.
- Der Wochen-Arbeitsspeicher verwendet maximal fünf LRU-Einträge. Diese Grenze
  löscht keine persistenten Wochen. Leere Wochen sind gültige Ergebnisse.
  Ladefehler lassen bereits verfügbare Daten und ihre Cache-Kennzeichnung stehen.
- `domain/timetable_presentation.dart` berechnet überlappende Unterrichtsblöcke
  unabhängig von Flutter. Nichtpositive Intervalle werden verworfen; ein fehlendes
  Ende erhält 45 Minuten, auch über eine Stundengrenze hinweg.
- Bis zu 20 vorbereitete Tage werden wiederverwendet. Änderungen an ausgeblendeten
  Fächern, Ausfällen, Präsentation oder Unterrichtsdaten verwerfen diese Ableitung.
  Die Rohdaten und das bestehende Offline-Format bleiben erhalten.
- `TimetableCarousel` erhält stabile Seiten-Widgets. Beim Ziehen aktualisiert ein
  lokaler `ValueNotifier` nur Transformationen und Opazität. Es sind die aktuelle
  Seite und höchstens eine eintretende Seite gemountet. Ein Gestenabbruch setzt
  die Bewegung zurück; eine deaktivierte Bewegung beendet laufende Übergänge.
- Haupttabs entstehen beim ersten Besuch. Besuchte Tabs behalten ihren Zustand;
  inaktive Tabs erhalten `TickerMode`, ausgeschlossene Semantik und bei animierten
  Übergängen nach dem Ausblenden `Offstage`. Kontoabhängige Tabs haben Kontoschlüssel.
- Aufgaben-, Prüfungs-, Noten- und Chatlisten erzeugen Karten im sichtbaren Bereich.
  Notengruppen und Lehrerstundenpläne werden vorbereitet. Der Lehrer-Wochencache ist
  ebenfalls begrenzt; Suchtext baut nur den Ergebnisbereich neu auf.
- KI-Streaming aktualisiert die letzte Nachricht separat und sendet keine Haptik
  pro Textfragment. Autoscroll endet bei eigener Scroll-Bewegung nach oben; ein
  Knopf springt zur neuesten Nachricht und aktiviert das Folgen wieder.

Der Stundenplan-Screen ist noch für mehrere UI- und Repository-Aufgaben zuständig.
Die neue Controller- und Präsentationsgrenze reduziert den Umbauumfang und bewahrt
bestehende Tagesübersicht, Klassenwechsel, Exporte, Details, Alarme und Offline-Flows.

## Expressive Darstellung und Bewegung

Die Standarddarstellung nutzt gemeinsame Typografierollen mit lesbarer
Körpertypografie, kräftigen Titeln und funktionaler Größenhierarchie. Die vorhandenen
Expressive-Komponenten für Buttons, Slider, Fortschritt, Sheets und Navigation
verwenden die gemeinsamen Bewegungsregeln. Der Tagesüberblick bietet direkte
Auswahlchips für Tag, drei Tage und Woche; die bestehende Umschaltaktion bleibt
verfügbar. Einzelunterricht bleibt ausführlich, Mehrtagesansichten kompakt.
Die primären Onboarding-Aktionen verwenden die passende `onPrimary`-Textfarbe,
damit die Schrift auf gefüllten Buttons auch im hellen Theme lesbar bleibt.

Seiten- und Menübewegungen berücksichtigen die Nutzerpräferenz, Systemzugänglichkeit,
`TickerMode` und App-Aktivität. Navigationsfedern übernehmen beim erneuten Zielwechsel
die aktuelle Geschwindigkeit. Die sparsame Variante dämpft stärker. Slider bestätigen
den Beginn und bei diskreten Werten tatsächliche Schrittwechsel, mit mindestens
60 ms Abstand; kontinuierliche Slider bestätigen auch das Loslassen.

Die Hintergrundstile Linien, Nebel, Prisma, Wellen, Raster und Ringe zeichnen direkt
aus dem Animationsticker neu. Sie bauen keinen Widget-Baum pro Frame auf. Weitere
Stile mit zusammengesetzten Widgets behalten ihre Darstellung und ihre eigenen
Animationen; die Profil- und Lebenszyklusregeln gelten auch dort. Hintergrund- und
Unterrichtsbereiche sind durch gezielte `RepaintBoundary`-Grenzen getrennt.

## Start und Offline-Schriften

Locale, angemeldetes Konto und sichtbare Darstellungspräferenzen werden vor dem
ersten Bild geladen. Optionale KI-Schlüsselmigration und GGUF-Prüfung sowie native
Zusatzdienste und Änderungsmetadaten starten nach dem ersten Frame. KI-Aufrufe und
Konfigurationsseiten warten auf die gemeinsame Initialisierung. Ein fehlgeschlagener
Initialisierungsvorgang wird nicht als erfolgreiche Konfiguration behandelt.

Outfit, Bebas Neue und IBM Plex Mono liegen mit insgesamt 24 Varianten lokal unter
`assets/fonts/`. Die Dateien entsprechen den SHA-256-Prüfsummen der gebundenen
`google_fonts`-Version; `manifest.json` hält Dateiname, Größe und Hash fest.
Die Varianten tragen die vom Paket erwarteten Namen wie `Outfit-Bold.ttf`.
Laufzeitabrufe sind beim App-Start abgeschaltet. OFL-Lizenzen sind eingebunden und
im Lizenzdialog registriert. Die reinen Schriftdateien benötigen etwa 1,59 MB.

## Validierung unter Windows

```powershell
pwsh -NoProfile -File tool/test_without_local_ai.ps1
flutter analyze --no-pub
flutter build web --no-pub --no-wasm-dry-run
git diff --check
```

Der Testwrapper tauscht die native Fllama-Bibliothek nur für Dart-/Widgettests aus
und stellt danach Produktionsabhängigkeiten und Lockfile wieder her. Dadurch sind
lokale Llama-Ausführung, native Grafik, Sensoren, Benachrichtigungen und Gerätehaptik
nicht durch diesen Testlauf bewiesen. Offline-Fonttests schalten Netzwerkabrufe
explizit aus. Die UI-Prüfungen decken alle vier Themes, drei Profile, größere Schrift,
Handy-/Tabletbreiten, Navigation und Stundenplananimationen ab.

## Reproduzierbarer Android-Profillauf

Auf einem physischen Android-Gerät jeweils einen separaten Lauf pro Profil durchführen:

```powershell
flutter run --profile -d <device-id> -t tool/profile_app.dart --dart-define=PROFILE_QUALITY=balanced --dart-define=PROFILE_SECONDS=90 --dart-define=PROFILE_DEVICE_LABEL=<device-name>
```

`PROFILE_QUALITY` akzeptiert `full`, `balanced` und `reduced`. Das Werkzeug setzt das
Profil nur im Arbeitsspeicher, schreibt keine persönliche Einstellung und protokolliert
keine Schuldaten oder Zugangsschlüssel. Nach dem ersten gerasterten Frame folgen
zehn Sekunden Aufwärmphase, dann standardmäßig 90 Sekunden Erfassung. Am Ende
erscheint `UNTIS_PROFILE_REPORT <path>`; dort liegt die JSON-Datei im Dokumentordner
der App. Im Debug-/Web-Modus lehnt das Werkzeug eine Performance-Erfassung ab.

Für vergleichbare Läufe identische Demo-Daten, Theme, Lichtmodus, Anzeigegröße,
Bildwiederholrate, Hintergrundstil und Einzelpräferenzen verwenden. Vor jeder Messung
denselben Zustand herstellen und das Gerät abkühlen lassen. Dreimal wiederholen:

| Zeit seit `UNTIS_PROFILE_START` | Interaktion |
| --- | --- |
| 0–20 s | Tagesansicht: fünf Tage vor/zurück, schnelle Umkehrgesten und Abbruch |
| 20–40 s | Drei-Tage-/Wochenansicht: mehrere Wochen vor/zurück, dann vertikal scrollen |
| 40–55 s | Aufgaben/Prüfungen/Noten: eine vorher festgelegte lange Liste scrollen |
| 55–70 s | Tabs mehrfach wechseln, Menü und Unterrichtsdetails öffnen/schließen |
| 70–80 s | Mit optionaler Test-KI streamen; hochscrollen und zur neuesten Nachricht springen |
| 80–90 s | App kurz überdecken/hintergrundieren, zurückkehren und Stundenplan scrollen |

KI-Streaming und Cache-/Offline-Aktualisierungen zusätzlich separat messen, weil
Server-/Dateiwartezeiten keine Grafikzeit darstellen. Demo-Daten allein beweisen
keine Live-WebUntis-Parität. Bei einer anderen Displayfrequenz nicht Werte für 120 Hz
aus einem 60-Hz-Lauf ableiten.

Der Bericht enthält UI-/Raster-p50/p95/p99, Rohframes, Anteil über dem tatsächlichen
Displaybudget, Start bis erstem Rasterframe und RSS-Speicherproben. UI- und Rasterzeiten
haben separate Budgets und werden nicht addiert. Leere Aufzeichnungen erhalten keine
erfundenen Perzentile oder Fehlerquote. RSS ist Prozessspeicher einschließlich nativer
Anteile und ersetzt weder Dart-Heap- noch GPU-/Energieanalysen. Bildaussetzer, Eingabelatenz,
Kalibrierung der Haptik und Akkulast sind zusätzliche Geräte-/DevTools-Prüfungen.

Das Ziel beträgt 16,67 ms bei 60 Hz beziehungsweise 8,33 ms bei 120 Hz pro UI-/Rasterphase.
Für regelmäßige Drags soll p95 innerhalb des Budgets liegen; die Quote überschrittener
Frames soll unter 1 % bleiben. Dies sind Abnahmeziele, keine bestätigten Messergebnisse.
Die Vorher-Version und die geänderte Version müssen unter denselben Bedingungen
gemessen werden. Der aktuelle Prüfstatus steht in `performance_validation.md`.
