# Einstellungen als Kategorien-Hub

Issue: noch offen, vor dem ersten Commit anlegen. Basis-Branch: `feat/notification-diagnostics-318-319` (enthält Menü-Standard, Diagnose-Schalter, Akku-Hinweis, Hintergrund-Status). Arbeits-Branch: `feat/settings-hub`.

Herkunft: Design-Kritik zu Menü und Einstellungen (2026-10-09), Teil A von A/B/C. Abgleich mit BiboNest (`lib/src/ui/accounts_page.dart`, `design/components.dart`) und [docs/STANDARD_MENU.md](../../STANDARD_MENU.md).

## Ziel
Jede Einstellung ist in höchstens zwei Taps erreichbar und der Zustand wichtiger Gruppen ist ohne Öffnen sichtbar. Erfolg: keine Seite mit mehr als einem Bildschirm voller Gruppen, keine Zeile mit Tippfläche unter 48 dp, Farbkreise für Screenreader als Auswahl lesbar.

## Festlegungen
- Kein Feature fällt weg. Sortierung ändert sich, Werte, Schlüssel und Standardwerte nicht.
- Das Menü (Sidebar) bleibt unverändert. Es folgt dem Wertwerk-Standardmenü (Inhalt / Einstellungen / Hilfe / Bewerten, Teilen, Andere Apps / Über / Abmelden). Bewerten, Teilen und Andere Apps bleiben dort. Menü-Icons, Kontrast der Auswahlfarbe und Rand-Wischen sind Teil B.
- Tablet: gleiche Push-Navigation wie auf dem Phone, kein Master-Detail.
- Neue Texte in `app_de.arb`, `app_en.arb`, `app_it.arb`.

## Angleichung an BiboNest
Übernommen:
- **Abschnittstitel:** `titleSmall` in Primärfarbe, `Semantics(header: true)`, Abstand oben 24, seitlich 16, unten 8. Ersetzt `headlineSmall` und die losen `Divider`.
- **Zeilen:** Icon links (abgerundete Variante), Titel, Untertitel mit aktuellem Wert. Rechts Pfeil für Ziele in der App, `open_in_new` für externe Ziele. Schalter nutzen `secondary` als Icon. Radio-Gruppen bekommen kein Icon.
- **Auswahl:** Sprache, Theme, Intervall, Sternfarbe als Zeile mit Wert im Untertitel, Tap öffnet einen Dialog mit Auswahl. Theme ist kein SegmentedButton mehr (BiboNest nutzt ebenfalls einen Dialog).
Abweichung: Der Hub behält `ResponsiveAppBar` (Menü-Knopf, Tablet-Logik). Die Unterseiten nutzen eine normale `AppBar` mit Zurück-Pfeil, weil `ResponsiveAppBar` nie einen Zurück-Pfeil zeigt. Kein `SliverAppBar.medium`.

## Struktur und Navigation
- `SettingsHubPage` ersetzt `SettingsPageWidget` als Ziel von `Pages.settings`. Sieben Zeilen mit Icon, Titel, Kurzstatus, Pfeil. Ganze Zeile tippbar.
- Kurzstatus aus `settingsProvider`: Benachrichtigungen „An · alle 30 Min" / „Aus", Darstellung „Hell · Deutsch", Konto „App-Sperre an" usw.
- Unterseiten unter `lib/ui/settings/`, je ein `ConsumerWidget` mit `SettingsPageScaffold` (normale `AppBar`). `Navigator.push` im geschachtelten Navigator, Zurück führt zum Hub.
- Demo-Modus: Profil und Konten entfallen. Wird eine Kategorie leer, verschwindet sie im Hub.
- Noten-Deep-Link: `scrollToGrades` entfällt samt `AutoScrollController`, `cacheExtent`-Workaround und `showGradesSettings` im ViewModel. Stattdessen öffnet `showGradesSettings` des Routers den Hub und legt die Noten-Unterseite darüber.
- Sidebar-Markierung bleibt `Pages.settings`, Unterseiten ändern sie nicht.

