# MacOSTest v1.2.1 – Start hier

1. Öffne `Project/MacOSTest.dproj` in Delphi 13.1 Professional.
2. Für **macOS Intel x64** ist `OSX64` vorausgewählt. Für das Deployment das passende SDK und PAServer-Profil auswählen.
3. Für **Windows x64** in der Projektverwaltung `Win64` und `Release` auswählen. Alternativ in der RAD-Studio-Eingabeaufforderung `Project\Build_Win64.cmd` ausführen.
4. Beim ersten Start erstellt die Anwendung die SQLite-Datenbank und das Protokoll im Benutzerverzeichnis.

Die Win64-EXE enthält das About-JPEG und die statisch eingebundene SQLite-Engine. Die SQLite-Datei im Ordner Data ist eine Beispieldatenbank. Weitere Hinweise stehen in Docs/Icons_Deployment.md.
