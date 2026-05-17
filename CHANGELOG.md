
## 1.1.0

### Interne Änderungen
- State-Management vollständig auf Riverpod umgestellt (Redux entfernt)
- Einstellungen und Fach-Themes intern vereinfacht (built_value teilweise entfernt)

## 1.0.2

### Änderungen
- Zeugnis-Ansicht intern auf Riverpod migriert (Vorbereitung für weiteren State-Management-Umbau)

## 1.0.1

### Änderungen
- Merkheft-Tab in der Seitenleiste ist nun auf allen Plattformen (inkl. Android) sichtbar
- Kalender: Fachfarben werden nun korrekt angezeigt (Absturz bei fehlendem Thema behoben)
- Noten: Seitentitel auf "Bewertungen" vereinheitlicht

## 1.0.0
Diese App ist eine Fortsetzung des ursprünglichen Projekts von Michael Debertol und Simon Wachtler
(https://github.com/miDeb/digitales_register). Herzlichen Dank für die großartige Arbeit!

### Änderungen
- Akzentfarbe der App kann nun in den Einstellungen angepasst werden
- Seitenleiste: "Hausaufgaben" wurde zu "Merkheft" umbenannt
- Seitenleiste: "Noten" wurde zu "Bewertungen" umbenannt
- Feedback-Schaltfläche öffnet nun direkt eine E-Mail
- Kalender: Überlauf-Fehler im Querformat behoben
- Kalender: Ladeindikator ist nun barrierefrei (Screenreader-Label)
- Kalenderansicht: Anhang-Schaltfläche ist nun barrierefrei beschriftet
- Abwesenheiten: Farben passen sich nun dem gewählten Theme an
- Startseite: FAB-Farben und Tooltips für bessere Zugänglichkeit aktualisiert
- Fehlermeldungen und "Kein Internet"-Anzeige verwenden nun Theme-Farben statt hartcodiertem Rot
- `WillPopScope` durch `PopScope` ersetzt (Flutter-Deprecation behoben)