# Änderungen

Erzeugt aus `assets/changelog.json` mit `dart tools/generate_changelog.dart` — Änderungen bitte dort eintragen, nicht hier.

## 1.4.1 — 2026-09-24

### Neue Funktionen

- Profilfoto: Vor dem Speichern lässt sich der Ausschnitt wählen. Das Bild lässt sich im Fenster ziehen und zoomen; was im Kreis steht, wird das Foto.
- Profilfoto: Ein Tippen auf das Foto fragt, ob es gewechselt oder entfernt werden soll. Entfernt stehen wieder die Initialen im Kreis.
- Mitteilungen: eine selbst gesendete Mitteilung lässt sich zurücknehmen, solange das Portal es erlaubt — vier Stunden nach dem Senden. Nach einer Rückfrage; bei den Empfängern verschwindet sie mit.
- Benachrichtigungen: Neue Mitteilungen, Bewertungen und andere Einträge erscheinen unter Android als Systembenachrichtigung, auch wenn die App geschlossen ist — für alle gespeicherten Konten, je Konto gruppiert und mit dessen Alias. Ein Tippen öffnet den Eintrag und wechselt dafür bei Bedarf das Konto. In den Einstellungen lässt sich festlegen, wie oft nachgesehen wird und welche Arten sich melden. Konten mit Zwei-Faktor-Anmeldung, SPID oder CIE sowie das Demokonto bleiben außen vor.

### Verbesserungen

- Fächerfarben sind auf einem neu eingerichteten Gerät von Anfang an eingeschaltet. Wer sie ausgeschaltet hat, behält sie aus.
- Merkheft-Wochenansicht: Sind die Fächerfarben aus, tragen Stunden mit Einträgen einen ruhigen Hintergrund und unten rechts ein kleines Zeichen. Bisher färbte die Wochenansicht auch dann ein, wenn die Farben abbestellt waren.
- Merkheft-Wochenansicht: Sind alle Einträge eines Fachs an diesem Tag abgehakt, trägt die Stunde unten rechts einen Haken. Noten und Beobachtungen zählen nicht mit — sie sind nichts zum Abarbeiten.
- Mitteilungen: Beantwortete Mitteilungen zeigen in der Liste, wie sie beantwortet wurden — Daumen hoch für zugestimmt, Daumen runter für abgelehnt, ein gefüllter Stift für unterschrieben —, auch wenn der andere Erziehungsberechtigte geantwortet hat. Bisher trugen sie gar keine Marke mehr. Alle Marken, auch die für noch offene Antworten, sind jetzt reine Symbole, damit mehrere nebeneinander in die Titelzeile passen.

### Fehlerbehebungen

- Das Profilfoto ließ sich nach der ersten Auswahl nicht mehr ändern: Das neue Bild lag unter demselben Namen, und die App zeigte weiter das alte.
- Kalender: Bei einem neuen Konto hatten nur einige Fächer eine Farbe. Jedes Fach bekommt seine Farbe jetzt, sobald es auftaucht — auch wenn es nur im Stundenplan vorkommt.
- Beim Start mit gespeichertem Konto und nach einem Kontowechsel meldet sich die App nur noch einmal an. Eine zweite Anmeldung zur selben Zeit konnte die Sitzung stören, und beendete das Portal sie später, konnte die App abstürzen.
- Merkheft: Wechselte die Ansicht von der Liste in den Monat oder die Woche — etwa beim Öffnen der App —, lud die App die Einträge beider Richtungen nicht nach. Das Laden startete mitten im Aufbau der Seite und brach ab.
- Mitteilungen: Eine Mitteilung, zu der noch eine ungelesene Benachrichtigung besteht, gilt jetzt als neu, auch wenn das Portal sie schon als gelesen führt. Bisher fehlte ihr dann das „neu“.

### Intern

- Plugins für App-Infos, Teilen und Dateiauswahl auf aktuelle Fassungen gehoben, dazu der sichere Speicher; unter Windows laufen sie damit auf win32 6. Der eigene Schlüsselspeicher für macOS und Linux ist entfallen — dort greift jetzt derselbe sichere Speicher wie auf den anderen Plattformen.
- Teilen (App-Einladung, Mitteilungs-Export, Debug-Log, Netzwerkprotokoll) nutzt die aktuelle Schnittstelle von share_plus statt der veralteten.
- Debug-Log (nur in Debug-Builds): hält jetzt fest, was beim Start, bei Anmeldung, Sitzung und Kontowechsel, im Hintergrundabruf und beim Tippen auf Systembenachrichtigungen geschieht, dazu Schreibwege bei Mitteilungen und Absenzen und unbehandelte Fehler. Die Einträge landen auch in einer Datei, die einen Neustart übersteht und die Einträge des Hintergrundabrufs aufnimmt; im Speicher bleiben höchstens 1000. Konten erscheinen nur als Kürzel, Passwörter, Cookies und Mitteilungstexte nie. Die Seite lässt sich nach Art filtern und per Ziehen neu laden.

