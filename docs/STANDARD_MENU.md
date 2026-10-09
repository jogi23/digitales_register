# Standard-Menü der Wertwerk-Apps

Gemeinsame Vorlage für alle Wertwerk-Apps (BiboNest, DigiReg ST, YT-Transkript-Downloader). Aktueller Stand von **DigiReg ST** siehe unten.

## Menüaufbau

Reihenfolge = Ziel-Reihenfolge, Gruppen durch Trennlinien getrennt.

### 1. App-Inhalt
- Hauptseiten der App (Übersicht, Suche, Verlauf …)

### 2. Einstellungen
- **Einstellungen**
  - Sprache: System, DE, EN, IT
  - Design: System, Hell, Dunkel
  - Benachrichtigungen (falls vorhanden)
  - Backup und Wiederherstellen (falls die App Daten speichert)
  - Diagnose / Absturzberichte: Opt-in-Schalter, standardmäßig aus

### 3. Hilfe und Feedback
- **Hilfe / FAQ**: in der App lesbar (offline), plus Link zur Online-FAQ
- **Kontakt**: E-Mail, Version im Betreff vorausgefüllt
- **Funktion vorschlagen**: Tally-Link
- **Fehler melden**: Tally-Link
- Alle Tally-Links mit `?app=<id>`, damit Rückmeldungen zuordenbar sind

### 4. Verbreitung
- **Neuigkeiten**: Changelog als eigener Menüpunkt
- **Bewerten**: erst sichtbar, wenn die App im Store ist
- **App weiterempfehlen**: teilen, mit Store-Link sobald vorhanden
- **Andere Apps von Wertwerk**: Icon, Kurztext, Store-Link aus gemeinsamer Quelle

### 5. Über
- **Über die App** (eigene Seite, kein Dialog):
  - Icon, Name, Version-Pill
  - Unabhängigkeitshinweis (falls die App einen Drittdienst nutzt)
  - Entwickler und Website
  - Quellcode / GPL (falls Open Source)
  - Open-Source-Lizenzen (`showLicensePage`)
  - Copyright-Zeile
- **Rechtliches** (Unterabschnitt der Über-Seite):
  - Datenschutz: Kurztext in der App plus Link zur Online-Erklärung
  - Impressum (DE/AT)
  - Nutzungsbedingungen

### 6. Konto (nur Apps mit Login)
- **Abmelden**: letzter Punkt, Trennlinie davor

## Regeln
- **Links zentral:** URLs, E-Mail und Entwicklername nur in `AppLinks`, nie im UI-Code.
- **Gemeinsame Texte:** Rechtstexte und die Liste der anderen Apps liegen auf `wertwerk.io` und werden verlinkt oder geladen, nicht pro App gepflegt.
- **Bedingte Einträge:** Backup, Benachrichtigungen, Abmelden und Quellcode nur, wenn die App sie braucht. Alles andere ist Pflicht.
- **Einheitliche Zeile:** Icon links, Titel, Pfeil (öffnet in der App) oder Extern-Symbol (öffnet im Browser) rechts.

## Stand in DigiReg ST

| Eintrag | Stand |
|---|---|
| Einstellungen / Sprache / Design | vorhanden |
| Diagnose-Schalter | vorhanden („Diagnose-Protokoll“ mit Teilen), [#325](https://github.com/jogi23/digitales_register/issues/325) |
| Hilfe/FAQ in der App | vorhanden, [#326](https://github.com/jogi23/digitales_register/issues/326) |
| Kontakt, Vorschlag, Fehler | vorhanden |
| Neuigkeiten | eigener Menüpunkt, [#323](https://github.com/jogi23/digitales_register/issues/323) |
| Bewerten | vorhanden |
| Teilen | vorhanden |
| Andere Apps | Menüpunkt zur Entwicklerseite im Play Store, [#329](https://github.com/jogi23/digitales_register/issues/329) |
| Über-Seite | eigene Seite, [#324](https://github.com/jogi23/digitales_register/issues/324) |
| Impressum / Nutzungsbedingungen | verlinkt aus „Rechtliches“, [#327](https://github.com/jogi23/digitales_register/issues/327) |
| Links zentral (`AppLinks`) | vorhanden, [#328](https://github.com/jogi23/digitales_register/issues/328) |
| Abmelden | vorhanden |
