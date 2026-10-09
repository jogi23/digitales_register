# Standard-Menü und Benachrichtigungs-Diagnose (v1.6.0)

Issues: #323, #324, #325, #326, #327, #328, #329 (PR 1 „Menü-Standard“), #318, #319 (PR 2 „Benachrichtigungen“).
Vorlage: [docs/STANDARD_MENU.md](../../STANDARD_MENU.md), Referenz BiboNest (`lib/src/app_info.dart`, `ui/about_page.dart`, `ui/help_page.dart`).

## Ziel
DigiReg ST entspricht dem Wertwerk-Standardmenü. Nutzer können Benachrichtigungsprobleme selbst eingrenzen und dem Support per Screenshot zeigen.

## Festlegungen
- Sentry bleibt unverändert immer aktiv. Der Schalter „Diagnose-Protokoll“ (#325) steuert nur Netzwerkprotokoll und Debug-Log.
- „Andere Apps“ ist nur ein Menüpunkt, der die Wertwerk-Entwicklerseite im Play Store extern öffnet. Keine eigene Seite.
- Rechtstexte (Impressum, Nutzungsbedingungen, Datenschutz) liegen auf wertwerk.io und werden nur verlinkt.
- Alle neuen Texte in `app_de.arb`, `app_en.arb`, `app_it.arb`.

## PR 1: Menü-Standard

### 1. AppLinks (#328)
`lib/app_links.dart`, `abstract final class AppLinks` nach BiboNest-Muster:
`contactEmail`, `developerName`, `developer`, `faq`, `privacy`, `imprint`, `terms`, `otherApps`, `suggestFeature`, `reportBug` (beide Tally mit `?app=digiregst`), `source`, `playStore`, `feedbackMail(version)`.
Umstellen: `help_feedback_page.dart`, `app_about_dialog.dart` (entfällt), `settings_page_widget.dart` (Quellcode), `api_client.dart`, `services/app_sharing.dart` soweit URLs dort stehen.

### 2. Menü (#323, #329)
`sidebar.dart`, Reihenfolge: Inhalte, Einstellungen, Hilfe, Bewerten, Teilen, Andere Apps, Über, Abmelden. Trennlinien an Gruppengrenzen.
- Neuigkeiten: kein Menüpunkt (Entscheid 2026-10-09). Der Changelog bleibt in der Über-Seite; die Dashboard-Karte meldet neue Versionen.
- Andere Apps: Icon `apps`, öffnet `AppLinks.otherApps` extern.

### 3. Über-Seite und Rechtliches (#324, #327)
`lib/ui/about_page.dart` ersetzt `showAppAboutDialog`: Icon, Name, Versions-Pill, Unabhängigkeitshinweis, Entwickler (Feichter, Debertol, Wachtler), Changelog, GPL/Quellcode, `showLicensePage`, Copyright.
Abschnitt „Rechtliches“: Datenschutz (Kurztext + Link), Impressum, Nutzungsbedingungen als Extern-Links. Zeilenstil einheitlich (Icon links, Extern-Symbol rechts).

### 4. Hilfe (#326)
`lib/ui/help_page.dart`: FAQ als `ExpansionTile`-Liste aus ARB (Anmeldung, Benachrichtigungen, Profil wechseln, Hausaufgaben, App-Sperre). Erster Eintrag in `HelpFeedbackPage`, Online-FAQ bleibt als Link.

### 5. Diagnose-Protokoll (#325)
- Ein Schalter „Diagnose-Protokoll“ in den Einstellungen, Abschnitt „Erweitert“, Standard aus, gespeichert in SharedPreferences. Er löst die bisherigen Einträge „Netzwerkprotokoll“ und „Debug-Log“ ab.
- Die Seiten `NetworkProtocolPage` und `DebugLogPage` samt `NetworkProtocolContainer`, Texten und dem Debug-only-Fixture-Export entfallen. Der Teilen-Export liefert dasselbe JSON-Format, damit bleibt die Fixture-Gewinnung (testdata_capture) möglich.
- Der gespeicherte Wert wird vor `DebugLog.init` gelesen (Muster `storedAppLockEnabled`). `DebugLog` und das Netzwerkprotokoll (`networkProtocolProvider.add`) zeichnen nur bei „an“ auf (statt `kDebugMode`). In Debug-Builds bleibt die Aufzeichnung immer an.
- Bei „an“ erscheint darunter ein Eintrag **„Protokoll teilen“**. Er teilt alles Aufgezeichnete in einem Teilen-Vorgang als zwei Dateien: `dr_debug_log_<zeit>.txt` (bestehendes `DebugLog.export`) und `dr_network_<zeit>.json` (bestehende Serialisierung aus `network_protocol_page.dart`, in einen eigenen Service verschoben und von UI getrennt). Leer: Snackbar „Nichts aufgezeichnet“.
- Vor dem Teilen fragt ein Dialog nach: Das Protokoll enthält Antworten des Portals (Noten, Absenzen, Mitteilungen). Erst nach „Teilen“ geht es an die Teilen-Auswahl.
- Ausschalten löscht Debug-Log-Datei und Netzwerkprotokoll.
- **Passwörter schwärzen:** `_record` ersetzt Werte sensibler Parameter (`password`, `pass`, `newPassword`, …) durch `***`, bevor sie ins Protokoll kommen (heute landet das Passwort aus `profile_provider.dart:53` unverändert darin). Test mit Muster-Request.
- Datenschutztext (online + Kurztext) nennt, was lokal aufgezeichnet wird, dass es nur lokal bleibt und erst beim Teilen durch den Nutzer weitergegeben wird.

### Tests PR 1
`AppLinks` (URLs, Tally-Parameter, Mailbetreff), Sidebar (Einträge, Reihenfolge, Callbacks), `AboutPage` (Abschnitte, Link-Aufrufe), `HelpPage` (Auf-/Zuklappen), Diagnose-Protokoll (Provider-Persistenz, Gating von `DebugLog` und Netzwerkprotokoll, Teilen-Eintrag nur bei „an“, Teilen mit zwei Dateien und Bestätigungsdialog, leeres Protokoll, Löschen beim Ausschalten, Schwärzung von Passwörtern). Widget-Tests für alle UI-Änderungen, Coverage ≥ 80 % auf geändertem Code.

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
