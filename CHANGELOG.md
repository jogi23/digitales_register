# Änderungen

Erzeugt aus `assets/changelog.json` mit `dart tools/generate_changelog.dart` — Änderungen bitte dort eintragen, nicht hier.

## 1.3.0 — 2026-09-10

### Neue Funktionen

- Die App spricht Italienisch und Englisch. Die Sprache lässt sich in den Einstellungen wählen; ohne eigene Wahl folgt sie dem Gerät.
- Klassenbuch: alle Unterrichtseinträge auf einer eigenen Seite, wahlweise nach Tagen oder nach Fach
- Klassenbuch: Fächer über Chips filtern; die Auswahl gilt je Konto
- Hausaufgaben: Aufgaben und Prüfungen in einer Übersicht, statt nur in der einzelnen Stunde
- Unterrichtsmaterialien: Themen je Fach mit Dateien, Links und Texten; Dateien landen wie jeder andere Anhang im gewohnten Ordner

### Verbesserungen

- Ein Link, der die bereits geöffnete App erreicht, springt direkt zur gewünschten Seite, statt die App neu zu laden
- Bewertungen geben beim Antippen wieder eine sichtbare Rückmeldung
- Die App ist rund 39 MB kleiner: das Bild des Startbildschirms lag zehnmal im Paket
- „App teilen“ steht jetzt im Menü bei „Über diese App“ statt oben in den Einstellungen
- Das Konto ist über den Avatar in der Titelzeile erreichbar; der zweite Zugang oben im Menü entfällt
- Das Merkheft heißt in der Überschrift wie im Menü
- Die Kalenderwoche im Merkheft steht in der Akzentfarbe, die gewählte Woche zusätzlich hinterlegt
- Das Netzwerkprotokoll in der Diagnose hält Zeitpunkt und Fehlergrund jeder Anfrage fest
- Die Liste der Neuerungen kennzeichnet mit „(neu)“, was mit dem letzten Update dazugekommen ist

### Fehlerbehebungen

- Ein geöffneter Link löscht nicht mehr die gespeicherten Zugangsdaten des gerade verwendeten Kontos
- Beim Anmelden eines zweiten Kontos bleibt das erste erhalten
- Die App bleibt sichtbar, wenn sie über einen Link aus dem Hintergrund geholt wird
- Merkheft: die unterste Zeile der Kalenderansichten liegt nicht mehr unter der Navigationsleiste des Geräts
- Merkheft: eine noch ladende Woche antippen verwirft die Auswahl nicht mehr
- Ein Schlüsselspeicher, der sich nicht mehr lesen lässt, wird wieder gemeldet und geleert, statt die Anmeldung stumm scheitern zu lassen
- Übersehene deutsche Texte in Meldungen und Diensten sowie ein falsches Anführungszeichen übersetzt

### Intern

- Flutter auf 3.47.2 und das Android-Build-Plugin auf 9.1.0 angehoben; damit entfallen die veralteten Aufrufe für die randlose Anzeige unter Android 15 und neuer
- Zwei nicht mehr gepflegte Zusatzpakete durch ihre Nachfolger ersetzt
- Jede Änderung wird vor dem Zusammenführen automatisch geprüft: Codeanalyse und alle Tests
- iOS wird unsigniert auf einem macOS-Runner mitgebaut
- Zeilenenden im Projekt vereinheitlicht und per .gitattributes festgehalten

## 1.2.1 — 2026-09-08

### Neue Funktionen

- Mitteilungen, die eine Bestätigung verlangen, lassen sich in der App akzeptieren und mit dem eigenen Namen unterschreiben
- Bewertungen: eigene Detailseite mit dem Kommentar zu jeder Kompetenz, dem Eintragenden und dem Datum, ab dem die Bewertung sichtbar war
- Bewertungen: Anzahl der Einträge, Kompetenzen und Beobachtungen je Fach in der Übersicht
- Farbe der Sterne in den Einstellungen wählbar, mit je einem Ton für den hellen und den dunklen Modus
- Konto in den Einstellungen und über den Namen im Menü erreichbar
- Diese Neuerungen erscheinen nach einem Update direkt im Merkheft
- Merkheft: zwei Kalenderansichten neben der Liste — Monatskalender und Wochenplan
- Merkheft: die Kalenderansichten laden Vergangenheit und Zukunft nach; eine Schaltfläche springt zur aktuellen Woche
- Merkheft: Fachfarben, hervorgehobener heutiger Tag und Kalenderwochen in den neuen Ansichten
- Merkheft: der Tageskopf nennt die Einträge des Tages; ein Tag lässt sich in Vollbild öffnen
- Kalender: Uhrzeit je Stunde, Pausen sind als solche zu sehen
- „App teilen“ in den Einstellungen und „Bei Google Play bewerten“ im Menü

