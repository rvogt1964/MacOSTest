# Bedienungsanleitung

Nach dem Start öffnet sich **Schraubenkatalog**. Im Suchfeld kann nach SKU, Norm, Gewinde und Beschreibung gesucht werden. Auswahl der Kopfart filtert Zylinderkopf bzw. Senkkopf. Klick auf einen Eintrag zeigt Abbildung und Metadaten. Im dritten Tab **Über mich...** stehen Version, Technik, Entwickler und Bundle-Identifier.

Die tatsächliche Datenbank liegt unter `TPath.GetDocumentsPath/MacOSTest/MacOSTest.sqlite3`, plattformabhängig im Benutzerverzeichnis. Sicherung: Anwendung schließen und die SQLite-Datei kopieren.

## Log

Im zweiten Tab **Log** werden Bedienhandlungen, Datenbankzugriffe und Fehler mit `TT.MM.JJJJ HH:NN:SS.ZZZ` angezeigt. **Speichern** exportiert die laufende Ansicht, **Kopieren** kopiert sie in die Zwischenablage, **Löschen** leert nur die aktuelle Ansicht. Das Langzeitprotokoll liegt unter `Documents/MacOSTest/MacOSTest.log`. Ab 5 MiB wird die bisherige Datei als `MacOSTest.log.1` abgelegt. Die Sitzungsanzeige hält bis zu 2000 Meldungen.
