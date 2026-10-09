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
Ein Menüpunkt „Hilfe und Feedback“, der eine Seite öffnet (kein aufklappbarer Bereich: die eingeklappte Leiste zeigt nur Symbole und kann keine Gruppen darstellen). Zeilen der Seite:
- **Hilfe / FAQ**: in der App lesbar (offline), Pfeil; am Ende der FAQ ein Link zur Online-FAQ
- **E-Mail schreiben**: Untertitel mit der Adresse, Version im Betreff vorausgefüllt
- **Funktion vorschlagen**: Tally-Link, Extern-Symbol
- **Fehler melden**: Tally-Link, Extern-Symbol
- Alle Tally-Links mit `?app=<id>`, damit Rückmeldungen zuordenbar sind

### 4. Über
Ein Menüpunkt „Über“, der eine Seite öffnet. Zeilen der Seite:
- **Bewerten**: Store-Link, immer sichtbar, sobald die App im Store ist
- **App weiterempfehlen**: teilen, mit Store-Link
- **Andere Apps von Wertwerk**: Untertitel, Extern-Symbol, Link zur Entwicklerseite im Store
- **Über die App**: Untertitel mit Version, Pfeil, öffnet die eigene Über-Seite:
  - Icon, Name, Version-Pill
  - Unabhängigkeitshinweis (falls die App einen Drittdienst nutzt)
  - Entwickler und Website
  - Neuigkeiten (Changelog)
  - Quellcode / GPL (falls Open Source)
  - Open-Source-Lizenzen (`showLicensePage`)
  - Copyright-Zeile
  - **Rechtliches** (Unterabschnitt): Datenschutz (Kurztext plus Link), Impressum (DE/AT), Nutzungsbedingungen

### 5. Konto (nur Apps mit Login)
- **Abmelden**: letzter Punkt, Trennlinie davor

## Regeln
- **Links zentral:** URLs, E-Mail und Entwicklername nur in `AppLinks`, nie im UI-Code.
- **Gemeinsame Texte:** Rechtstexte und die Liste der anderen Apps liegen auf `wertwerk.io` und werden verlinkt oder geladen, nicht pro App gepflegt.
- **Bedingte Einträge:** Backup, Benachrichtigungen, Abmelden und Quellcode nur, wenn die App sie braucht. Alles andere ist Pflicht.
- **Einheitliche Zeile:** Icon links (`*_rounded`), Titel, Pfeil (öffnet in der App) oder Extern-Symbol (öffnet im Browser) rechts; mindestens 48 dp hoch.
- **Menü-Symbole:** ein Symbolsatz (`*_rounded`), jedes Symbol nur einmal, damit die eingeklappte Leiste ohne Text lesbar bleibt.

## Stand in DigiReg ST

| Eintrag | Stand |
|---|---|
| Einstellungen / Sprache / Design | vorhanden |
| Diagnose-Schalter | vorhanden („Diagnose-Protokoll“ mit Teilen), [#325](https://github.com/jogi23/digitales_register/issues/325) |
| Hilfe/FAQ in der App | vorhanden, [#326](https://github.com/jogi23/digitales_register/issues/326) |
| Kontakt, Vorschlag, Fehler | Zeilen der Seite „Hilfe und Feedback“, [#335](https://github.com/jogi23/digitales_register/issues/335) |
| Neuigkeiten | in der Über-Seite statt im Menü, [#323](https://github.com/jogi23/digitales_register/issues/323) |
| Bewerten, Teilen, Andere Apps | Zeilen der Seite „Über“, [#329](https://github.com/jogi23/digitales_register/issues/329), [#335](https://github.com/jogi23/digitales_register/issues/335) |
| Über-Seite | eigene Seite, [#324](https://github.com/jogi23/digitales_register/issues/324) |
| Impressum / Nutzungsbedingungen | verlinkt aus „Rechtliches“, [#327](https://github.com/jogi23/digitales_register/issues/327) |
| Links zentral (`AppLinks`) | vorhanden, [#328](https://github.com/jogi23/digitales_register/issues/328) |
| Abmelden | vorhanden |