### Verbesserungen

- Die App startet ohne Kontoabfrage im zuletzt genutzten Konto
- Die Konten-Karte fährt von oben ein statt von unten — sie gehört zum Avatar in der Titelzeile
- Der Durchschnitt steht hinter dem Fachnamen und entfällt, solange nichts bewertet ist
- Einstellungen zu Aussehen, Fächern, Merkheft und Noten gelten für alle Konten
- Bewertungen: gruppierte Einträge sind als Unterebene des Fachs erkennbar
- Bewertungen: Kompetenzsterne stehen immer unter ihrem Namen
- Eine Stunde mit Hausaufgabe öffnet den zugehörigen Tag; Überschriften im Merkheft sind hervorgehoben
- Nach mehrfacher Nutzung fragt die App einmal nach einer Bewertung im Store
- Schrift auf farbigen Flächen folgt dem tatsächlichen Kontrast statt einer festen Regel

### Fehlerbehebungen

- Ein Konto ohne gespeicherten Stand übernimmt nicht mehr die Einstellungen des zuvor genutzten Kontos
- Die Sterne im Merkheft und in den Bewertungen haben wieder dieselbe Farbe
- Merkheft: Einträge im Wochenplan sind sichtbar und lassen sich dort anlegen
- Merkheft: die Tagesansicht folgt Änderungen am Bestand
- Merkheft: die Farbe folgt den Einträgen, die Erinnerung stammt aus der gewählten Woche
- Merkheft: Ausgrauen im Dunkelmodus und der Hinweis bei leeren Tagen korrigiert
- Merkheft: es steht jetzt da, wenn der Server für den Zeitraum nichts liefert
- Kalender: eine leere Woche ist vom Ladevorgang zu unterscheiden
- Kalender: die Mittagspause erscheint auch bei durchgehendem Fach
- Konten: die Initialen kommen aus dem Namen statt aus der Matrikelnummer
- Konten: das Häkchen zum Bestätigen des Alias ist klar zu sehen
- Das Menü öffnete sich nach der Rückkehr aus einer Menüseite von selbst

### Intern

- Diagramm von charts_flutter auf fl_chart umgestellt; die aufgegebene Bibliothek liegt nicht mehr im Projekt

## 1.2.0 — 2026-07-11

### Neue Funktionen

- Demomodus in allen Versionen, nicht nur in Testversionen: die App mit Beispieldaten ausprobieren, bevor man sich anmeldet
- Neuer Bereich „Hilfe und Feedback“ im Menü mit häufigen Fragen, einem Formular für Fehler und Wünsche sowie Kontakt per E-Mail
- Eigene Seite für Fächerkürzel und -farben

### Verbesserungen

- Kürzel und Farben gelten app-weit und bleiben erhalten, auch wenn ein Konto gelöscht wird
- Neue Fächer bekommen Farben, die sich von den bereits vergebenen deutlich unterscheiden
- Dunkelmodus: Fächerfarben auf Karten und in Kalenderzellen kräftiger
- Einstellungen vereinfacht: „Daten lokal speichern“ und „Daten beim Abmelden löschen“ entfallen — zwischengespeichert wird immer, beim Abmelden wird automatisch gelöscht

### Fehlerbehebungen

- Der Kalender springt beim Öffnen nicht mehr auf die aktuelle Woche zurück, sondern bleibt auf der zuletzt angesehenen
- Die Tagesliste springt nicht mehr an den Anfang, wenn im Hintergrund aktualisiert wird

## 1.1.6 — 2026-06-26

### Neue Funktionen

- Demokonto mit anonymisierten Daten für alle Bereiche
- Startbildschirm mit Logo-Animation
- Schulliste wird aus einer eigenen Datei geladen

### Verbesserungen

- Absenzen: übersichtliche Zeilen mit Statussymbolen und abwechselnden Hintergründen
- Bewertungen: abwechselnde Farben, hervorgehobene Überschriften und Sternebewertung für Grundschulen
- Zeugnis: zweispaltig und seitlich scrollbar
- Mitteilungen: besserer Kontrast

### Fehlerbehebungen

- Die Navigationsleiste mit drei Schaltflächen verdeckt keine Inhalte mehr
- „Ohne Note“ wird wieder korrekt angezeigt
- Benachrichtigungen zu Bewertungen führen zum richtigen Eintrag
- Profilfotos werden beim Start geladen
- Ein Konto erschien beim Start doppelt

## 1.1.5 — 2026-06-13

