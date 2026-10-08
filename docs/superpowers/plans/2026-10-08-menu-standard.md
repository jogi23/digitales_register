# Standard-Menü und Benachrichtigungs-Diagnose Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** DigiReg ST bekommt das Wertwerk-Standardmenü (#323–#329) und zeigt Benachrichtigungs-Probleme selbst an (#318, #319).

**Architecture:** Zentrale `AppLinks`-Klasse, neue Seiten `AboutPage` und `HelpPage`, zwei neue Menüpunkte. Ein Schalter in den globalen Einstellungen steuert Debug-Log und Netzwerkprotokoll (ersetzt deren Seiten) und ein Teilen-Service exportiert beides. Android-Akku-Status über einen MethodChannel, Hintergrund-Status über SharedPreferences.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, `share_plus`, `url_launcher`, `workmanager`, Kotlin (MainActivity), ARB (de/en/it).

**Spec:** [docs/superpowers/specs/2026-10-08-menu-standard-design.md](../specs/2026-10-08-menu-standard-design.md)

## Global Constraints

- Alle neuen Texte in `lib/l10n/app_de.arb`, `app_en.arb`, `app_it.arb`; Zugriff über `tr(context)`; danach `flutter gen-l10n` (bzw. Build).
- Keine hartcodierten URLs im UI-Code, nur `AppLinks`.
- Tally-Links mit `?app=digiregst`. Datenschutz-URL bleibt `https://wertwerk.io/datenschutz/digiregst`.
- Sentry bleibt unverändert immer aktiv.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` wird nicht deklariert (Play-Richtlinie); nur `ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`.
- Android-Paket der Activity: `io.wertwerk.digitalesregister`.
- Neue Dateien tragen den GPL-Header der Nachbardateien (Copyright Johannes Feichter 2026).
- Kein Passwort und keine Mitteilungstexte im Hintergrund-Status.
- Texte abgeschlossener Changelog-Versionen nie ändern; neue Einträge nur unter 1.6.0 in `assets/changelog.json`, dann `dart tools/generate_changelog.dart`.
- Conventional Commits mit Issue-Nummer; Commits enden mit `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.

## Review Focus

- Passwort-Parameter (`password`, `pass`, `newPassword`) im Netzwerkprotokoll: erwartet `***`, auch verschachtelt in Maps.
- Teilen bei leerem Protokoll: erwartet Snackbar „Nichts aufgezeichnet“, kein leerer Share.
- Teilen, wenn nur eine der zwei Quellen Daten hat: erwartet nur die eine Datei.
- Schalter aus → an → aus: erwartet, dass nach dem Ausschalten nichts mehr aufgezeichnet wird und beide Aufzeichnungen leer sind.
- Hintergrund-Isolate bei ausgeschaltetem Schalter: erwartet kein `debug_log.jsonl` und keine Einträge.
- Akku-Kanal ohne Android oder bei Fehler: erwartet „nicht ausgenommen“ nicht anzuzeigen, sondern die Karte auszublenden.
- Hintergrund-Status ohne bisherigen Lauf oder mit defektem JSON: erwartet Text „Noch kein Lauf“, kein Absturz.
- Sidebar mit 17 Einträgen auf 300×700: erwartet kein Overflow-Fehler.

---

# PR 1 — Menü-Standard (Branch `feat/menu-standard-323-329`, bereits angelegt)

### Task 1: AppLinks (#328)

**Files:**
- Create: `lib/app_links.dart`, `test/app_links_test.dart`
- Modify: `lib/ui/help_feedback_page.dart`, `lib/ui/settings_page_widget.dart` (Quellcode-Zeile ~807), `lib/api_client.dart`, `lib/services/app_sharing.dart`