## 1.4.0 — 2026-09-15

### Neue Funktionen

- Mitteilungen: die Liste ist in Empfangen, Gesendet, Archiviert und Alle aufgeteilt. Beim Öffnen stehen die empfangenen Mitteilungen; führt eine Benachrichtigung zu einer gesendeten oder archivierten Mitteilung, wechselt die Liste dorthin.
- Mitteilungen: ein Stern markiert wichtige Mitteilungen, „Markiert“ zeigt nur diese. Die Markierung bleibt auf dem Gerät; das Portal kennt sie nicht.
- Mitteilungen: die Liste lässt sich nach Datum (neueste oder älteste zuerst) oder nach Absender sortieren. „Ungelesen“ zeigt nur ungelesene Mitteilungen; wer eine davon öffnet, verliert sie nicht aus der Liste, bis der Filter wieder aus ist.
- Mitteilungen: ein langer Druck auf eine Mitteilung startet die Auswahl. Ausgewählte Mitteilungen lassen sich gemeinsam als PDF, Text oder Markdown teilen oder speichern, archivieren und wieder aus dem Archiv holen.
- Mitteilungen: neue Mitteilungen schreiben und auf empfangene antworten. Empfänger lassen sich nach Namen, Klasse oder Gruppe suchen; bei einer Gruppe lässt sich jede Person einzeln abwählen. Vor dem Senden sagt die App, an wie viele Personen die Mitteilung geht. Beim Antworten steht die ursprüngliche Mitteilung wie im Portal kursiv darunter; das Zitat lässt sich abschalten.
- Kalender: eine Stunde außerhalb des eigenen Klassenzimmers trägt oben rechts ein kleines Dreieck, auch in der Wochenansicht des Merkhefts. Ein langer Druck auf die Stunde nennt den Raum; eine gebuchte Präsentationskamera gilt nicht als Raum.
- Einstellungen → Fächer: „Alle Details im Kalender anzeigen“ nennt in der Stunde auch den Raum, soweit Platz ist. Der Ortsname, den alle Räume der Woche tragen, entfällt; bei mehreren Räumen steht „+1“ dahinter. Lehrpersonen und Raum werden dafür bei Bedarf etwas kleiner, das Fach nie. Voreingestellt bleibt alles wie bisher.
- Bewertungen: ein Lesezeichen markiert einzelne Noten, in der Liste und auf der Seite der Note. „Nur markierte Noten anzeigen“ blendet alles andere aus. Die Markierung bleibt auf dem Gerät und gilt je Konto; das Portal kennt sie nicht.
- Mitteilungen: beim Schreiben und Antworten lassen sich Dateien anhängen. Jeder Anhang zeigt Name, Größe und ob er schon beim Portal ist; gesendet wird erst, wenn alle oben sind. Wie viele Anhänge erlaubt sind, sagt die Schule.
- Absenzen: Absenzen lassen sich in der App begründen und unterschreiben, künftige Absenzen im Voraus melden und wieder löschen. Verlangt die Schule eine Selbsterklärung, steht sie zur Auswahl. Ob ein Konto das darf, entscheidet das Portal; bereits entschuldigte Absenzen bleiben unverändert.

### Verbesserungen

- Mitteilungen: der Betreff selbst gesendeter Mitteilungen steht kursiv und etwas kleiner, damit sie sich unter „Alle“ von empfangenen abheben.

### Fehlerbehebungen

