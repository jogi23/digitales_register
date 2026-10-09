# Einstellungen als Kategorien-Hub Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die Einstellungen werden ein Hub mit sieben Kategorien und Unterseiten, die `settingsProvider` direkt lesen; die 37-Callback-Seite entfällt.

**Architecture:** Kleine Bausteine (`lib/ui/settings/widgets/`) tragen Abschnittstitel, Auswahlzeile, Farbkreise und Anzeigemodus-Zeilen. Jede Kategorie ist ein `ConsumerWidget` unter `lib/ui/settings/pages/`. Erst entstehen alle Seiten (unerreichbar, App bleibt lauffähig), dann schaltet der Hub in Router und Routen um, dann wird Altes gelöscht.

**Tech Stack:** Flutter, flutter_riverpod, `dynamic_theme`, ARB (de/en/it), flutter_test, golden_toolkit.

**Spec:** [docs/superpowers/specs/2026-10-09-settings-hub-design.md](../specs/2026-10-09-settings-hub-design.md). Issue: [#333](https://github.com/jogi23/digitales_register/issues/333). Branch: `feat/settings-hub` (Basis `feat/notification-diagnostics-318-319`).

## Global Constraints

- Sidebar (`lib/ui/sidebar.dart`) bleibt unverändert.
- Kein Feature fällt weg; Schlüssel, Werte und Standardwerte in `SettingsState` bleiben, außer dem entfallenden `scrollToGrades`.
- Abschnittstitel: `titleSmall`, `colorScheme.primary`, `Semantics(header: true)`, Padding `fromLTRB(16, 24, 16, 8)`. Unterabschnitt: `labelLarge`.
- Tippfläche jeder Zeile und jedes Farbkreises ≥ 48 dp; sichtbarer Farbkreis 36 dp.
- Zeilen: Icon links (`*_rounded`-Variante), Pfeil `Icons.chevron_right_rounded` für Ziele in der App, `Icons.open_in_new_rounded` für externe. Schalter nutzen `secondary`. Radio-Gruppen ohne Icon.
- Tablet wie Phone: Push-Navigation, kein Master-Detail.
- Neue Texte in `lib/l10n/app_de.arb`, `app_en.arb`, `app_it.arb`; danach `flutter gen-l10n`. Texte per `tr(context)`.
- Commits: Conventional Commits mit `(#333)`, Trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Verifikation: `flutter analyze` und `flutter test`; bekannte Pass-Test-Failures nicht fixen. Coverage ≥ 80 % auf geändertem Code.
- Neue Dateien tragen den GPL-Header der Nachbardateien (`Copyright (C) 2026 Johannes Feichter`).

## Neue ARB-Schlüssel (de / en / it)

| Schlüssel | de | en | it |
|---|---|---|---|
| `settingsCategoryAccount` | Konto & Sicherheit | Account & security | Account e sicurezza |
| `settingsCategoryNotifications` | Benachrichtigungen | Notifications | Notifiche |
| `settingsCategoryAppearance` | Darstellung | Appearance | Aspetto |
| `settingsCategorySubjectsCalendar` | Fächer & Kalender | Subjects & calendar | Materie e calendario |
| `settingsCategoryHomework` | Hausaufgaben & Klassenbuch | Homework & class register | Compiti e registro di classe |
| `settingsCategoryGrades` | Noten | Grades | Voti |
| `settingsCategoryAdvanced` | Erweitert | Advanced | Avanzate |
| `settingsSummaryNotificationsOn` (`interval`: String) | An · {interval} | On · {interval} | Attive · {interval} |
| `settingsSummaryNotificationsOff` | Aus | Off | Disattivate |
| `settingsSummaryAppearance` (`theme`, `language`: String) | {theme} · {language} | {theme} · {language} | {theme} · {language} |
| `settingsSummaryAppLockOn` | App-Sperre an | App lock on | Blocco app attivo |
| `settingsSummaryAppLockOff` | App-Sperre aus | App lock off | Blocco app disattivato |
| `settingsSummarySubjectsCalendar` | Kürzel, Farben, Kalender | Abbreviations, colours, calendar | Abbreviazioni, colori, calendario |
| `settingsSummaryHomework` | Ansicht, Klassenbuch, Absenzen | View, class register, absences | Vista, registro, assenze |
| `settingsSummaryGrades` | Diagramm, Durchschnitt, Sterne | Chart, average, stars | Grafico, media, stelle |
| `settingsSummaryDiagnosticsOn` | Diagnose-Protokoll an | Diagnostic log on | Registro diagnostico attivo |
| `settingsSummaryDiagnosticsOff` | Diagnose-Protokoll aus | Diagnostic log off | Registro diagnostico disattivato |
| `settingsSectionGeneral` | Allgemein | General | Generale |
| `settingsSectionCalendar` | Kalender | Calendar | Calendario |
| `settingsTheme` | Design | Theme | Tema |
| `settingsMoreInfo` | Mehr Informationen | More information | Maggiori informazioni |

## Review Focus

- Android-Zurück auf einer Unterseite landet im Hub, vom Hub im Menü-Inhalt; beim Deep-Link zu den Noten führt Zurück erst zum Hub, dann zur Notenseite.
- Systemschrift 200 %: Hub-Zeilen und `SettingsChoiceTile` laufen nicht über (kein Overflow).
- Demo-Modus: Konto-Seite ohne Profil- und Konten-Zeile, Hub zeigt weiter alle sieben Kategorien.
- Ausgeschlossene Fächer: „+" mit leerer Fächerliste öffnet den Dialog ohne Absturz; Löschen des letzten Eintrags zeigt den Leerzustand.
- Gespeicherter Wert fehlt in der Auswahlliste (z. B. `starColor` mit unbekannter ID): `SettingsChoiceTile` zeigt einen leeren Untertitel statt abzustürzen oder eine falsche Auswahl vorzutäuschen (Task 2).

Abweichung von der Spec: Der Hub blendet leere Kategorien nicht aus. Im Demo-Modus bleibt jede Kategorie gefüllt (Konto behält Schalter und App-Sperre), eine Ausblend-Logik wäre damit ungenutzter Code.

---

### Task 1: Testhelfer, Abschnittstitel, Seiten-Rahmen

**Files:**
- Create: `lib/ui/settings/widgets/settings_headers.dart`, `lib/ui/settings/widgets/settings_page_scaffold.dart`, `test/ui/settings/settings_pump.dart`, `test/ui/settings/widgets/settings_headers_test.dart`

**Interfaces:**
- Produces: `class SettingsSectionHeader extends StatelessWidget { const SettingsSectionHeader(String title, {Key? key}) }`, `class SettingsSubheader extends StatelessWidget { const SettingsSubheader(String title, {Key? key}) }`, `class SettingsPageScaffold extends StatelessWidget { const SettingsPageScaffold({Key? key, required String title, required List<Widget> children}) }` (Scaffold mit `ResponsiveAppBar(title: Text(title), actions: const [ConnectionStatusButton()])` und `ListView(padding: context.systemInsets, children: children)`).
- Produces (Test): `Future<ProviderContainer> pumpSettings(WidgetTester tester, Widget home, {SettingsState? settings, bool demo = false, double textScale = 1})` (übernimmt den Aufbau aus `_pumpSettingsPage` in `test/ui/settings/settings_test.dart`: `_TestSettingsNotifier`, `pc.providerContainer`, `DynamicTheme`, de-Locale; `demo` überschreibt `isDemoProvider`; `textScale` setzt `MediaQuery.textScaler`) und `Future<void> expectMeetsGuidelines(WidgetTester tester)` (`ensureSemantics`, `androidTapTargetGuideline`, `labeledTapTargetGuideline`).

- [ ] **Step 1: Write the failing test** in `settings_headers_test.dart`: `'section header is a primary titleSmall header'` pumpt `SettingsSectionHeader('Noten')`, erwartet `tester.getSemantics(find.text('Noten'))` mit `SemanticsFlag.isHeader`, `Text.style.color == colorScheme.primary`, Padding `EdgeInsets.fromLTRB(16, 24, 16, 8)`. `'subheader uses labelLarge'` prüft `style == textTheme.labelLarge` (Farbe unberührt). `'scaffold shows title and children'` pumpt `SettingsPageScaffold(title: 'T', children: [Text('x')])` und findet beide Texte.
- [ ] **Step 2: Run** `flutter test test/ui/settings/widgets/settings_headers_test.dart`. Expected: FAIL (Dateien fehlen).
- [ ] **Step 3: Implement** die drei Widgets und `settings_pump.dart` gemäß Interfaces.
- [ ] **Step 4: Run** den Test erneut. Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): Abschnittstitel und Seiten-Rahmen (#333)`.

### Task 2: SettingsChoiceTile

**Files:**
- Create: `lib/ui/settings/widgets/settings_choice_tile.dart`, `test/ui/settings/widgets/settings_choice_tile_test.dart`

**Interfaces:**
- Consumes: `pumpSettings` (Task 1).
- Produces: `class SettingsChoice<T> { const SettingsChoice({required T value, required String label, Widget? leading}) }`; `class SettingsChoiceTile<T> extends StatelessWidget { const SettingsChoiceTile({Key? key, required IconData icon, required String title, required T value, required List<SettingsChoice<T>> choices, required ValueChanged<T> onChanged, String? hint, bool enabled = true}) }`. Untertitel = Beschriftung des aktuellen Werts (leer, wenn `value` in `choices` fehlt). Tap auf die ganze Zeile öffnet `AlertDialog` (Titel `title`, `hint` als Text darüber, `RadioListTile` je Auswahl, `commonCancel`). Auswahl schließt den Dialog und ruft `onChanged` nur bei geändertem Wert.

- [ ] **Step 1: Write the failing tests:** `'subtitle shows the current label'`; `'tapping the title (not only a trailing widget) opens the dialog'`; `'picking another option calls onChanged once and closes'` (Erwartung: Liste der Aufrufe `[2]`); `'picking the current option does not call onChanged'`; `'unknown value shows an empty subtitle without throwing'`; `'disabled tile does not open'`; `'large text scale 2.0 has no overflow'` (`pumpSettings(textScale: 2)`, `tester.takeException()` ist null).
- [ ] **Step 2: Run** `flutter test test/ui/settings/widgets/settings_choice_tile_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `SettingsChoiceTile` gemäß Interfaces (`ListTile(leading: Icon(icon), title, subtitle, enabled, onTap)`).
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): Auswahlzeile mit Dialog (#333)`.

### Task 3: AccentColorPicker

**Files:**
- Create: `lib/ui/settings/widgets/accent_color_picker.dart`, `test/ui/settings/widgets/accent_color_picker_test.dart`

**Interfaces:**
- Consumes: `pumpSettings`.
- Produces: `class AccentColorPicker extends StatelessWidget { const AccentColorPicker({Key? key}) }` mit den zehn Farben und Beschriftungen aus `_SeedColorPicker._colors` in `lib/ui/settings_page_widget.dart` (Werte unverändert übernehmen), Titel `settingsAccentColor`. Jeder Kreis: `Semantics(button: true, selected: isSelected, label: farbname)` um `InkResponse`, Tippfläche `SizedBox(48, 48)`, sichtbarer Kreis 36 dp, Haken und Rand für die Auswahl bleiben, Tap ruft `DynamicTheme.of(context)!.setSeedColor(color)`.

- [ ] **Step 1: Write the failing tests:** `'every swatch has a tap target of at least 48x48'` (`tester.getSize(find.byType(InkResponse).first)` ≥ 48 in beiden Achsen, alle zehn); `'the selected swatch is announced as selected'` (`tester.getSemantics` des aktuellen Seeds hat `SemanticsFlag.isSelected`, ein anderer nicht); `'tapping a swatch sets the seed colour'` (`DynamicTheme.of(context)!.seedColor == Color(0xFF009688)` nach Tap auf „Türkis"); `'meets tap target guidelines'` (`expectMeetsGuidelines`).
- [ ] **Step 2: Run** `flutter test test/ui/settings/widgets/accent_color_picker_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** `AccentColorPicker`; `readableOn` und Farbliste wie im Altcode weiterverwenden.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): Farbkreise mit 48-dp-Tippfläche und Semantics (#333)`.

### Task 4: Anzeigemodus- und Anordnungs-Zeilen

**Files:**
- Create: `lib/ui/settings/widgets/view_option_tiles.dart`, `test/ui/settings/widgets/view_option_tiles_test.dart`

**Interfaces:**
- Produces: `class DisplayModeTiles extends StatelessWidget { const DisplayModeTiles({Key? key, required EntryDisplayMode value, required ValueChanged<EntryDisplayMode> onChanged, bool offerTimeline = false, bool timelineEnabled = true}) }` und `class ArrangementTiles extends StatelessWidget { const ArrangementTiles({Key? key, required ClassbookViewMode value, required ValueChanged<ClassbookViewMode> onChanged}) }`. Verhalten wie `_displayModeTiles` / `_arrangementTiles` in `settings_page_widget.dart` (Zeitleiste bleibt sichtbar, gesperrt, Untertitel `displayTimelineOnlyByDay`); Kopfzeilen über `SettingsSubheader(settingsDisplay)` bzw. `SettingsSubheader(settingsClassbookView)`.

- [ ] **Step 1: Write the failing tests:** `'list and cards are offered, timeline only with offerTimeline'`; `'timeline is disabled with the reason when timelineEnabled is false'` (Text `Nur bei Anordnung nach Tag` bzw. der Wert von `displayTimelineOnlyByDay`; Tap ruft `onChanged` nicht auf); `'picking cards calls onChanged with EntryDisplayMode.cards'`; `'arrangement offers chronological and by subject and reports the pick'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/widgets/view_option_tiles_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** beide Widgets; die Beschriftungen stammen aus den bestehenden ARB-Schlüsseln.
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): Anzeige- und Anordnungs-Zeilen als Widgets (#333)`.

### Task 5: Seite „Konto & Sicherheit"

**Files:**
- Create: `lib/ui/settings/pages/account_settings_page.dart`, `test/ui/settings/pages/account_settings_page_test.dart`
- Modify: `lib/l10n/app_{de,en,it}.arb` (`settingsCategoryAccount`, `settingsMoreInfo`)

**Interfaces:**
- Consumes: `SettingsPageScaffold`, `SettingsSectionHeader`, `pumpSettings`; bestehend `AccountSettingsTile`, `AppLockSettingsTiles`, `appRouterProvider.showProfile`, `isDemoProvider`.
- Produces: `class AccountSettingsPage extends ConsumerWidget { const AccountSettingsPage({Key? key}) }`. Inhalt: (nicht Demo) Zeile „Profil" (`Icons.person_outline_rounded`, Chevron, `ref.read(appRouterProvider).showProfile`) und `AccountSettingsTile`; Schalter „Angemeldet bleiben" (`setSaveNoPass(!value)`; Untertitel nur `settingsStayLoggedInSubtitle`; `IconButton` `Icons.info_outline_rounded` mit Tooltip `settingsMoreInfo` öffnet `AlertDialog` mit `settingsStayLoggedInOffHint` und `settingsStayLoggedInBackgroundHint`); `AppLockSettingsTiles`; (nicht Demo) Schalter `settingsKeepPageOnAccountSwitch` (`setKeepPageOnAccountSwitch`).

- [ ] **Step 1: Write the failing tests** (Texte aus den bisherigen Tests übernehmen und dorthin verschieben: `'the account row opens the account card'` mit `AccountSheet`, `'staying on the page when switching accounts can be turned on'` mit Label `Beim Kontowechsel auf der Seite bleiben`): zusätzlich `'stay logged in writes noPasswordSaving'` (Tap → `noPasswordSaving == true`), `'the info button explains the two hints'` (Dialog enthält beide Hinweistexte), `'demo mode hides profile, account and keep-page rows'` (`demo: true`), `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/account_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** die Seite und die ARB-Schlüssel (alle drei Sprachen), `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Die verschobenen Tests aus `settings_test.dart` löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Konto & Sicherheit (#333)`.

### Task 6: Seite „Benachrichtigungen"

**Files:**
- Create: `lib/ui/settings/pages/notification_settings_page.dart`, `test/ui/settings/pages/notification_settings_page_test.dart`
- Modify: ARB (`settingsCategoryNotifications`)

**Interfaces:**
- Consumes: `SettingsChoiceTile`, `SettingsSectionHeader`, Bausteine aus Task 1; bestehend `BatteryOptimizationHint`, `BackgroundStatusCard`, `runBackgroundCheckNow`, `debugCheckDelay`, `allowedNotificationPollMinutes`.
- Produces: `class NotificationSettingsPage extends ConsumerWidget`. Inhalt wie Block in `settings_page_widget.dart` (Hauptschalter mit Untertitel `settingsNotificationsNeedStayLoggedIn` bei `noPasswordSaving && Platform.isAndroid`; `BatteryOptimizationHint`; `BackgroundStatusCard`; Intervall als `SettingsChoiceTile<int>` mit `_intervalLabel`-Logik, `hint: settingsNotificationsIntervalSubtitle`, `enabled: notificationsEnabled`; Debug-Zeilen unverändert unter `kDebugMode && Platform.isAndroid`; `SettingsSectionHeader(settingsNotificationsTypes)` und sechs Typ-Schalter, gesperrt solange der Hauptschalter aus ist).

- [ ] **Step 1: Write the failing tests:** verschobener Test `'notification settings can be changed'` (Hauptschalter aus/an, Intervall 30 Min → 3 Stunden ergibt `notificationPollMinutes == 180`, über den Dialog); `'each type switch writes its setting'` (sechs Schalter: classbook, messages, grades, observations, homework, absences, je Tap kippt das Feld); `'type switches and interval are disabled while notifications are off'` (`SwitchListTile.onChanged == null`, Tap auf Intervall öffnet keinen Dialog); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/notification_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite und ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobenen Test aus `settings_test.dart` löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Benachrichtigungen (#333)`.

### Task 7: Seite „Darstellung"

**Files:**
- Create: `lib/ui/settings/pages/appearance_settings_page.dart`, `test/ui/settings/pages/appearance_settings_page_test.dart`
- Modify: ARB (`settingsCategoryAppearance`, `settingsTheme`)

**Interfaces:**
- Consumes: `SettingsChoiceTile`, `AccentColorPicker`; `supportedLanguages`, `languageNames`, `DynamicTheme`.
- Produces: `class AppearanceSettingsPage extends ConsumerWidget`; Sprache als `SettingsChoiceTile<String>` (`''` = `settingsLanguageDevice`, Schreiben `setLanguage(value == '' ? null : value)`); Theme als `SettingsChoiceTile<ThemeChoice>` mit `enum ThemeChoice { followDevice, light, dark }` (öffentlich in der Datei) und Logik von `_selectTheme` (`setFollowDevice` / `setBrightness` über `DynamicTheme`); `AccentColorPicker`; Schalter `settingsAccentBackground`.

- [ ] **Step 1: Write the failing tests:** `'picking Dunkel sets brightness dark and stops following the device'` (`DynamicTheme.of(context)!.followDevice == false`, `customBrightness == Brightness.dark`); `'picking the device theme turns followDevice on'`; `'picking a language writes it, the device entry writes null'`; verschobener Test `'switching off the accent background writes the setting'` (Label `Hintergrund in Akzentfarbe`); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/appearance_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite und ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobenen Test löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Darstellung (#333)`.

### Task 8: Seite „Fächer & Kalender"

**Files:**
- Create: `lib/ui/settings/pages/subjects_calendar_settings_page.dart`, `test/ui/settings/pages/subjects_calendar_settings_page_test.dart`
- Modify: ARB (`settingsCategorySubjectsCalendar`, `settingsSectionCalendar`)

**Interfaces:**
- Produces: `class SubjectsCalendarSettingsPage extends ConsumerWidget`. Zeile `settingsNicksAndColors` (`Icons.palette_outlined`, Chevron, `Navigator.push` auf `SubjectAppearancePage`), `SettingsSectionHeader(settingsSectionCalendar)`, Schalter `settingsColorLessons` (`setCalendarColorBackground`), `settingsShowTimes` (`setCalendarShowTimes`), `settingsShowAllDetails` mit Hinweis (`setCalendarShowAllDetails`), `settingsSixDayWeek` mit Hinweis (`setSixDayWeek`).

- [ ] **Step 1: Write the failing tests:** verschobener Test `'opens the subject appearance screen from "Aussehen"'` (Text `Kürzel und Farben`, `find.byType(SubjectAppearancePage)`); `'each calendar switch writes its setting'` (vier Schalter: Farben, Zeiten, Details, 6-Tage-Woche kippen `calendarColorBackground`, `calendarShowTimes`, `calendarShowAllDetails`, `sixDayWeek`); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/subjects_calendar_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite und ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobenen Test löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Fächer & Kalender (#333)`.

### Task 9: Seite „Hausaufgaben & Klassenbuch"

**Files:**
- Create: `lib/ui/settings/pages/homework_settings_page.dart`, `test/ui/settings/pages/homework_settings_page_test.dart`
- Modify: ARB (`settingsCategoryHomework`, `settingsSectionGeneral`)

**Interfaces:**
- Consumes: `DisplayModeTiles`, `ArrangementTiles`, `SettingsSectionHeader`.
- Produces: `class HomeworkSettingsPage extends ConsumerWidget` mit Abschnitten: `settingsSectionHomework` (Radio-Gruppe `DashboardViewMode` Liste/Monat/Woche über `setDashboardViewMode`; Schalter `settingsMarkNewEntries` → `setMarkNewOrChanged`, `settingsIgnoreDuplicates` → `setDeduplicate`, `settingsFrameTestsRed` → `setDashboardColorTestsInRed`, `settingsColorHomework` → `setDashboardColorBorders`); `settingsClassbook` (`ArrangementTiles` → `setClassbookViewMode`, `DisplayModeTiles(offerTimeline: true, timelineEnabled: classbookViewMode == chronological)` → `setClassbookDisplayMode`); `settingsHomeworkOverview` (Anordnung → `setHomeworkViewMode`, Anzeige → `setHomeworkDisplayMode`); `settingsAbsences` (Anzeige → `setAbsencesDisplayMode`); `settingsSectionGeneral` (Schalter `settingsAskWhenDeleting` → `setAskWhenDelete`).

- [ ] **Step 1: Write the failing tests:** verschobener Test `'picking the month view writes the setting'` (Label `Als Monatskalender anzeigen`); `'switches write their settings'` (markNew, dedupe, testsInRed, colorBorders, askWhenDelete); `'classbook timeline is only selectable chronologically'` (bei `ClassbookViewMode.bySubject` ist die Zeitleiste gesperrt); `'homework, classbook and absences display modes write their own setting'` (je Karten wählen, drei Felder unabhängig); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/homework_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite und ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobenen Test löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Hausaufgaben & Klassenbuch (#333)`.

### Task 10: Seite „Noten"

**Files:**
- Create: `lib/ui/settings/pages/grades_settings_page.dart`, `lib/ui/settings/widgets/add_subject_dialog.dart`, `test/ui/settings/pages/grades_settings_page_test.dart`
- Modify: ARB (`settingsCategoryGrades`)

**Interfaces:**
- Consumes: `DisplayModeTiles`, `SettingsChoiceTile`, `allSubjectsProvider`, `Deleteable`.
- Produces: `class GradesSettingsPage extends ConsumerWidget`; `class AddSubject extends StatefulWidget` unverändert aus `settings_page_widget.dart` nach `add_subject_dialog.dart` verschoben (Name und Konstruktor bleiben). Inhalt: Schalter `settingsShowChart` (`setShowGradesDiagram`), `settingsShowAllSubjectsAverage`, `settingsShowSubjectAverage`; `DisplayModeTiles` → `setGradesDisplayMode`; Sternfarbe als `SettingsChoiceTile<String>` (Auswahlen `accentStarColorId` und `starColors`, `leading: Icon(Icons.star, color: resolveStarColor(...))`, `hint: settingsStarColorSubtitle`); Zeile `settingsExcludeSubjects` mit „+" (öffnet `AddSubject`), Liste der ausgeschlossenen Fächer mit „×" über `AnimatedCrossFade` und `Deleteable` wie bisher; Leerzustand `settingsNoSubjectExcluded` in `colorScheme.onSurfaceVariant`, gleiche Einrückung (16) wie die Einträge.

- [ ] **Step 1: Write the failing tests:** verschobene Tests `'switching off the per-subject average writes the setting'` (Label `Durchschnitt je Fach anzeigen`), `'picking a star colour writes the setting'` (Zeile `Farbe der Sterne`, `Gelb` ergibt `starColor == 'amber'`; über den Dialog), `'adds an item'` und `'removes an item'` (Ausschluss-Liste, Fach1) mit unveränderten Assertions; neu: `'the empty hint is not a hardcoded grey'` (Textfarbe == `colorScheme.onSurfaceVariant`); `'plus with no available subjects opens the dialog'` (`allSubjectsProvider` leer, `find.byType(InfoDialog)` gefunden, keine Exception); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/grades_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite, `AddSubject` verschieben (alte Datei erst in Task 12 entfernen; bis dahin importiert sie den neuen Ort nicht, `AddSubject` existiert vorübergehend doppelt unter getrennten Importpfaden — daher in `settings_page_widget.dart` die Klasse jetzt durch `export` ersetzen: `export 'package:dr/ui/settings/widgets/add_subject_dialog.dart';`), ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobene Tests löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Noten (#333)`.

### Task 11: Seite „Erweitert"

**Files:**
- Create: `lib/ui/settings/pages/advanced_settings_page.dart`, `test/ui/settings/pages/advanced_settings_page_test.dart`
- Modify: ARB (`settingsCategoryAdvanced`)

**Interfaces:**
- Consumes: bestehend `DiagnosticsSettingsTiles`, `AppLinks.source`, `launchUrl`.
- Produces: `class AdvancedSettingsPage extends StatelessWidget` mit `DiagnosticsSettingsTiles` und der Zeile `settingsSource` (`Icons.code_rounded`, `Icons.open_in_new_rounded`, öffnet `AppLinks.source`).

- [ ] **Step 1: Write the failing tests:** verschobener Test `'offers the diagnostic log instead of the two log pages'` (`Diagnose-Protokoll` da, `Netzwerkprotokoll` und `Debug-Log` fehlen); `'the source row shows the external symbol'` (`find.byIcon(Icons.open_in_new_rounded)`); `'meets tap target guidelines'`.
- [ ] **Step 2: Run** `flutter test test/ui/settings/pages/advanced_settings_page_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Seite und ARB, `flutter gen-l10n`.
- [ ] **Step 4: Run.** Expected: PASS. Verschobenen Test löschen.
- [ ] **Step 5: Commit** `feat(settings): Seite Erweitert (#333)`.

### Task 12: Hub, Router, Routen, Deep-Link

**Files:**
- Create: `lib/ui/settings/settings_category.dart`, `lib/ui/settings/settings_hub_page.dart`, `test/ui/settings/settings_hub_page_test.dart`, `test/services/settings_routing_test.dart`
- Modify: `lib/services/app_router.dart:84-88` und `:208-211`, `lib/main.dart:262-267` (Route `settings`; neue Route `settingsGrades`), ARB (alle `settingsCategory*` übrigen und `settingsSummary*`)

**Interfaces:**
- Consumes: alle Seiten aus Task 5–11.
- Produces: `enum SettingsCategory { account, notifications, appearance, subjectsCalendar, homework, grades, advanced }` mit `IconData get icon`, `String title(BuildContext context)`, `String summary(BuildContext context, SettingsState s)`, `Widget get page`; Summen laut ARB-Tabelle (Benachrichtigungen: `settingsSummaryNotificationsOn(interval)` / `...Off`; Darstellung: `settingsSummaryAppearance(theme, language)` mit `DynamicTheme`-Zustand; Konto: AppLock an/aus; Erweitert: Diagnose an/aus; übrige statisch). `class SettingsHubPage extends ConsumerWidget { const SettingsHubPage({Key? key}) }`: `SettingsPageScaffold(title: settingsTitle)` mit sieben `ListTile` (Icon `*_rounded`, Titel, Kurzstatus als Untertitel, `Icons.chevron_right_rounded`, Tap → `Navigator.push(MaterialPageRoute(builder: (_) => category.page))`). `AppRouter.showSettings` wählt `const SettingsHubPage()` (ohne `resetScroll`). `AppRouter.showEditGradesAverageSettings` pusht `"/settings"` und dann `"/settingsGrades"`; in `main.dart` baut `"settings"` den Hub (unverändert `fullscreenDialog: true`), `"settingsGrades"` baut `const GradesSettingsPage()` als normale `MaterialPageRoute`.

- [ ] **Step 1: Write the failing tests:** Hub: `'shows the seven categories in order'`; `'tapping each category opens its page and back returns to the hub'` (sieben Seitentypen); `'summaries reflect the state'` (Benachrichtigungen aus → `Aus`, an mit 30 → `An · alle 30 Min`; App-Sperre; Diagnose); `'demo mode keeps all seven categories'`; `'large text scale 2.0 has no overflow'`; `'meets tap target guidelines'`. Routing: `'editing the grades average opens hub, then grades settings; back returns to the hub'` (Navigator mit den Routen aus `main.dart`-Muster, `find.byType(SettingsHubPage)` nach einmal Zurück, `find.byType(GradesSettingsPage)` zuvor).
- [ ] **Step 2: Run** `flutter test test/ui/settings/settings_hub_page_test.dart test/services/settings_routing_test.dart`. Expected: FAIL.
- [ ] **Step 3: Implement** Enum, Hub, Router- und Routenänderungen, ARB-Rest, `flutter gen-l10n`.
- [ ] **Step 4: Run** beide Tests plus `flutter test test/ui/sidebar test/ui/drawer_navigation_test.dart`. Expected: PASS.
- [ ] **Step 5: Commit** `feat(settings): Kategorien-Hub als Einstellungen (#333)`.

### Task 13: Altes entfernen

**Files:**
- Delete: `lib/ui/settings_page_widget.dart`, `lib/container/settings_page.dart`, `test/ui/settings/settings_test.dart`, `test/ui/settings/goldens/scrolled_to_grades.png` (Pfad per `Glob` prüfen)
- Modify: `lib/app_state.dart` (Feld `scrollToGrades`: Konstruktor, Deklaration, `copyWith`, Zeile 836, `==`, `hashCode`), `lib/providers/settings_provider.dart` (`load`: `copyWith(scrollToGrades: false)` entfällt, `scrollToGradesSection`, `resetScroll`), `test/settings_provider_test.dart:193-198`, `pubspec.yaml` (`scroll_to_index`, falls sonst unbenutzt per `Grep`)

- [ ] **Step 1: Remove the tests of the old API:** den Test bei `test/settings_provider_test.dart:193-198` (`scrollToGradesSection`) entfernen; `settings_test.dart` samt Golden löschen (alle Fälle liegen seit Task 5–11 in den Seiten-Tests).
- [ ] **Step 2: Run** `flutter analyze` nach dem Löschen der Quelldateien. Expected: Fehler genau an den oben gelisteten Nutzungen von `SettingsPageContainer`, `SettingsViewModel`, `scrollToGrades`.
- [ ] **Step 3: Implement** die Bereinigung; `AddSubject`-`export` aus Task 10 entfällt mit der Datei. `flutter pub get`.
- [ ] **Step 4: Run** `flutter analyze` und `flutter test`. Expected: sauber bzw. nur bekannte Pass-Test-Failures.
- [ ] **Step 5: Commit** `refactor(settings): alte Einstellungsseite und Scroll-Flag entfernen (#333)`.

### Task 14: Abschluss und Gerät

**Files:**
- Modify: `CHANGELOG.md` (über `tools/generate_changelog.dart`; Texte abgeschlossener Versionen nie ändern)

- [ ] **Step 1:** Changelog-Eintrag für #333 prüfen/erzeugen („Einstellungen in Kategorien gegliedert; Farbkreise besser bedienbar").
- [ ] **Step 2:** `flutter analyze`, `flutter test`, Coverage der neuen Dateien ≥ 80 % (`flutter test --coverage`, `lcov`-Zeilen für `lib/ui/settings/`). Expected: grün bzw. nur bekannte Pass-Test-Failures.
- [ ] **Step 3:** Dart-MCP: `analyze_files`, `get_runtime_errors`, Hot Reload nach Codeänderung.
- [ ] **Step 4:** Auf das Handy per Skill `install-debug`. Von Hand prüfen: Menü → Einstellungen zeigt Hub; jede Kategorie öffnet; Android-Zurück; Noten-Deep-Link von der Notenseite („Durchschnitt bearbeiten"); TalkBack liest Farbkreise als „ausgewählt".
- [ ] **Step 5:** Berichten: was ist auf dem Pixel, was fehlt, was wie testen. Dann Review (`/code-review`, `flutter-reviewer`, `/simplify`) vor dem PR; PR erst nach Absprache.
