# Standard-Menü und Benachrichtigungs-Diagnose (v1.6.0)

Issues: #323, #324, #325, #326, #327, #328, #329 (PR 1 „Menü-Standard“), #318, #319 (PR 2 „Benachrichtigungen“).
Vorlage: [docs/STANDARD_MENU.md](../../STANDARD_MENU.md), Referenz BiboNest (`lib/src/app_info.dart`, `ui/about_page.dart`, `ui/help_page.dart`).

## Ziel
DigiReg ST entspricht dem Wertwerk-Standardmenü. Nutzer können Benachrichtigungsprobleme selbst eingrenzen und dem Support per Screenshot zeigen.

## Festlegungen
- Sentry bleibt unverändert immer aktiv. Der Diagnose-Schalter (#325) steuert nur Netzwerkprotokoll und Debug-Log.
- „Andere Apps“ ist nur ein Menüpunkt, der die Wertwerk-Entwicklerseite im Play Store extern öffnet. Keine eigene Seite.
- Rechtstexte (Impressum, Nutzungsbedingungen, Datenschutz) liegen auf wertwerk.io und werden nur verlinkt.
- Alle neuen Texte in `app_de.arb`, `app_en.arb`, `app_it.arb`.

## PR 1: Menü-Standard

### 1. AppLinks (#328)
`lib/app_links.dart`, `abstract final class AppLinks` nach BiboNest-Muster:
`contactEmail`, `developerName`, `developer`, `faq`, `privacy`, `imprint`, `terms`, `otherApps`, `suggestFeature`, `reportBug` (beide Tally mit `?app=digiregst`), `source`, `playStore`, `feedbackMail(version)`.
Umstellen: `help_feedback_page.dart`, `app_about_dialog.dart` (entfällt), `settings_page_widget.dart` (Quellcode), `api_client.dart`, `services/app_sharing.dart` soweit URLs dort stehen.

### 2. Menü (#323, #329)
`sidebar.dart`, Reihenfolge: Inhalte, Einstellungen, Hilfe, Neuigkeiten, Bewerten, Teilen, Andere Apps, Über, Abmelden. Trennlinien an Gruppengrenzen.
- Neuigkeiten: Icon `new_releases_outlined`, öffnet `ChangelogPage`.
- Andere Apps: Icon `apps`, öffnet `AppLinks.otherApps` extern.

### 3. Über-Seite und Rechtliches (#324, #327)
`lib/ui/about_page.dart` ersetzt `showAppAboutDialog`: Icon, Name, Versions-Pill, Unabhängigkeitshinweis, Entwickler (Feichter, Debertol, Wachtler), Changelog, GPL/Quellcode, `showLicensePage`, Copyright.
Abschnitt „Rechtliches“: Datenschutz (Kurztext + Link), Impressum, Nutzungsbedingungen als Extern-Links. Zeilenstil einheitlich (Icon links, Extern-Symbol rechts).

### 4. Hilfe (#326)
`lib/ui/help_page.dart`: FAQ als `ExpansionTile`-Liste aus ARB (Anmeldung, Benachrichtigungen, Profil wechseln, Hausaufgaben, App-Sperre). Erster Eintrag in `HelpFeedbackPage`, Online-FAQ bleibt als Link.

### 5. Diagnose-Schalter (#325)
- Provider `diagnosticsEnabledProvider`, gespeichert in SharedPreferences, Standard aus.
- Der gespeicherte Wert wird vor `DebugLog.init` gelesen (Muster `storedAppLockEnabled`).
- `DebugLog.add/init` und die Protokollierung des Netzwerkprotokolls prüfen den Schalter statt `kDebugMode`. In Debug-Builds bleibt die Aufzeichnung immer an.
- Ausschalten löscht Debug-Log-Datei und Netzwerkprotokoll.
- Einstellungen, Abschnitt „Erweitert“: Schalter „Diagnose“ mit erklärendem Untertitel. „Netzwerkprotokoll“ und „Debug-Log“ erscheinen nur bei „an“, auch im Release.
- Datenschutztext (online + Kurztext) nennt, was lokal aufgezeichnet wird und dass nichts automatisch gesendet wird.

### Tests PR 1
`AppLinks` (URLs, Tally-Parameter, Mailbetreff), Sidebar (Einträge, Reihenfolge, Callbacks), `AboutPage` (Abschnitte, Link-Aufrufe), `HelpPage` (Auf-/Zuklappen), Diagnose (Provider-Persistenz, Gating von `DebugLog`, Sichtbarkeit der Einträge, Löschen beim Ausschalten). Widget-Tests für alle UI-Änderungen, Coverage ≥ 80 % auf geändertem Code.

## PR 2: Benachrichtigungen

### 6. Akku-Optimierung (#318)
- MethodChannel `battery_optimization` (Muster `app_lock_platform.dart`) mit `isIgnoring` und `openSettings`.
- Öffnet `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`, ohne `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (Play-Richtlinie).
- Hinweiskarte in den Benachrichtigungs-Einstellungen, wenn nicht ausgenommen. Zusätzlich beim Einschalten der Benachrichtigungen (neben `_askPermission`). Neuprüfung bei `AppLifecycleState.resumed`.
- Nur Android; sonst Karte ausgeblendet.

### 7. Hintergrund-Status (#319)
- `checkForNewNotifications` schreibt die letzte Runde in SharedPreferences: Zeitpunkt, je Konto (Alias) ein Ergebnis `ok(n)`, `nichtErreicht`, `übersprungenAppAngemeldet`, `ersterLauf`, `fehlgeschlagen`. Keine Passwörter, keine Mitteilungstexte.
- Einstellungen zeigen Zeitpunkt, Ergebnis je Konto, Systemberechtigung, geplant ja/nein und „Jetzt prüfen“ (`runBackgroundCheckNow`), auch im Release.
- Lesen mit `reload()`, da der Job in einem eigenen Isolate schreibt.

### Tests PR 2
Status-Serialisierung und -Schreiben je Ergebnisfall, Hinweiskarte bei ausgenommen/nicht ausgenommen (Channel gemockt), Neuprüfung nach Resume, Statusanzeige. Auf dem Gerät: Akku-Seite öffnet, Status nach Hintergrundlauf sichtbar.

## Nicht im Umfang
Remote-Quelle für Rechtstexte oder andere Apps, Änderungen an Sentry, #312, #265, #258, #152.

## Voraussetzung außerhalb der App
`wertwerk.io/impressum` und `wertwerk.io/nutzungsbedingungen/digiregst` müssen live sein, bevor 1.6.0 veröffentlicht wird.
