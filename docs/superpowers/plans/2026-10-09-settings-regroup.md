# Einstellungen: fünf Kategorien, einklappbare Inhalts-Blöcke

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:executing-plans. Aufbau auf dem Plan [2026-10-09-settings-hub.md](2026-10-09-settings-hub.md); Spec-Abschnitt „Änderung 2026-10-09" in [der Spec](../specs/2026-10-09-settings-hub-design.md). Issue #333.

**Goal:** Hub mit fünf Kategorien; „Inhalte & Ansichten" fasst Fächer & Kalender, Merkheft, Klassenbuch, Hausaufgaben-Übersicht, Absenzen und Noten in einklappbaren Blöcken zusammen.

## Global Constraints
- Commits wie bisher, `(#333)`, Trailer `Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>`.
- Neue Texte in de/en/it, nicht mehr gebrauchte ARB-Schlüssel entfernen.
- Jede Einstellung behält ihren Setter; Tests belegen jeden Schreibweg.

## Review Focus
- Noten-Deep-Link öffnet den Block „Noten" aufgeklappt, Zurück führt zum Hub.
- Einklappen versteckt Inhalte für Screenreader (kein Fokus auf Zugeklapptem); Kopfzeile ≥ 48 dp, `expanded`-Semantik.
- Text 200 % ohne Overflow in Kopfzeilen mit Kurztext.

### Task R1: SettingsExpandableSection
**Files:** Create `lib/ui/settings/widgets/settings_expandable_section.dart`, `test/ui/settings/widgets/settings_expandable_section_test.dart`.
**Interfaces:** Produces `class SettingsExpandableSection extends StatelessWidget { const SettingsExpandableSection({super.key, required String title, required String summary, required List<Widget> children, bool initiallyExpanded = false}) }` (`ExpansionTile`, ohne Trennlinien, Kurztext als Untertitel).
- [ ] Tests: zu bei Standard (Kinder nicht sichtbar), Tap öffnet, `initiallyExpanded` offen, mehrere Blöcke gleichzeitig offen, Text 200 % ohne Overflow, Barrierefreiheits-Richtlinien.
- [ ] Implementieren, Tests grün, Commit `feat(settings): einklappbarer Block (#333)`.

### Task R2: Blöcke, Inhalts-Seite, fünf Kategorien
**Files:** Create `lib/ui/settings/blocks/{subjects_calendar_block,merkheft_block,entry_view_blocks,grades_block}.dart`, `lib/ui/settings/pages/content_settings_page.dart`; Modify `settings_category.dart`, `app_router.dart`, `main.dart`, ARB; Delete `pages/{subjects_calendar,homework,grades}_settings_page.dart` und ihre Tests (Tests ziehen nach `test/ui/settings/blocks/` um).
**Interfaces:** Produces `enum ContentBlock { subjectsCalendar, merkheft, classbook, overview, absences, grades }`; `class ContentSettingsPage extends StatelessWidget { const ContentSettingsPage({super.key, Set<ContentBlock> initiallyExpanded = const {}}) }`; Blöcke als `ConsumerWidget`s ohne Scaffold. `SettingsCategory` hat `account, notifications, appearance, content, advanced`.
- [ ] Tests zuerst: Block-Tests (aus den Seiten-Tests, mit „Beim Löschen fragen" im Merkheft), `content_settings_page_test.dart` (sechs Blöcke zu, Aufklappen, Deep-Link-Variante mit `{grades}`, Richtlinien), Hub-Test mit fünf Zeilen, Routing-Test mit `ContentSettingsPage`.
- [ ] Implementieren; ARB: `settingsCategoryAppearance` → „Design & Sprache" / „Theme & language" / „Tema e lingua", neu `settingsCategoryContent`, `settingsSummaryContent`, Block-Kurztexte; entfernen `settingsCategorySubjectsCalendar|Homework|Grades`, `settingsSummaryHomework|SubjectsCalendar|Grades`, `settingsSectionGeneral`.
- [ ] Route `settingsGrades` baut `ContentSettingsPage(initiallyExpanded: {ContentBlock.grades})`.
- [ ] Tests grün, Commit `refactor(settings): fünf Kategorien, Inhalte & Ansichten (#333)`.

### Task R3: Abschluss
- [ ] `flutter analyze`, `flutter test`, Coverage, Review (`flutter-reviewer`), Installation per `install-debug`, Bericht.
