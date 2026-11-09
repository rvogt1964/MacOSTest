# Dateiliste

- `Project/MacOSTest.dpr` – Programmstart.
- `Project/MacOSTest.dproj` – MSBuild-Projektgrundlage.
- `Forms/MainForm.pas/.fmx` – Hauptformular, 3 Tabs, eingebettete Frames.
- `Frames/CatalogFrame.pas/.fmx` – Katalog UI.
- `Frames/AboutFrame.pas/.fmx` – Über mich UI.
- `Source/CatalogDatabase.pas` – Datenbankdienst.
- `Source/CatalogSeed.pas` – Schema, Seeding, Produktgrafiken.
- `Source/CatalogModel.pas` – Datentransfer.
- `Data/MacOSTest.sqlite3` – befüllte Beispiel-DB.
- `Resources/Images/*.jpg` – JPEG-Bilder.
- `Docs/*.md` – Projektdokumentation.

- `Resources/Icons/`: Master, Windows .ico, macOS .icns + iconset, iOS AppIcon.appiconset, Android mipmap
- `Resources/Images/About_MacOSTest.jpg`: About-Header, eingebunden über die zugehörige RES-Datei
- `Docs/Icons_Deployment.md`: IDE- und Deployment-Anleitung

- `Frames/LogFrame.pas` / `.fmx`: Designerbasierter Protokolltab
- `Source/AppLogger.pas`: zentrale zeitgestempelte Protokollierung
