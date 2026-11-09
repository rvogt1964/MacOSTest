# Technische Hinweise

## Aufbau

Das Hauptformular und die drei eingebetteten Frames befinden sich unter Forms und Frames. Unter Source liegen der FireDAC-Datenbankdienst, der Seed für die Demonstrationsartikel, das Artikelmodell und der zentrale Logger.

## Datenhaltung

Die aktive Datenbank liegt unter `TPath.GetDocumentsPath/MacOSTest/MacOSTest.sqlite3`. Die beigefügte Beispieldatenbank dient als Prüfmuster. Die Anwendung erzeugt bei Bedarf 308 eigene Demonstrationsartikel. Schema, Seed und JPEG-Migration werden in einer SQLite-Transaktion ausgeführt. Vorhandene PNG-BLOBs bleiben erhalten. Undekodierbare Altbilder werden protokolliert und bei einem späteren Start erneut berücksichtigt. `PRAGMA user_version` kennzeichnet die JPEG-Schemastufe mit dem Wert 1.

Die Artikelsuche verwendet SQL-Parameter. Textfelder werden als VARCHAR abgefragt und über AsString in normale Listenzeilen übernommen. Produkt-JPEGs werden erst für den ausgewählten Artikel aus dem BLOB gelesen.

## Protokoll

AppLogger speichert die aktuelle Sitzung in einem begrenzten Puffer. Der Log-Frame liest den Puffer im FMX-Hauptthread. Die laufende Datei rotiert ab 5 MiB. Die vorherige Datei erhält die Endung .1. Das Löschen der Anzeige leert den Sitzungspuffer und protokolliert die Aktion.

## Zielplattform

OSX64 ist Standard. Verfügbare weitere Ziele hängen von der Delphi-Installation, Lizenz und SDK-Konfiguration ab. Hinweise zu Ressourcen und Paketprüfung stehen in Icons_Deployment.md.