- Mitteilungen: selbst gesendete Mitteilungen gelten nicht mehr als neu. Sie tragen kein „neu“ mehr und halten „Alle als gelesen markieren“ nicht mehr aktiv.
- Meldet der Server eine abgelaufene Sitzung mit einem Fehlercode statt mit einer Weiterleitung zur Anmeldung, meldet sich die App neu an und wiederholt den Abruf. Gelingt das nicht, zeigt die Verbindungsanzeige die Sitzung als abgelaufen, statt die Seiten still leer zu lassen.
- Anmeldung: die Sitzung richtet sich nach der Uhr des Servers. Geht die Uhr des Geräts falsch, meldet die App nicht mehr zu früh ab oder arbeitet mit einer schon abgelaufenen Sitzung weiter.
- Anmeldung: ein kurzes Funkloch meldet nicht mehr ab. Kennt der Server die Sitzung nicht mehr, meldet die App still neu an.
- Verbindung von Hand wiederherstellen führt nicht mehr auf den Anmeldebildschirm, solange nur das Netz fehlt. Und ein Tippen auf Anmelden ohne Passwort löscht nicht länger die Zugangsdaten des Kontos: der Knopf bleibt grau, bis Benutzername und Passwort da sind, und ein Konto bleibt auch ohne gespeichertes Passwort in der Kontoliste.
- Lief die Sitzung ab, während das Handy gesperrt war, half auch mehrfaches Neuverbinden nicht mehr und irgendwann stand der Anmeldebildschirm da. Die App meldet sich jetzt mit den gespeicherten Zugangsdaten neu an, so wie es bisher nur der Wechsel auf ein anderes Konto und zurück tat.
- Klassenbuch und Hausaufgaben: die Tönung jeder zweiten Zeile bleibt in der Liste. Beim Scrollen schob sie sich bisher als Streifen hinter die Fächer-Filter darüber.

### Intern

- Die Versionshinweise veröffentlichter Versionen sind festgeschrieben: ein Test schlägt fehl, sobald sich ihr Text nachträglich ändert.
- Android-Build auf das im Android-Build-Plugin eingebaute Kotlin umgestellt; dafür Sentry sowie die Android-Teile von Bildauswahl und Einstellungsspeicher auf Fassungen angehoben, die das unterstützen.
- Debug-Builds gehen per WLAN in einem Lauf auf alle gekoppelten Geräte, ohne die App vorher zu löschen; Anmeldung und gespeicherter Stand bleiben dabei erhalten.

## 1.3.1 — 2026-09-14

### Neue Funktionen

- Jede Seite zeigt in der Titelzeile, ob die App gerade mit dem Server spricht. Fehlendes Netz und abgelaufene Sitzung werden dabei unterschieden; ein Tippen darauf stellt die Verbindung wieder her oder meldet neu an.
- Ist der letzte Abruf länger her, steht sein Zeitpunkt in der Titelzeile, statt alte Daten wie frische aussehen zu lassen.
- Mitteilungen: was noch eine Antwort verlangt, ist schon in der Liste gekennzeichnet — „Bestätigung offen“ für die Unterschrift mit Namen, „Zustimmung offen“ für Zustimmen oder Ablehnen.
- Einstellungen → Anmeldung: Auf Wunsch bleibt die App beim Wechsel zwischen Konten auf der geöffneten Seite, statt jedes Mal zum Merkheft zurückzukehren. Die Einstellung gilt für alle Konten; ohne sie bleibt alles wie bisher.
- Klassenbuch: zwei neue Darstellungen unter Einstellungen → Klassenbuch — Karten mit Stunde, Uhrzeit, Fach, Eintrag und Lehrperson, oder eine Zeitleiste, auf der vorbeigegangene Stunden grün gefüllt sind. Die Zeitleiste gibt es bei Anordnung nach Tagen.
- Hausaufgaben, Absenzen und Bewertungen lassen sich ebenfalls als Karten statt als Liste zeigen. Die Hausaufgaben haben dafür eigene Einstellungen und übernehmen beim ersten Start die Anordnung, die bisher für beide Seiten galt.
- Einstellungen → Aussehen: „Hintergrund in Akzentfarbe“ lässt sich ausschalten. Dann sind alle Seiten weiß, im dunklen Modus dunkel; Knöpfe, Überschriften und Markierungen behalten die Akzentfarbe. Voreingestellt bleibt der Hintergrund wie bisher.

### Verbesserungen

