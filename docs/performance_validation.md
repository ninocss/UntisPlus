# Validierung der Experience-Überarbeitung

Stand: 6. Oktober 2026. Lokaler Windows-Arbeitsbaum; vorhandene Änderungen an
Tageskontext, Lehrersuche und Repository-Daten wurden bei der Umsetzung bewahrt.

## Nachweise

- Der vollständige Windows-Testwrapper hat im abschließenden Lauf alle 208 Tests
  bestanden. Produktionsabhängigkeiten und Lockfile wurden danach wiederhergestellt.
- `flutter analyze --no-pub` meldet keine Probleme. Web- und Android-Debug-Build
  wurden erfolgreich erstellt.
  Der Android-Build warnt bei `home_widget` und `workmanager_android` vor deren
  bisheriger Kotlin-Gradle-Anbindung in künftigen Flutter-Versionen; die aktuelle
  Kompilierung ist erfolgreich. Eine spätere Plugin-Migration ist separat zu prüfen.
- Die lokale Web-Demo wurde nach dem Onboarding bei 1280 × 720 und 390 × 844
  geprüft: Tages-/Wochenansicht, Menü, Erscheinungsbild, Profilwechsel und
  Interaktionsschalter. Während dieser Prüfung wurden keine Browser-Konsolenfehler
  oder -warnungen aufgezeichnet. Das ist eine gezielte Demo-Prüfung, keine vollständige
  Live-WebUntis- oder native Funktionsabnahme.
- Profilauflösung/Migration, unveränderte Einzelpräferenzen, LRU-Verdrängung,
  leere Cache-Ergebnisse, Anfragenzusammenfassung, Generationen und
  Überlappungsaufbereitung haben gezielte Tests.
- Lebenszyklus, verdeckte Routen, Scroll-Pausen, deaktivierte Haptik, stabile
  Carousel-Kinder und begrenzter Aufbau langer Listen werden als Widgets geprüft.
- Ein separater Offline-Test lädt sämtliche 24 Schriftvarianten bei deaktiviertem
  Runtime-Fetching. Dadurch werden korrekte Dateinamen und Asset-Einbindung geprüft.
- Die zusätzlichen Layouttests prüfen die Profilwahl und alle Themes auf einem
  360-Pixel-Viewport mit 1,6-facher Schrift.

## Gerätegrenzen

`flutter devices` meldete Windows, Chrome und Edge, aber kein Android-/iOS-Gerät.
Es liegen keine physischen Vorher-/Nachher-Aufzeichnungen, GPU-Speichermessungen,
Akkumessungen oder 60-/120-Hz-Abnahmen vor. Der neue native Profiling-Einstieg und
die reproduzierbare Szenariofolge sind vorbereitet; Gerätewerte bleiben offen.

| Kennzahl | Vorher | Nachher | Status |
| --- | --- | --- | --- |
| Start bis erster Rasterframe | nicht gemessen | nicht gemessen | Gerätelauf erforderlich |
| Drag: UI p95 / Raster p95 bei 60 Hz | nicht gemessen | nicht gemessen | Gerätelauf erforderlich |
| Drag: UI p95 / Raster p95 bei 120 Hz | nicht gemessen | nicht gemessen | passendes Display erforderlich |
| Speicher nach wiederholten Wochen-/Tabwechseln | nicht gemessen | nicht gemessen | RSS + Heap/GPU-Abnahme erforderlich |
| Hintergrund, Sensoren, native Dienste, Haptik | nicht gemessen | nicht gemessen | native Funktionsabnahme erforderlich |

Widget-Rebuild-Tests belegen die lokale Aufbaugrenze des Carousels, keine Bildrate.
Ein erfolgreicher Web-/Android-Build belegt Kompilierung, keine Geräteleistung oder
Installation. Die Windows-Suite verwendet den bestehenden Fllama-Teststub.