**Interfaces:**
- Produces: `abstract final class AppLinks` mit `contactEmail` (`hallo@wertwerk.io`), `developerName` (`Johannes Feichter`), `Uri developer` (`https://wertwerk.io`), `faq` (`https://wertwerk.io/projekte/digitale-register-app/#faq`), `privacy`, `imprint` (`https://wertwerk.io/impressum`), `terms` (`https://wertwerk.io/nutzungsbedingungen/digiregst`), `otherApps` (`https://play.google.com/store/apps/developer?id=WertWerk`), `suggestFeature` (`https://tally.so/r/Y5xKgv?app=digiregst`), `reportBug` (`https://tally.so/r/yPdpP6?app=digiregst`), `source` (`https://github.com/jogi23/digitales_register`), `playStore`, `Uri feedbackMail(String version)`; Betreff `Feedback DigiReg ST $version`.

- [ ] **Step 1: Failing test** `test/app_links_test.dart`: `suggestFeature` und `reportBug` haben `queryParameters['app'] == 'digiregst'`; `feedbackMail('1.6.0')` hat Schema `mailto`, Pfad `hallo@wertwerk.io`, Betreff `Feedback DigiReg ST 1.6.0`; alle Uris sind `https`.
- [ ] **Step 2:** `flutter test test/app_links_test.dart` → FAIL (Datei fehlt).
- [ ] **Step 3:** `lib/app_links.dart` nach Muster `C:\projects\bibliothek\lib\src\app_info.dart` anlegen. `playStore` und die Share-URL aus `app_sharing.dart` / `api_client.dart` übernehmen, nicht neu erfinden.
- [ ] **Step 4:** Alle Fundstellen umstellen: `grep -rn "wertwerk.io\|tally.so\|github.com/jogi23\|play.google.com" lib` darf außerhalb `app_links.dart` nichts mehr liefern (Ausnahme `app_about_dialog.dart`, entfällt in Task 3). Bestehende Tests `test/ui/help_feedback`, `test/app_sharing_test.dart` anpassen und laufen lassen.
- [ ] **Step 5:** Test grün, Commit `refactor(links): URLs zentral in AppLinks (#328)`.

### Task 2: Menü — Neuigkeiten und Andere Apps (#323, #329)

**Files:**
- Modify: `lib/ui/sidebar.dart`, `lib/l10n/app_{de,en,it}.arb`, Aufrufer von `Sidebar` (per `tokensave_callers` ermitteln), `test/ui/sidebar/sidebar_test.dart`