- Die Verbindungsanzeige in der Titelzeile ist jetzt immer eine Wolke, deren Form und Farbe den Zustand zeigt: verbunden, noch nichts geladen, veraltet, wird aufgebaut, kein Netz oder Sitzung abgelaufen. Ohne Netz erscheint zusätzlich für zwei Sekunden eine kurze Meldung. Der dauerhafte Hinweis „Offline-Modus aktiv …“ unten auf den Seiten entfällt.
- Querformat: das Merkheft stellt Monatsraster und Tagesansicht nebeneinander, statt beides übereinander zu quetschen.
- Querformat: Seitenüberschrift, Kopfzeilen und Abstände fallen kleiner aus, damit mehr vom Inhalt bleibt.
- Querformat: auf dem Handy bleibt die Seitenleiste eingeklappt, statt ein Drittel der Breite zu belegen.
- Mitteilungen: selbst gesendete Mitteilungen tragen in der Liste die Kennzeichnung „Gesendet“ und sind so von empfangenen zu unterscheiden.
- Mitteilungen: der Knopf zum Bestätigen steht in einem abgesetzten Bereich über die volle Breite und sagt, solange er grau ist, dass noch der Name fehlt.
- Kalender-Wochenansicht: das Fach steht in jeder Kachel gleich groß, Lehrer kursiv, höchstens drei Zeilen und mit Abstand zum Rand; der Raum bleibt der Detailansicht vorbehalten.
- Benachrichtigungen: ein Tippen auf die Benachrichtigung öffnet die Mitteilung oder Bewertung. Der Haken rechts markiert sie als gelesen, ohne sie zu öffnen — bei Mitteilungen gilt dann auch die Mitteilung selbst als gelesen.
- Klassenbuch und Hausaufgaben: in der Liste ist jede zweite Zeile eingefärbt, damit lange Einträge nicht ineinanderlaufen. Jeder Tag beginnt mit einem farbigen Band; seine Überschrift bleibt beim Scrollen oben stehen, bis der nächste Tag sie ablöst.

### Fehlerbehebungen

- Herunterziehen zum Aktualisieren funktioniert auf allen Seiten mit Daten vom Server — Merkheft in jeder Ansicht und auch leer, Kalender, Bewertungen, Absenzen, Zeugnis, Mitteilungen, Klassenbuch, Hausaufgaben, Unterrichtsmaterialien, Benachrichtigungen und Profil. Der Kreisel bleibt stehen, bis die Daten da sind; ohne Verbindung wird sie zuerst wiederhergestellt.
- Merkheft: Wochen- und Monatsansicht zeigen auch vergangene Einträge, ohne dass dafür erst in der Listenansicht auf die Vergangenheit getippt werden muss.
- Merkheft: der Knopf „Neue Einträge“ führt in Wochen- und Monatsansicht zum Tag des Eintrags, statt nichts zu bewirken. Ein Tag, der wieder verlassen wird, gilt als gesehen; ist nichts Neues mehr übrig, verschwindet der Knopf.
- Querformat: Inhalte liegen nicht mehr unter der Navigationsleiste des Geräts, die dort am rechten Rand steht.
- Querformat: der Stundenplan in Kalender und Merkheft scrollt, statt die Stunden bis zur Unlesbarkeit zusammenzudrücken.
- Im Demo-Konto zeigt die Verbindungsanzeige die Verbindung als hergestellt, statt dauerhaft „noch nichts geladen“.
- Benachrichtigungen: eine gelesene Mitteilung nimmt keine Benachrichtigung zu einer Bewertung mehr mit, die zufällig dieselbe Nummer trägt.
- Kalender: die App stürzt nicht mehr ab, wenn der Kalender geöffnet ist, während die Daten eines Kontos neu geladen werden — etwa beim Kontowechsel. Ohne gewählte Woche zeigt er die aktuelle.
- Nach längerer Zeit im Hintergrund beendet sich die App beim erneuten Anmelden nicht mehr, wenn der Server statt der Startseite des Kontos eine andere Seite liefert. Die Anmeldung gilt dann als fehlgeschlagen.
- Bewertungen: die App stürzt nicht mehr ab, wenn Bewertungen geladen werden, bevor die Anmeldung abgeschlossen ist. Ein fehlgeschlagener Abruf blockiert auch nicht mehr das andere Semester.
- Merkheft und Bewertungen: bricht das Laden ab, dreht sich die Ladeanzeige nicht mehr endlos weiter.

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
- Der Name, mit dem eine Mitteilung unterschrieben wurde, steht beim nächsten Mal schon im Feld

### Fehlerbehebungen

- Ein geöffneter Link löscht nicht mehr die gespeicherten Zugangsdaten des gerade verwendeten Kontos
- Beim Anmelden eines zweiten Kontos bleibt das erste erhalten
- Die App bleibt sichtbar, wenn sie über einen Link aus dem Hintergrund geholt wird
- Merkheft: die unterste Zeile der Kalenderansichten liegt nicht mehr unter der Navigationsleiste des Geräts
- Merkheft: eine noch ladende Woche antippen verwirft die Auswahl nicht mehr
- Ein Schlüsselspeicher, der sich nicht mehr lesen lässt, wird wieder gemeldet und geleert, statt die Anmeldung stumm scheitern zu lassen
- Übersehene deutsche Texte in Meldungen und Diensten sowie ein falsches Anführungszeichen übersetzt
- Eine Bestätigung, die den Server nicht erreicht, wird als solche gemeldet, statt den Knopf stumm zu sperren

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
