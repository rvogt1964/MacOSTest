# Changelog

## 1.0.0 – 09.11.2026
- Projekt MacOSTest eingeführt, Projektstruktur für Delphi 13.1 Professional May Patch.
- MacOS Intel OSX64 als gewünschtes Primärziel; plattformneutraler FMX-Code.
- 2 Tabs mit Designer-Frames, einschließlich Über mich....
- 308 Artikel und je ein PNG-Illustrations-BLOB in SQLite.
- App-ID/CFBundleIdentifier `de.rvogt.macostest` hinterlegt.

## 1.1.0 – 10.11.2026
- 308 Artikelabbildungen in SQLite von PNG-BLOB auf JPEG-BLOB migriert.
- JPEG-Seed für neue Benutzer-Datenbanken und Migration alter Datenbanken.
- Herstellerunabhängige Icons für Windows, macOS, iOS, Android ergänzt.
- JPEG-Headerbild für den About-Frame ergänzt.
- SQL-Filterausdruck repariert.

## v1.1.1 – Textanzeige / Routinedokumentation

- FireDAC-Suchabfrage: Textspalten mit expliziten SQLite-Casts als `VARCHAR` ausgelesen, um Memo-Typinferenz in der Artikelliste zu vermeiden.
- `TCatalogFrame.RefreshArticles`: Listeneinträge bestehen aus Artikelnummer, Bezeichnung, Norm und Material als Text, nicht aus Feldobjektrepräsentationen.
- Erste Artikel-Detailanzeige wird bei jeder erfolgreichen Suche explizit aktualisiert.
- Deutsche Zweck-, Parameter- und Hinweisblöcke vor jeder implementierten Routine geprüft; doppelten/fehlplatzierten Block in `CatalogSeed.pas` bereinigt und `InitializeCatalog` dokumentiert.
- Datenbank unverändert übernommen (308 Artikel, 308 JPEG-BLOBs).

## v1.2.0 – Vollständiger Funktionslog

- Dritter Haupt-Tab **Log** zwischen Katalog und Über mich.
- Log-Frame mit Designer-FMX und Buttons Speichern, Löschen, Kopieren.
- Zentrale Logger-Unit `Source.AppLogger` mit Datum/Uhrzeit (Millisekunden), Kategorie und Meldung.
- Instrumentiert: App-Start/Ende, Datenbankverbindung, Migration/Initialisierung, SQL-Suche, Filter, Suchknopf, Artikelauswahl, BLOB-Laden, About-Bild, Navigation, Log-Aktionen und Exception-Behandlung.
- Auf Platte fortlaufend unter `Documents/MacOSTest/MacOSTest.log`; Löschen betrifft nur die aktuelle Anzeige.
- Bestehende `Memo`-Textkorrektur und deutsche Kommentare bleiben erhalten.

## v1.2.1 – Build, Bilddaten und Plattformkonfiguration

- Projektaufruf und Unit-Namen für Delphi 13.1 korrigiert. macOS Intel x64 ist das Standardziel.
- JPEG-Codec für Seed und Altbestandsmigration, transaktionale Datenbankinitialisierung und fehlertolerante Bildanzeige.
- Logger mit begrenztem Sitzungspuffer, Hauptthread-Anzeige, Logrotation und Schutz der Protokolldateien beim Export.
- About-JPEG als Programmressource eingebunden. Versionsanzeige, Bundle-ID und Icon-Zuordnungen aktualisiert.