### Neue Funktionen

- Profilfoto und Kontoverwaltung: Avatar in jeder Titelzeile mit Initialen oder Foto, dazu eine Karte zum Festlegen von Foto und Alias, zum Wechseln und Hinzufügen von Konten
- Das Merkheft bleibt über Neustarts erhalten, auch ohne Internetverbindung
- Eine Benachrichtigung zu einer Bewertung führt direkt zum Fach und klappt den Eintrag auf

### Fehlerbehebungen

- Ohne Verbindung zeigt die App die gespeicherten Daten statt eines leeren Bildschirms und meldet die fehlende Verbindung verständlich
- Der Startbildschirm erschien als schmaler Streifen und füllt nun den ganzen Bildschirm
- Das Menü öffnet sich von überall, per Wischen wie über die Schaltfläche
- Beim Kontowechsel blitzte der Startbildschirm auf
- „Über diese App“: der Link zum Digitalen Register lässt sich antippen

## 1.1.4 — 2026-06-09

### Verbesserungen

- Eigenes App-Symbol, das sich der Form des Geräts anpasst, und ein eigener Startbildschirm

### Fehlerbehebungen

- Nach einem Neustart ohne Internet werden Bewertungen, Kalender, Mitteilungen, Absenzen, Benachrichtigungen und Profil wieder korrekt angezeigt
- Kompetenzbewertungen zeigen sechs statt fünf Sterne
- Der Startbildschirm füllt den ganzen Bildschirm

### Intern

- Link zur Datenschutzerklärung in den Einstellungen
- Leistungsmessung von Sentry abgeschaltet, iOS-Modus und ungenutzte Dateien entfernt

## 1.1.3 — 2026-06-04

### Fehlerbehebungen

- Eine Mitteilung aus einer Benachrichtigung öffnet sich beim ersten Antippen
- Die Kennzeichnung „neu“ verschwindet, sobald die Mitteilung gelesen ist
- Eine gelesene Mitteilung verschwindet aus der Benachrichtigungsliste

### Intern

- Android Gradle Plugin und Kotlin aktualisiert
- flutter_markdown durch flutter_markdown_plus ersetzt
- Die Neuerungen werden aus den GitHub-Releases geladen

## 1.1.2 — 2026-06-01

### Verbesserungen

- Das Menü lässt sich von links her aufziehen
- Kalender: „Aktuelle Woche“ ist immer sichtbar und in der laufenden Woche ausgegraut
- Benachrichtigungen: „Mitteilung öffnen“ führt zur betreffenden Mitteilung statt zur Liste
- „Über diese App“: „Neuerungen“ öffnet diese Liste
- „Über diese App“ zeigt das App-Symbol

## 1.1.1 — 2026-06-01

### Neue Funktionen

- Mitteilungen: „Alle als gelesen markieren“ in der Titelzeile
- Mitteilungen: zum Aktualisieren nach unten ziehen; ohne Verbindung wird ein neuer Verbindungsversuch gestartet

### Fehlerbehebungen

- Gelesene Mitteilungen galten nach Neustart, Seitenwechsel oder Kontowechsel wieder als ungelesen

## 1.1.0 — 2026-06-01

### Verbesserungen

- Kalender und Merkheft bekommen farbige Hintergründe

### Intern

- Zustandsverwaltung vollständig auf Riverpod umgestellt, Redux entfernt
- Einstellungen und Fächerfarben intern vereinfacht

## 1.0.2 — 2026-06-01

### Intern

- Zeugnisansicht auf Riverpod umgestellt

## 1.0.1 — 2026-06-01

### Fehlerbehebungen

- Das Merkheft ist im Menü auf allen Geräten sichtbar, auch unter Android
- Kalender: Fächerfarben werden wieder angezeigt; der Absturz bei fehlender Farbe ist behoben
- Bewertungen: einheitlicher Seitentitel

## 1.0.0 — 2026-06-01

### Neue Funktionen

- Fortführung der App von Michael Debertol und Simon Wachtler — vielen Dank für die Vorarbeit
- Akzentfarbe in den Einstellungen wählbar

### Verbesserungen

- „Hausaufgaben“ heißt jetzt „Merkheft“, „Noten“ heißt „Bewertungen“
- Die Feedback-Schaltfläche öffnet direkt eine E-Mail
- Absenzen, Fehlermeldungen und der Hinweis „Keine Verbindung“ nehmen die gewählten Farben an
- Bessere Bedienbarkeit mit Screenreader: Ladeanzeige, Anhänge und Schaltflächen sind beschriftet

### Fehlerbehebungen

- Kalender: Darstellungsfehler im Querformat behoben