**Interfaces:**
- Consumes: `AppLinks.otherApps` (Task 1), `ChangelogPage`.
- Produces: ARB-Schlüssel `menuNews` („Neuigkeiten“ / „What's new“ / „Novità“), `menuOtherApps` („Andere Apps von Wertwerk“ / „Other apps by Wertwerk“ / „Altre app di Wertwerk“).

- [ ] **Step 1: Failing tests** in `sidebar_test.dart`: `lists the entries in the standard order` (Titel der `CollapsibleItem`s in der Reihenfolge Hausaufgaben … Einstellungen, Hilfe, Neuigkeiten, Bewerten, App teilen, Andere Apps, Über, Abmelden); `opens the changelog from "Neuigkeiten"` (Tap → `ChangelogPage` im Baum); `opens the developer page from "Andere Apps"` (`url_launcher`-Plattform per `UrlLauncherPlatform.instance` gemockt, erwartet `AppLinks.otherApps` extern); `fits 17 entries without overflow` bei `Size(300, 700)`.
- [ ] **Step 2:** Tests laufen → FAIL.
- [ ] **Step 3:** ARB-Schlüssel in allen drei Dateien, `sidebar.dart` auf die Reihenfolge nach Spec Abschnitt 2 umbauen: `hasDivider` an „Einstellungen“, „Hilfe“, „Neuigkeiten“-Gruppenanfang, „Über“ und „Abmelden“. Icons `Icons.new_releases_outlined` und `Icons.apps`. Goldens `sidebar_*.png` per `flutter test --update-goldens test/ui/sidebar` neu erzeugen und prüfen.
- [ ] **Step 4:** `flutter test test/ui/sidebar test/ui/drawer_navigation_test.dart` → PASS.
- [ ] **Step 5:** Commit `feat(menu): Neuigkeiten und Andere Apps im Menü (#323, #329)`.

### Task 3: Über-Seite und Rechtliches (#324, #327)

**Files:**
- Create: `lib/ui/about_page.dart`, `test/ui/about/about_page_test.dart`
- Delete: `lib/ui/app_about_dialog.dart`
- Modify: `lib/ui/sidebar.dart` („Über“ öffnet `AboutPage` per `Navigator.push`), `lib/l10n/app_{de,en,it}.arb`

**Interfaces:**
- Consumes: `AppLinks` (Task 1), `appVersion` (`util.dart`), `ChangelogPage`.
- Produces: `class AboutPage extends StatelessWidget` (`const AboutPage({super.key})`); ARB: `aboutLegal` („Rechtliches“), `aboutImprint` („Impressum“), `aboutTerms` („Nutzungsbedingungen“), `aboutPrivacyShort` (Kurztext zur Datenverarbeitung), `aboutDevelopers`, `aboutOpenSourceLicenses`; vorhandene `aboutClientFor`, `aboutFreeSoftware`, `aboutSeeLicence`, `aboutPrivacy`, `changelogTitle` weiterverwenden.

- [ ] **Step 1: Failing tests:** `shows name, version pill and the independence note`; `lists the three developers`; `opens imprint, terms and privacy from "Rechtliches"` (je ein Tap, `UrlLauncherPlatform` gemockt, erwartet `AppLinks.imprint/terms/privacy`); `opens the changelog`; `opens the license page` (`LicensePage` im Baum).
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Seite nach Muster `C:\projects\bibliothek\lib\src\ui\about_page.dart`, Zeilen mit Icon links und Pfeil/Extern-Symbol rechts. Entwicklerlinks (Debertol, Wachtler) in `AppLinks` ergänzen (`developerLinks`), nicht inline.
- [ ] **Step 4:** `app_about_dialog.dart` löschen, Aufrufer und Tests aufräumen; `flutter analyze` ohne neue Befunde.
- [ ] **Step 5:** Commit `feat(about): Über-Seite mit Rechtlichem (#324, #327)`.

### Task 4: Hilfe-Seite mit FAQ (#326)

**Files:**
- Create: `lib/ui/help_page.dart`, `test/ui/help_feedback/help_page_test.dart`
- Modify: `lib/ui/help_feedback_page.dart`, `lib/l10n/app_{de,en,it}.arb`, `test/ui/help_feedback/help_feedback_page_test.dart`

**Interfaces:**
- Produces: `class HelpPage extends StatelessWidget`; ARB-Paare `faqLoginQ/A`, `faqNotificationsQ/A`, `faqProfilesQ/A`, `faqHomeworkQ/A`, `faqAppLockQ/A`, `helpOfflineFaq` („Häufige Fragen“).

- [ ] **Step 1: Failing tests:** `HelpPage` zeigt fünf Fragen, Antwort erst nach Tap sichtbar; `HelpFeedbackPage` hat als ersten Eintrag „Häufige Fragen“ und Tap öffnet `HelpPage`; Online-FAQ-Eintrag bleibt.
- [ ] **Step 2:** FAIL. **Step 3:** `HelpPage` mit `ExpansionTile`s aus ARB, Eintrag in `HelpFeedbackPage` oberhalb von E-Mail; dort ebenfalls `AppLinks` verwenden (aus Task 1). Fragetexte inhaltlich zu dem, was die App tut (Anmeldung/2FA, Hintergrundabruf ist kein Push, Profile wechseln über Avatar, Hausaufgaben abhaken/Filter, App-Sperre).
- [ ] **Step 4:** Tests grün. **Step 5:** Commit `feat(help): FAQ in der App (#326)`.

### Task 5: Diagnose-Schalter und Gating der Aufzeichnung (#325)

**Files:**
- Modify: `lib/app_state.dart` (`SettingsState`: Feld `diagnosticsEnabled`, `copyWith`, `globalJson`, `withGlobalJson`, Gleichheit/Hash, Liste globaler Schlüssel ~Zeile 807), `lib/providers/settings_provider.dart` (`setDiagnosticsEnabled`, `storedDiagnosticsEnabled()`), `lib/debug_log.dart`, `lib/main.dart`, `lib/background_check.dart`, `lib/providers/network_protocol_provider.dart`
- Test: `test/settings_provider_test.dart`, `test/debug_log_test.dart`, `test/providers/network_protocol_provider_test.dart`

**Interfaces:**
- Produces: `SettingsState.diagnosticsEnabled` (Standard `false`, JSON-Schlüssel `diagnosticsEnabled`); `SettingsNotifier.setDiagnosticsEnabled(bool)`; `Future<bool> storedDiagnosticsEnabled()`; `DebugLog.enabled` (bool, Standard `kDebugMode`) statt der `kDebugMode`-Prüfung in `init`/`add`; `NetworkProtocolNotifier.add` verwirft Einträge bei `!diagnosticsEnabled && !kDebugMode`.

- [ ] **Step 1: Failing tests:** `diagnosticsEnabled defaults to off and survives a restart`; `storedDiagnosticsEnabled reads the stored flag`; `DebugLog drops entries while disabled` und `keeps entries after enabled = true`; `network protocol ignores items while diagnostics are off`; `turning diagnostics off clears the debug log and the network protocol`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Feld wie `appLockEnabled` durchziehen. In `main.dart` vor `DebugLog.instance.init()` `DebugLog.instance.enabled = kDebugMode || await storedDiagnosticsEnabled()`. Ein `providerContainer.listen` auf `settingsProvider.select((s) => s.diagnosticsEnabled)` setzt `DebugLog.instance.enabled`, löscht beim Ausschalten Log (`DebugLog.instance.clear()`) und `networkProtocolProvider.notifier.reset()`. Im Hintergrund-Isolate (`checkForNewNotifications` und wo dort `DebugLog.instance.init` läuft) `enabled` aus den gelesenen `settings` setzen, bevor protokolliert wird.
- [ ] **Step 4:** Tests grün. **Step 5:** Commit `feat(diagnostics): Diagnose-Protokoll schaltet Aufzeichnung (#325)`.

### Task 6: Passwörter im Netzwerkprotokoll schwärzen (#325)

**Files:**
- Modify: `lib/session_manager.dart` (`_record`, ~Zeile 424)
- Create: `lib/util/redact.dart` oder Funktion in `lib/util.dart` (Nachbarstil entscheidet), `test/session_manager_test.dart`

**Interfaces:**
- Produces: `Map<String, Object?> redactSensitive(Map<String, Object?> args)` — ersetzt Werte der Schlüssel `password`, `pass`, `newPassword`, `oldPassword` (case-insensitiv) durch `'***'`, rekursiv in Maps und Listen; verändert das Original nicht.

- [ ] **Step 1: Failing tests:** `redactSensitive masks password keys` (`{'email':'a','password':'x'}` → `password: '***'`, `email` unverändert); `masks nested and case-insensitive keys`; `does not mutate its input`; `session manager records redacted parameters` (Request mit `password` → `NetworkProtocolItem.parameters` enthält `***`, nicht den Wert).
- [ ] **Step 2:** FAIL. **Step 3:** Funktion implementieren, in `_record` `stringifyMaybeJson(redactSensitive(args))`. **Step 4:** PASS. **Step 5:** Commit `fix(diagnostics): Passwörter im Netzwerkprotokoll schwärzen (#325)`.

### Task 7: Diagnose-Export (Teilen) (#325)

**Files:**
- Create: `lib/services/diagnostics_export.dart`, `test/services/diagnostics_export_test.dart`
- Modify: `lib/ui/network_protocol_page.dart` (Serialisierung `_exportProtocol`/`_decodeMaybeJson` wandern in den Service; Seite fällt in Task 8 weg)

**Interfaces:**
- Produces: `class DiagnosticsExport { DiagnosticsExport({DebugLog? log, Future<Directory> Function()? tempDir, Future<void> Function(ShareParams)? share}); Future<DiagnosticsExportResult> share(List<NetworkProtocolItem> items); }` mit `enum DiagnosticsExportResult { shared, empty }`; Dateien `dr_debug_log_<zeit>.txt` (`DebugLog.export`, `text/plain`) und `dr_network_<zeit>.json` (bestehendes JSON-Format, `application/json`); Betreff `DigiReg Diagnose-Protokoll`; nur nicht leere Quellen werden angehängt.
- Consumes: `DebugLog.instance.readAll()`, `DebugLog.export(entries)`.

- [ ] **Step 1: Failing tests:** `returns empty and shares nothing when both sources are empty`; `shares both files when both have data` (zwei `XFile`s, Namen/MIME wie oben); `shares only the debug log when the protocol is empty`; `shares only the network file when the log is empty`; `network json decodes nested json responses` (Antwort `'{"a":1}'` → Objekt).
- [ ] **Step 2:** FAIL. **Step 3:** Service implementieren, Teilen und Temp-Verzeichnis injizierbar (Defaults `SharePlus.instance.share`, `getTemporaryDirectory`).
- [ ] **Step 4:** PASS. **Step 5:** Commit `feat(diagnostics): Protokoll als zwei Dateien teilen (#325)`.

### Task 8: Einstellungen — Schalter, Teilen-Eintrag, alte Seiten entfernen (#325)

**Files:**
- Create: `lib/ui/diagnostics_settings.dart`, `test/ui/settings/diagnostics_settings_test.dart`
- Modify: `lib/ui/settings_page_widget.dart` (Zeilen ~778–802 ersetzen), `lib/l10n/app_{de,en,it}.arb`
- Delete: `lib/ui/network_protocol_page.dart`, `lib/ui/debug_log_page.dart`, `lib/container/network_protocol_container.dart`, `lib/ui/network_protocol.dart` samt zugehöriger Tests und nicht mehr genutzter ARB-Schlüssel (`settingsNetworkLog`, `settingsDebugLog`, `networkExport*`, `debugLog*` nur entfernen, wenn `grep` keine Nutzung mehr findet)

**Interfaces:**
- Consumes: `settingsProvider`, `setDiagnosticsEnabled`, `DiagnosticsExport` (Task 7), `networkProtocolProvider`.
- Produces: `class DiagnosticsSettingsTiles extends ConsumerWidget` (Muster `AppLockSettingsTiles`); ARB `settingsDiagnostics` („Diagnose-Protokoll“), `settingsDiagnosticsSubtitle`, `diagnosticsShare` („Protokoll teilen“), `diagnosticsShareWarningTitle/Body`, `diagnosticsNothingRecorded` („Nichts aufgezeichnet“).

- [ ] **Step 1: Failing tests:** `the share entry shows only while the switch is on`; `switching on stores the setting`; `share asks for confirmation first` (Abbrechen → `DiagnosticsExport.share` nicht aufgerufen; „Teilen“ → aufgerufen); `empty result shows the snackbar`; `the old log pages are gone from settings` (kein „Netzwerkprotokoll“/„Debug-Log“).
- [ ] **Step 2:** FAIL. **Step 3:** Tiles-Widget bauen, in „Erweitert“ einsetzen (anstelle der zwei alten Einträge, `settingsSource`-Zeile auf `AppLinks.source`). Alte Seiten und Container löschen, `flutter analyze` sauber.
- [ ] **Step 4:** `flutter test test/ui/settings` → PASS. **Step 5:** Commit `feat(diagnostics): Schalter und Teilen in den Einstellungen (#325)`.

### Task 9: Datenschutz, Changelog, PR 1

**Files:** `assets/changelog.json`, `CHANGELOG.md` (generiert), `docs/STANDARD_MENU.md` (Tabelle „Stand in DigiReg ST“ aktualisieren)

- [ ] **Step 1:** Einträge unter 1.6.0: „Neue Funktionen“ — Über-Seite, Hilfe mit FAQ, Menü (Neuigkeiten, Andere Apps), Impressum/Nutzungsbedingungen, Diagnose-Protokoll; „Verbesserungen“ — Links zentral (falls im Generator vorgesehen, sonst „Intern“ weglassen).
- [ ] **Step 2:** `dart tools/generate_changelog.dart`; `git diff CHANGELOG.md` zeigt nur 1.6.0.
- [ ] **Step 3:** Datenschutz-Kurztext in `aboutPrivacyShort` nennt lokale Aufzeichnung und Teilen durch den Nutzer; Hinweis an den Nutzer, dass die Online-Erklärung auf wertwerk.io entsprechend zu ergänzen ist.
- [ ] **Step 4:** `flutter analyze`, `flutter test` (bekannte Pass-Test-Failures nicht fixen), Coverage auf geänderten Dateien ≥ 80 %. Dart-MCP `analyze_files`, Hot Restart.
- [ ] **Step 5:** `install-debug`-Skill, dann auf dem Pixel prüfen: Menü (17 Einträge scrollen), Über-Seite, Links, FAQ, Schalter an/aus, Teilen mit Bestätigung, Passwort im geteilten JSON geschwärzt. Reviews: `/code-review`, Agent `flutter-reviewer`, `/simplify`. PR erst nach Absprache im Chat.

---

# PR 2 — Benachrichtigungen (neuer Branch `feat/notification-diagnostics-318-319` von `main`)

### Task 10: Akku-Optimierung — Kanal (#318)

**Files:**
- Create: `lib/services/battery_optimization.dart`, `test/services/battery_optimization_test.dart`
- Modify: `android/app/src/main/kotlin/io/wertwerk/digitalesregister/MainActivity.kt`

**Interfaces:**
- Produces: `const batteryChannel = MethodChannel('dr/battery')`; `Future<bool?> isIgnoringBatteryOptimizations({bool? isAndroid})` (null außerhalb Android oder bei Fehler); `Future<void> openBatteryOptimizationSettings({bool? isAndroid})`; Riverpod `batteryOptimizationProvider` (`FutureProvider.autoDispose<bool?>`).
- Kotlin: Methoden `isIgnoring` (`PowerManager.isIgnoringBatteryOptimizations(packageName)`) und `openSettings` (Intent `Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS`, Fallback `Settings.ACTION_APPLICATION_DETAILS_SETTINGS`).

- [ ] **Step 1: Failing tests** (Muster `app_lock_platform_test.dart`): `asks the channel on Android`; `returns null off Android without calling the channel`; `returns null when the channel throws`; `opens the settings through the channel`.
- [ ] **Step 2:** FAIL. **Step 3:** Dart-Seite und Kotlin-Handler implementieren. **Step 4:** PASS, `flutter build apk --debug` baut. **Step 5:** Commit `feat(notifications): Akku-Optimierung abfragen (#318)`.

### Task 11: Akku-Hinweis in den Einstellungen (#318)

**Files:**
- Create: `lib/ui/battery_hint.dart`, `test/ui/settings/battery_hint_test.dart`
- Modify: `lib/ui/settings_page_widget.dart` (Benachrichtigungs-Abschnitt ~Zeile 319), `lib/l10n/app_{de,en,it}.arb`, `lib/services/system_notification_service.dart` (Hinweis nach `_askPermission` beim Einschalten, falls dort der Einschaltweg liegt; sonst im Settings-Callback)

**Interfaces:**
- Consumes: `batteryOptimizationProvider`, `openBatteryOptimizationSettings` (Task 10).
- Produces: `class BatteryOptimizationHint extends ConsumerStatefulWidget` (Karte nur, wenn Provider `false` liefert und Benachrichtigungen an sind; Neuprüfung bei `AppLifecycleState.resumed` per `ref.invalidate`); ARB `batteryHintTitle`, `batteryHintBody`, `batteryHintButton`, `batteryHintMore` (Link `dontkillmyapp.com` in `AppLinks.dontKillMyApp`).

- [ ] **Step 1: Failing tests:** `shows the hint while the app is not exempt`; `hides it when exempt`; `hides it when the state is unknown (null)`; `the button opens the system page`; `checks again after the app resumes` (zweiter Providerwert `true` → Karte weg).
- [ ] **Step 2:** FAIL. **Step 3:** Widget und Einbindung. **Step 4:** PASS. **Step 5:** Commit `feat(notifications): Hinweis auf Akku-Optimierung (#318)`.

### Task 12: Hintergrund-Status speichern (#319)

**Files:**
- Create: `lib/services/background_status.dart`, `test/services/background_status_test.dart`
- Modify: `lib/background_check.dart` (`checkForNewNotifications`), `test/background_check_test.dart`

**Interfaces:**
- Produces: `enum AccountCheckOutcome { ok, unreachable, skippedAppSignedIn, firstRun, failed }`; `class AccountCheckResult { final String label; final AccountCheckOutcome outcome; final int? unread; final int? fresh; }`; `class BackgroundStatus { final DateTime finishedAt; final List<AccountCheckResult> accounts; Map<String, Object?> toJson(); static BackgroundStatus? tryParse(Object? raw); }`; `Future<void> writeBackgroundStatus(SharedPreferences, BackgroundStatus)`; `Future<BackgroundStatus?> readBackgroundStatus()` (ruft `reload()`); Schlüssel `background_check_status`. `label` ist Alias, sonst `accountTag`, nie Benutzername oder Passwort.

- [ ] **Step 1: Failing tests:** `BackgroundStatus round-trips through json`; `tryParse returns null for broken or missing json`; `a round records one result per account` (ok mit Zahlen, nicht erreicht, übersprungen, erster Lauf — über die bestehende Testinfrastruktur in `background_check_test.dart`); `a skipped run (notifications off) leaves the old status`.
- [ ] **Step 2:** FAIL. **Step 3:** Ergebnis je Konto an den vorhandenen `debugLog`-Stellen in `checkForNewNotifications` sammeln und am Ende (nicht bei `testNotification`) schreiben. **Step 4:** PASS. **Step 5:** Commit `feat(notifications): Status des Hintergrundabrufs speichern (#319)`.

### Task 13: Hintergrund-Status anzeigen und „Jetzt prüfen“ (#319)

**Files:**
- Create: `lib/ui/background_status_card.dart`, `test/ui/settings/background_status_card_test.dart`
- Modify: `lib/ui/settings_page_widget.dart` (Zeilen ~355 und ~370: `kDebugMode &&`-Schranke für „Jetzt prüfen“ entfernen, `Platform.isAndroid` bleibt), `lib/l10n/app_{de,en,it}.arb`

**Interfaces:**
- Consumes: `readBackgroundStatus` (Task 12), `runBackgroundCheckNow`, Systemberechtigung aus `system_notification_service.dart`.
- Produces: `class BackgroundStatusCard extends ConsumerWidget` mit `backgroundStatusProvider` (`FutureProvider.autoDispose<BackgroundStatus?>`); ARB `statusLastRun`, `statusNoRun` („Noch kein Lauf“), `statusOk(n)`, `statusUnreachable`, `statusSkippedApp`, `statusFirstRun`, `statusFailed`, `statusPermissionGranted/Denied`, `statusCheckNow`.

- [ ] **Step 1: Failing tests:** `shows the time and one line per account`; `shows "Noch kein Lauf" without a status`; `shows the permission state`; `"Jetzt prüfen" is available in release mode` (ohne `kDebugMode`-Abhängigkeit, Android-Flag injiziert); `refreshes after the check was started`.
- [ ] **Step 2:** FAIL. **Step 3:** Karte unter den Benachrichtigungs-Einstellungen einbauen, `Semantics` für Screenreader. **Step 4:** PASS. **Step 5:** Commit `feat(notifications): Status des Hintergrundabrufs in den Einstellungen (#319)`.

### Task 14: Changelog, Abnahme, PR 2

- [ ] **Step 1:** `assets/changelog.json` unter 1.6.0: „Neue Funktionen“ — Hinweis auf Akku-Optimierung, Status des letzten Hintergrundabrufs; Generator laufen lassen, `git diff CHANGELOG.md` nur 1.6.0.
- [ ] **Step 2:** `flutter analyze`, `flutter test`, Coverage ≥ 80 % auf geändertem Code, Dart-MCP, Hot Restart.
- [ ] **Step 3:** `install-debug`, auf dem Pixel: Karte erscheint bei aktiver Optimierung, Button öffnet Systemseite, nach Rückkehr Status neu; nach „Jetzt prüfen“ Status mit Zeit und Konten; Screenshot für Support lesbar.
- [ ] **Step 4:** `/code-review`, `flutter-reviewer`, `/simplify`; PR erst nach Absprache im Chat.