## Kategorien
| # | Kategorie | Inhalt |
|---|---|---|
| 1 | Konto & Sicherheit | Profil, Konten, Angemeldet bleiben (Untertitel ein Satz, Rest im Info-Dialog), App-Sperre, Seite beim Kontowechsel behalten |
| 2 | Benachrichtigungen | Hauptschalter, Intervall, Akku-Hinweis, Status-Karte, Abschnitt „Typen" mit sechs Schaltern, Debug-Zeilen unter `kDebugMode` |
| 3 | Darstellung | Sprache, Theme, Akzentfarbe, Akzent-Hintergrund |
| 4 | Fächer & Kalender | Nicks & Farben, Unterricht einfärben, Zeiten, Details, 6-Tage-Woche |
| 5 | Hausaufgaben & Klassenbuch | Abschnitte Hausaufgaben (Ansicht, Neu markieren, Duplikate, Tests rot, Farben), Klassenbuch, Übersicht, Abwesenheiten, Allgemein („Beim Löschen fragen") |
| 6 | Noten | Diagramm, Durchschnitte, Anzeige, Sternfarbe, ausgeschlossene Fächer |
| 7 | Erweitert | Diagnose-Protokoll, Quellcode (mit `open_in_new`) |

## Bausteine (`lib/ui/settings/widgets/`)
- `SettingsSectionHeader`: wie oben beschrieben.
- `SettingsChoiceTile<T>`: ganze Zeile tippbar, Wert im Untertitel, Dialog mit Radio-Liste. Sternfarbe zeigt die Vorschau-Sterne im Dialog. Bei großer Schrift bricht nichts um.
- `DisplayModeTiles`, `ArrangementTiles`: heutige `_displayModeTiles` und `_arrangementTiles` als eigene Widgets. Zeitleiste bleibt sichtbar, aber gesperrt mit Begründung.
- `AccentColorPicker` (aus `_SeedColorPicker`): Tippfläche je Kreis 48 × 48 dp, sichtbarer Kreis 36 dp. `Semantics(button: true, selected: …, label: Farbname)`. Haken und Rand bleiben als farbunabhängiges Merkmal.
- Leerzustand „Kein Fach ausgeschlossen": `colorScheme.onSurfaceVariant` statt `Colors.grey`, Einrückung wie die anderen Zeilen.

## Datenfluss und Migration
Kategorieseiten lesen und schreiben `settingsProvider` direkt. Entfallen: `SettingsPageWidget`, `SettingsPageContainer`, `SettingsViewModel`, `OnSettingChanged`, die 37 Callbacks. Theme-Setter (`DynamicTheme`) bleiben in der Darstellungs-Seite, da sie nicht im Provider liegen. `AllSubjects` und `isDemo` kommen aus ihren Providern. Das Verhalten jeder Einstellung bleibt, jeder Schreibweg wird per Test belegt.

## Texte
Neu: sieben Kategorietitel, Kurzstatus-Muster, Info-Dialog „Angemeldet bleiben", Abschnittstitel („Typen", „Anzeige", „Allgemein", „Kalender"), Semantics-Labels der Farbkreise. Bestehende Texte werden nur umgezogen. Danach `flutter gen-l10n` prüfen.

## Tests (erst Test, dann Code)
- **Bausteine:** `SettingsChoiceTile` (ganze Zeile tippbar, Dialog, Wert im Untertitel), `AccentColorPicker` (Größe ≥ 48 dp per `tester.getSize`, Semantics `selected`), `SettingsSectionHeader` (Header-Semantics).
- **Hub:** je Kategorie Zeile vorhanden, Tap öffnet Unterseite, Zurück kehrt zurück. Kurzstatus je Zustand. Demo-Modus.
- **Unterseiten:** `ProviderScope`-Override, jeder Schalter und jede Auswahl ändert den Wert im `settingsProvider`. Sperrlogik der Benachrichtigungs-Typen und der Zeitleiste.
- **Deep-Link:** Noten-Einstellungen öffnen Hub + Noten-Seite, Zurück landet im Hub.
- **Barrierefreiheit:** `androidTapTargetGuideline` und `labeledTapTargetGuideline` auf Hub und Unterseiten.
- Die Fälle aus `test/ui/settings/settings_test.dart` werden auf die neuen Seiten verteilt, keiner geht verloren. Coverage ≥ 80 % auf geändertem Code. Bekannte Pass-Test-Failures bleiben unberührt.

## Reihenfolge der Commits
1. Bausteine mit Tests.
2. Hub und Router/Deep-Link, Unterseiten zunächst leer.
3. Eine Kategorie je Commit: Konto, Benachrichtigungen, Darstellung, Fächer & Kalender, Hausaufgaben & Klassenbuch, Noten, Erweitert.
4. Altes `SettingsPageWidget`, Container, ViewModel entfernen, Tests aufräumen.
5. CHANGELOG über den Generator prüfen, Texte abgeschlossener Versionen unverändert.

## Risiken
- Beim Verschieben der Callbacks geht ein Schreibweg verloren: jeder Schalter bekommt einen State-Test, kein `result != null`.
- Rückweg auf Tablet im geschachtelten Navigator: per Test belegen.
- Die Basis `feat/notification-diagnostics-318-319` ist noch nicht in `main`. Der PR geht erst nach deren Merge, sonst gestapelt.

## Nicht im Umfang
Teil B (Menü-Icons, Auswahlkontrast, Rand-Wischen) und Teil C außer den hier genannten Farbkreisen und `Colors.grey`. Suche in den Einstellungen. Master-Detail auf dem Tablet.
