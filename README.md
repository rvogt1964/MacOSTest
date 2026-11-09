# MacOSTest 1.2.1

Plattformübergreifender FMX-Schraubenkatalog für Delphi 13.1 Professional (May Patch). In Delphi `Project/MacOSTest.dproj` öffnen. Standardziel ist **macOS Intel x64 (OSX64)**. Weitere Ziele sind über die Projektverwaltung auswählbar, sofern Toolchain, SDK und Lizenz eingerichtet sind.

- Drei Designer-Frames in der Reihenfolge **Schraubenkatalog**, **Log**, **Über mich...**.
- Artikelsuche, Kopfartfilter und Detailansicht mit schematischer Produktabbildung.
- 308 Demonstrationsartikel in `Data/MacOSTest.sqlite3`. Die Anwendung legt beim ersten Start eine eigene Datenbank im Benutzerverzeichnis an. Produktbilder liegen als JPEG in `articles.image_jpg`.
- Zentrales Sitzungsprotokoll mit Export und rotierenden Logdateien.
- App-ID und Apple-Bundle-ID `de.rvogt.macostest`. Hinweise zu den Zielplattformen stehen in `Docs/Icons_Deployment.md`.

Artikelnummern, Maße und Illustrationen dienen der Demonstration. Technische Herstellerangaben sind vor Konstruktion und Beschaffung separat zu prüfen.
