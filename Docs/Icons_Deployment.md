# Programm-Icons und Deployment – MacOSTest 1.2.1

- **Windows** verwendet `Resources/Icons/MacOSTest.ico` über Icon_MainIcon.
- **macOS** verwendet für Intel und Apple Silicon `MacOSTest.icns` über Icns_MainIcns. Die Bundle-ID steht in den Apple-Versionsschlüsseln. Bei der Paketprüfung Info.plist und Contents/Resources im erzeugten Bundle kontrollieren.
- **iOS** verwendet die in den Projektoptionen zugeordneten PNG-Größen aus AppIcon.appiconset. Der vollständige Katalog einschließlich Marketing-Icon liegt als Ressource bei. Die finale Asset- und Signaturkonfiguration im iOS-Build prüfen.
- **Android** verwendet die zugeordneten Launcher-PNGs aus den Mipmap-Ordnern und die Paket-ID de.rvogt.macostest. Die fertigen Manifest- und Icon-Ressourcen im Android-Paket prüfen.

About_MacOSTest.jpg wird über About_MacOSTest.res als RCDATA mit ID 101 eingebunden. Bei einem Bildaustausch müssen JPEG und RES aktualisiert werden. Das designerbasierte TImage lädt die Ressource beim Start.

Für macOS-Builds und Deployment werden je nach Arbeitsablauf das passende SDK und ein konfiguriertes PAServer-Profil benötigt.
