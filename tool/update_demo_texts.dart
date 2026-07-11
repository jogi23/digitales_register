// Replaces demo texts in assets/demo/capture.json.
// Run from repo root: dart run tool/update_demo_texts.dart

import 'dart:convert';
import 'dart:io';

// ── Grade descriptions by gradeId ────────────────────────────────────────────
const gDesc = <int, String>{
  // ── Religion (subject 86) ──
  46421: 'Hinter jedem Türchen steckt ein eigener Gedanke – das zeigt echte Auseinandersetzung mit dem Thema Advent.',
  54597: 'Das Gleichnis wird flüssig wiedergegeben und der Kern klar getroffen: Helfen ohne Bedingungen.',
  32431: 'Die sieben Schöpfungstage werden in richtiger Reihenfolge benannt und mit eigenen Naturbeobachtungen verknüpft.',
  33416: 'Text und Melodie des Lieds sind gut verankert. Max singt mit sicherer Intonation und deutlicher Aussprache.',
  // ── NatGeGeo (subject 97) ──
  65392: 'Der Steckbrief ist klar gegliedert, vollständig und zeigt treffende Informationen. Die Zeichnung ist erkennbar.',
  76237: 'Das Pflanzentagebuch dokumentiert den Wachstumsverlauf sorgfältig. Skizzen sind aussagekräftig, Beobachtungen gut formuliert.',
  59015: 'Das Tagebuch wurde über zwei Wochen konsequent geführt. Temperaturen und Symbole stimmen; Zusammenhänge werden treffend erkannt.',
  57819: 'Das Experiment wird sorgfältig durchgeführt und vollständig protokolliert. Max leitet eine verständliche Erklärung ab.',
  44993: 'Alle drei Pflanzen sind korrekt abgebildet und benannt. Max hat spontan einen eigenen Fund aus dem Garten mitgebracht.',
  80010: 'Max erklärt das Prinzip der Seife klar in eigenen Worten und führt das Experiment korrekt durch.',
  44718: 'Monate und Jahreszeiten werden in richtiger Reihenfolge geordnet. Typische Merkmale werden korrekt zugeordnet.',
  48469: 'Volle Stunden werden sicher erkannt. Max zeigt seinen Tagesablauf anhand der Uhr – flüssig und verständlich.',
  // ── Musik (subject 90) ──
  48427: 'Das Rhythmusstück wird mit Körperspannung und gutem Puls vorgeführt. Koordination stimmt über die gesamte Länge.',
  75435: "Max beschreibt Klang und Stimmung treffend: 'Das klingt wie ein fliegender Vogel.' Sehr genaue Beobachtung.",
  88504: 'Alle drei Lieder werden textlich sicher und mit Freude vorgetragen. Intonation und Melodieführung sind sehr gut.',
  // ── Mathematik (subject 85) ──
  54118: 'Subtraktionsaufgaben bis 20 werden mit sicherer Strategie gelöst. Auch Aufgaben über den Zehner gelingen fast fehlerlos.',
  38657: 'Alle vier Körper werden sicher erkannt und benannt. Ecken, Kanten und Flächen werden treffend beschrieben.',
  16006: 'Additionsaufgaben bis 20 werden flüssig und weitgehend korrekt bearbeitet. Strategien sind gut verinnerlicht.',
  93320: 'Gemischte Aufgaben werden größtenteils korrekt gelöst. Das Überqueren des Zehners klappt zunehmend sicher.',
  13278: 'Max erklärt seine Strategie klar und nachvollziehbar. Er nimmt Rückmeldungen auf und fragt gezielt nach.',
  93886: 'Subtraktionen bis 10 werden schnell und fehlerfrei abgerufen. Keine Hilfsmittel mehr notwendig.',
  87397: 'Abzüge vom Zehner werden zuverlässig und ohne Zählen gelöst. Die Strategie ist gut automatisiert.',
  14165: 'Aufgaben mit –0 und –1 werden sofort richtig beantwortet. Max erklärt die Regel klar und verständlich.',
  46048: 'Alle Additionsstrategien werden sicher abgerufen. Max erklärt seinen Weg klar; schwierige Paare kommen mit kurzem Überlegen.',
  28131: "Die Strategie 'Kraft der 5' ist gut verstanden. Max zeigt am Rechenrahmen anschaulich, wie er Fünfergruppen nutzt.",
  42953: 'Max zählt von 20 rückwärts flüssig und fehlerfrei. Die Übertragung auf Subtraktionsaufgaben gelingt gut.',
  79352: 'Alle Verdopplungen bis 10+10 werden automatisiert abgerufen. Auch 8+8 und 9+9 kommen ohne Zögern.',
  44973: 'Max versteht Addition als Zusammenfassen von Mengen und stellt Aufgaben mit Material und Zeichnung korrekt dar.',
  75612: 'Alle geprüften Bereiche werden sicher und vollständig beherrscht. Sehr gute Leistung am Ende des ersten Semesters.',
  89818: 'Zahlenpaare zur 10 werden blitzschnell und sicher erkannt. Die Aufgaben sind vollständig automatisiert.',
  80697: 'Additionsaufgaben bis 10 werden sicher und ohne Hilfsmittel abgerufen. Gutes Tempo, richtige Ergebnisse.',
  21395: '+0 und +1 werden sofort und korrekt beantwortet. Das Verständnis der Rechenregeln ist klar vorhanden.',
  // ── KuTE (subject 89) ──
  38221: 'Die Monotypie zeigt klare Strukturen und mutige Farbkombinationen. Max überträgt den Abzug konzentriert und präzise.',
  30379: 'Das Weben ist gleichmäßig, das Muster hält gut. Max arbeitet ruhig und mit sichtbarer Ausdauer.',
  20328: 'Der Scherenschnitt ist präzise ausgeführt; Konturen sind scharf und die Symmetrie gut eingehalten.',
  58520: 'Die Dose ist kreativ und sorgfältig dekoriert. Max setzt Materialien gezielt ein und hält die Technik gut ein.',
  24371: 'Das Tier ist dreidimensional und erkennbar modelliert. Proportionen und Oberflächengestaltung sind ausdrucksstark.',
  88104: 'Kreise und Linien sind bewusst gesetzt; die Farbwahl ist mutig und ausgewogen. Ein ausdrucksstarkes Bild.',
  44522: 'Verschiedene Materialien werden gezielt eingesetzt. Druckbilder sind klar erkennbar; Farben sorgfältig aufgetragen.',
  // ── Italiano (subject 94) ──
  42087: 'Alle Farben werden auf Italienisch sicher und korrekt ausgesprochen. Max reagiert auf farbige Gegenstände spontan.',
  // ── Deutsch (subject 84) ──
  10851: 'Die Wörter werden in die richtige Satzreihenfolge gebracht und klar aufgeschrieben. Satzstruktur ist gut verstanden.',
  44671: 'Die Abschrift ist vollständig, leserlich und weitgehend fehlerfrei. Buchstabenform und Abstände stimmen gut.',
  80284: 'Der Satz passt treffend zum Bild. Groß- und Kleinschreibung sowie Satzzeichen sind korrekt gesetzt.',
  82357: 'Detailfragen zur Geschichte werden treffend und vollständig beantwortet. Max hört konzentriert zu.',
  85674: 'Jj wird in Silben und Wörtern sicher erkannt und korrekt gelesen. Das Leseblatt wird flüssig vorgetragen.',
  19116: 'Alle angesagten Buchstaben und Wörter werden korrekt und leserlich aufgeschrieben.',
  46434: 'Die Übungen sind vollständig, sauber und weitgehend fehlerfrei. Buchstabenform ist altersgerecht gut.',
  52504: 'Alle Buchstaben und Lernwörter werden fehlerfrei aufgeschrieben. Max hört aufmerksam zu und schreibt klar.',
  51347: 'ch wird in verschiedenen Positionen sicher erkannt und korrekt gelesen. Gutes Tempo beim Vorlesen.',
  37869: 'Pp wird in Silben und Wörtern sicher erkannt. Vorlesen deutlich und ohne Stocken.',
  25014: 'Silben und Wörter mit Ff werden korrekt erlesen. Klares, flüssiges Vorlesen.',
  80539: 'Die Lesehausaufgabe wird regelmäßig und sorgfältig erledigt. Lesefluss verbessert sich sichtbar.',
  30032: 'Anweisungen werden korrekt und vollständig ausgeführt. Max hört aufmerksam zu und handelt sofort.',
  31174: 'Alle angesagten Buchstaben und Wörter werden korrekt und leserlich aufgeschrieben.',
  84364: 'Die Lesehausaufgabe wird mit Engagement erledigt. Ausdruck und Lesefluss haben sich deutlich verbessert.',
  // ── Sport (subject 87) ──
  70217: 'An Geräten bewegt sich Max sicher und mit Freude. Rollen, Klettern und Balancieren werden koordiniert ausgeführt.',
  39871: 'Max hält Regeln ein und spielt fair. Im Staffellauf zeigt er gutes Tempo und saubere Übergaben.',
  56566: 'Konstant engagiertes Verhalten im Sportunterricht. Aufgaben werden zügig aufgenommen und mit Begeisterung ausgeführt.',
  76784: 'Max übernimmt im Team Verantwortung. Beim Hindernislauf hat er spontan einem Mitschüler geholfen.',
  30730: 'Passen, Fangen und Prellen gelingen mit wachsender Sicherheit. Ballgefühl und Koordination entwickeln sich stetig.',
  // ── Weitere Bewertungen (aus entry/getGrade) ──
  42098: 'Fingerbilder werden schnell erkannt; Max nennt die Anzahl direkt ohne Abzählen.',
  39256: 'Das Werk ist kreativ und sorgfältig ausgeführt; hohes Engagement beim Arbeiten sichtbar.',
  98696: 'Offene Auseinandersetzung mit dem Thema; persönliche Gedanken klar und verständlich formuliert.',
  81482: 'Präzise Faltarbeit; alle Knicke sitzen exakt und das Ergebnis ist ordentlich.',
  65302: 'Vergleichszeichen werden korrekt eingesetzt; Zahlenbeziehungen sicher erkannt.',
  13905: 'Das Mengenbild der 5 ist gut verankert; Aufgaben werden sicher und zügig gelöst.',
  22280: 'Geometrische Formen werden sauber geschnitten und korrekt benannt.',
  40495: 'Vorgänger, Nachfolger und Zahlenvergleich gelingen sicher und flüssig.',
  88907: 'Additionsaufgaben werden selbstständig und korrekt bearbeitet; gutes Arbeitstempo.',
  13478: 'Aktive Teilnahme am Sportunterricht; Regeln werden eingehalten, andere respektvoll behandelt.',
  83563: 'Buchstaben und Silben werden korrekt gelesen; gutes Tempo beim Vorlesen.',
  36062: 'Wörter werden sicher und vollständig erlesen; Textverständnis ist vorhanden.',
};

// ── Competence descriptions by "gradeId|typeName" ────────────────────────────
const cDesc = <String, String>{
  '93810|Zahl: Orientierung im Zahlenraum 12': 'Zahlen bis 12 werden sicher erkannt und der Reihe nach geordnet.',
  '39256|Kreative Gestaltung': 'Kreative Ideen werden eigenständig umgesetzt und ansprechend präsentiert.',
  '98696|Einzigartigkeit': 'Das Thema wurde mit Offenheit und persönlichem Engagement erarbeitet.',
  '81482|Geometrie': 'Geometrische Formen werden korrekt erkannt und präzise dargestellt.',
  '40495|Zahl: zählen, vergleichen und ordnen': 'Zahlenreihen werden sicher beherrscht und zuverlässig angewendet.',
  '76237|Auseinandersetzung mit einem persönlichen Thema': 'Das Thema wurde selbstständig erarbeitet und anschaulich aufbereitet.',
  '13478|Bewegungs- und Sportspiele: Sportspielen teil': 'Spielregeln werden eingehalten; das Spiel wird kooperativ mitgestaltet.',
  '83563|Lesen: die Buchstaben erkennen und richtig lesen': 'Buchstaben werden sicher erkannt und korrekt gelesen.',
  '36062|Lesen: Wörter lesen und verstehen': 'Wörter werden korrekt gelesen und der Inhalt wird gut verstanden.',
  '46421|Heftführung': 'Hefteinträge sind vollständig, sauber und gut gestaltet.',
  '54597|Daniel in der Löwengrube': 'Die Botschaft der Geschichte wurde erkannt und verständlich wiedergegeben.',
  '32431|Mündliche Mitarbeit': 'Regelmäßige und wertvolle Beteiligung am Unterrichtsgespräch.',
  '33416|Mündliche Mitarbeit': 'Beiträge sind passend und zeigen ein gutes Verständnis der Themen.',
  '65392|Auseinandersetzung mit einem persönlichen Thema': 'Gute Grundlagen sind vorhanden; diese werden weiter ausgebaut.',
};

// ── Grade name overrides by gradeId (subject_detail + getGrade) ──────────────
const gName = <int, String>{
  // ── Religion ──
  46421: 'Adventkalender: Gestalten und Nachdenken',
  54597: 'Gleichnis vom barmherzigen Samariter',
  32431: 'Schöpfungserzählung: Sieben Tage nacherzählen',
  33416: 'Gottesdienst: Lied gemeinsam einstudieren',
  // ── NatGeGeo ──
  65392: 'Steckbrief: Mein Lieblingstier vorstellen',
  76237: 'Pflanzenwachstum: Kresse-Tagebuch führen',
  59015: 'Wettertagebuch: Zwei Wochen beobachten',
  57819: 'Schwimmen und Sinken: Experiment und Protokoll',
  44993: 'Frühblüher-Plakat: Schneeglöckchen, Krokus, Tulpe',
  80010: 'Hände waschen: Experiment zur Seifenwirkung',
  44718: 'Monate und Jahreszeiten ordnen und benennen',
  48469: 'Uhr lesen: volle und halbe Stunden erkennen',
  // ── Musik ──
  48427: "Bodypercussion: Rhythmusstück 'Boom cha'",
  75435: "Vivaldi: 'Der Frühling' – Musik beschreiben",
  88504: 'Faschingslieder: Drei Stücke einstudieren',
  // ── Mathematik ──
  54118: 'Lernkontrolle: Subtrahieren bis 20',
  38657: 'Geometrische Körper erkennen und benennen',
  16006: 'Lernkontrolle: Addieren bis 20',
  93320: 'Minus-Training: Gemischte Aufgaben bis 20',
  13278: 'Mathekonferenz: Lösungsweg vorstellen',
  93886: 'Subtraktion bis 10: Kärtchenabfrage',
  87397: 'Abzug vom Zehner: 10er-Minusaufgaben',
  14165: 'Aufgaben mit –0 und –1: Strategie kennen',
  46048: '1+1-Kärtchen: Additionsstrategien festigen',
  28131: 'Kraft der 5: Additionsstrategien kennenlernen',
  42953: 'Rückwärts zählen von 20 bis 0',
  79352: 'Verdopplungsaufgaben bis 10+10 auswendig',
  44973: 'Addition als Mengenzusammenfassen verstehen',
  75612: 'Lernstandserhebung: Was ich alles kann',
  89818: 'Ergänze auf 10: Zahlenpaare kennen',
  80697: 'Handaufgaben: Addieren bis 10',
  21395: '+0 und +1: Einfachstes Addieren',
  // ── KuTE ──
  38221: 'Druckgrafik: Monotypie mit Acrylfarbe',
  30379: 'Fadenweberei: Papierweben am Rahmen',
  20328: 'Scherenschnitt und Collagebild',
  58520: 'Alltagsobjekte gestalten: Dosen dekorieren',
  24371: 'Plastizieren: Tier aus Salzteig',
  88104: 'Malen nach Kandinsky: Kreise und Quadrate',
  44522: 'Naturmaterialien drucken: Blatt, Rinde, Kork',
  // ── Italiano ──
  42087: 'I colori: Farben auf Italienisch benennen',
  // ── Deutsch ──
  10851: 'Schüttelsatz in richtige Reihenfolge bringen',
  44671: 'Abschrift: Text sauber und vollständig abschreiben',
  80284: 'Satzschreiben: Einen Satz zum Bild erfinden',
  82357: 'Zuhören: Geschichte verstehen und antworten',
  85674: 'Buchstabe Jj: Lesen auf Silben- und Wortebene',
  19116: 'Buchstabendiktat: Mitlaute und Lernwörter',
  46434: 'Heftübung: Buchstaben sauber nachspuren',
  52504: 'Buchstabendiktat: Vokale und Anlaute',
  51347: 'Buchstabe ch: Erkennen und Lesen',
  37869: 'Buchstabe Pp: Lesezettel vorlesen',
  25014: 'Buchstabe Ff: Lesezettel vorlesen',
  80539: 'Lesehausaufgabe: Lesepass Stufe 3',
  30032: 'Zuhören: Anweisungen verstehen und ausführen',
  31174: 'Buchstabendiktat: Grundlaute und einfache Sätze',
  84364: 'Lesehausaufgabe: Lesepass Stufe 5',
  // ── Sport ──
  70217: 'Geräteturnen: Rollen, Balancieren, Klettern',
  39871: 'Spielturnen: Treibball, Staffel, Fangen',
  56566: 'Bewegungsbeobachtung: April/Mai',
  76784: 'Kooperationsspiele: Gemeinsam Aufgaben lösen',
  30730: 'Ballkontrolle: Prellen, Passen, Fangen',
  // ── Mathematik (nur subject_detail, nicht in getGrade) ──
  93810: 'Zahlen ordnen und vergleichen',
  // ── Weitere Bewertungen (aus entry/getGrade) ──
  42098: 'Fingerbilder: Mengen schnell erfassen',
  39256: 'Kreative Ausführung: Werkbeurteilung',
  98696: 'Mündliche Beteiligung am Unterrichtsgespräch',
  81482: 'Faltarbeit nach geometrischer Anleitung',
  65302: 'Zahlen vergleichen: Zeichen <, >, =',
  13905: 'Kraft der 5: Mengenstruktur erkennen',
  22280: 'Falten und Schneiden: Geometrische Figuren',
  40495: 'Zahlenreihe: Vorwärts, rückwärts, Vergleich',
  88907: 'Additionsaufgaben selbstständig bearbeiten',
  13478: 'Sportbeobachtung: Mitarbeit und Regelverhalten',
  83563: 'Lesecheck: Buchstaben und Silben',
  36062: 'Lesen: Wörter und kurze Texte erfassen',
};

// ── Extra grade titles only present as dashboard "grade" items ────────────────
// (gradeIds NOT covered by gName above, used for the Merkheft/Dashboard subtitle)
const gradeDashExtra = <int, String>{
  // Deutsch
  23947: 'Lesehausaufgabe: Lesezettel zum Mm',
  25860: 'Lesehausaufgabe: Lesezettel zum Ss',
  38864: 'Lesehausaufgabe: Lesezettel zum Tt',
  53309: 'Nikolausgedicht auswendig vortragen',
  69177: 'Lesehausaufgabe: Wörter mit Rr lesen',
  71213: 'Lesehausaufgabe: Leseblatt Seite 1',
  77391: 'Ansage: Mm, Ii, Aa, Oo, Ss, Uu',
  // NatGeGeo
  22899: 'Lagebegriffe: links/rechts, oben/unten',
  58944: 'Tiere im Winter: Überwinterung',
  71953: 'Verkehrserziehung: sicher unterwegs',
  // Religion
  19305: 'Heftführung: Religionsheft',
  84847: 'Das Kreuzzeichen kennenlernen',
  // KuTE
  24322: 'Selbstporträt für den Einband',
  26483: 'Herbstbild: Der Fuchs',
  42591: 'Heft-Einbände gestalten',
  87128: 'Weihnachtsgeschenk basteln',
  97684: 'Schattenbilder gestalten',
  98039: 'Winterbild: Schneekugel',
  // Mathematik
  10942: 'Zahlen zerlegen an der Zahlenreihe',
  22704: 'Lernkontrolle: Würfelbilder und Strichlisten',
  26828: 'Zahlen zerlegen bis 10',
  56438: 'Orientierung im Zahlenraum 10',
  63354: 'Wendekärtchen: mündliche Überprüfung',
  93810: 'Orientierung in der Zahlenreihe bis 20',
  96474: 'Addition im Zahlenraum 10: Zerlegen',
  // Bewegung und Sport
  42493: 'Sportbeobachtung: November/Dezember',
  44741: 'Geräteübungen mit Kleinmaterial',
  // Musik
  17100: 'Rhythmen mit Orff-Instrumenten',
  95180: 'Lieder singen: Jahreszeiten',
};

// ── Observation notes (subject_detail) by observationId ─────────────────────
const obsNote = <int, String>{
  // Religion (subject 86)
  31417: 'Mündliche Mitarbeit März/April:\n'
      'Beim Thema Ostertraditionen hat Max einen Brauch aus seinem Familienumfeld eingebracht – eine unbekannte Variante, die die ganze Klasse überraschte.\n'
      'Er hört anderen aufmerksam zu und meldet sich mit gezielten Fragen.\n'
      'Hausaufgaben werden vollständig und ordentlich mitgebracht.',
  66155: 'Gesprächsnotiz Elternkontakt (14.04.2026):\n'
      'Der Vater von Max rief an, um nach der Erstkommunionvorbereitung zu fragen.\n'
      'Er berichtete, dass Max zu Hause Lieder aus dem Religionsunterricht singt und Fragen zu Bibeltexten stellt.\n'
      'Vereinbart: Gebet für den Schulgottesdienst am 28. Mai gemeinsam einüben.',
  76542: 'Beobachtung Januar/Februar:\n'
      "Bei der Erarbeitung des Gleichnisses vom verlorenen Sohn hat Max eine unerwartete Parallele gezogen: 'Das ist wie wenn jemand lange böse war und dann trotzdem wieder gemocht wird.'\n"
      'Diese Eigeninterpretation zeigt reifes Denken und echtes Verständnis.\n'
      'Mündliche Mitarbeit konstant gut.',
  // NatGeGeo (subject 97)
  95909: 'Sozialverhalten Schuljahr 2025/26:\n'
      'In der Klasse ist Max eine verlässliche Stütze im sozialen Gefüge.\n'
      'Als zwei Kinder beim Kooperationsspiel in Streit gerieten, griff er ein und schlug einen Kompromiss vor – ohne Aufforderung.\n'
      'Auf dem Pausenhof sucht er regelmäßig Kontakt zu Neulingen und Einzelgängern.',
  // Mathematik (subject 85)
  65333: 'Beobachtung 11.11.2025:\n'
      'Beim Freiarbeitsblock hat Max entdeckt, dass er Punkte schneller zählen kann, wenn er sie in Fünfergruppen anordnet.\n'
      'Er hat diese Idee spontan entwickelt, an die Tafel gezeichnet und der Klasse erklärt.\n'
      'Solche Momente selbstentdeckten Lernens sind selten und wertvoll.',
  59009: 'Arbeitsverhalten September/Oktober:\n'
      'Max gibt bei schwierigen Aufgaben nicht schnell auf – er versucht zunächst, den letzten Schritt zu wiederholen.\n'
      'Das Arbeitstempo ist gleichmäßig gut; die meisten Aufgaben werden im Zeitrahmen erledigt.\n'
      'Ziffern in der Heftführung sind klar und leserlich; Seiten ordentlich gestaltet.',
  // Italiano (subject 94)
  92397: 'Beobachtung Italiano:\n'
      "Beim Rollenspiel 'al mercato' hat Max spontan Sätze gebildet, die über den eingeübten Dialog hinausgingen.\n"
      'Er verwendete Farben und Mengenangaben selbstständig und korrekt.\n'
      'Wortschatz zu Schulmaterialien und Farben ist gut gefestigt.',
  86484: 'Elternkontakt (18.03.2026):\n'
      'Der Vater von Max berichtete, dass Max zu Hause manchmal Sätze auf Italienisch einbaut und Lieder aus dem Unterricht singt.\n'
      'Vereinbart: kurze tägliche Übungen mit der Sprach-App; Interesse am Fach ist vorhanden.\n'
      'Nächstes Gespräch: Sprechstunde im Mai.',
  91959: 'Beobachtung KuTE / Italiano:\n'
      'Max hat beim Basteln von Vokabelkärtchen für Italiano deutlich mehr Zeit investiert als vorgesehen.\n'
      'Er illustrierte die Kärtchen freiwillig, überarbeitete sie einmal und präsentierte das Ergebnis der Klasse.\n'
      'Diese Ausdauer und Sorgfalt bei kreativen Aufgaben ist bemerkenswert.',
  // Deutsch (subject 84)
  19358: 'Lernberatung 12.02.2026:\n'
      'Stärken: Buchstaben sicher erkennen; flüssiges Lesen auf Silbenebene; Heftführung ordentlich und vollständig.\n'
      'Förderbereich: selbstständiges Satzschreiben weiter üben; Nomen mit Großschreibung im Fließtext festigen.\n'
      'Vereinbarung: täglich 10 Minuten Lesen; schwierige Wörter mit Kärtchen wiederholen.',
  84341: "Beobachtung 07.01.2026:\n"
      "Max hat beim Üben des Buchstabens 'd' selbst bemerkt, dass er ihn manchmal mit 'b' verwechselt.\n"
      "Er entwickelte ein eigenes Merkbild ('d wie Dach') und zeichnete es freiwillig an die Tafel.\n"
      'Diese Fähigkeit zur Selbstreflexion ist für sein Alter bemerkenswert.',
  86622: 'Wichtige Info für Eltern:\n'
      'Bitte bis Montag, 15. April, mitgeben:\n'
      '– Unterschriebenes Ausflugformular (Bibliotheksbesuch, 22. April)\n'
      '– Fahrtbeitrag 2,00 € im beschrifteten Kuvert',
  94012: 'Elternkontakt (07.04.2026):\n'
      'Die Mutter berichtete, dass Max zu Hause freiwillig liest und Bücher aus der Schulbibliothek mit nach Hause nimmt.\n'
      'Besprochen: welche Bücher für sein Niveau am besten passen.\n'
      "Vereinbart: Bücher der Stufe 'Lesepass 3' ausleihen; Themen Dinosaurier und Tiere bevorzugen.",
  52487: 'Arbeitsverhalten Jänner/Februar:\n'
      'Max arbeitet mit erkennbarer Freude am Lernstoff und fragt gezielt nach, wenn er etwas nicht versteht.\n'
      'Er gibt erst auf, wenn eine Aufgabe wirklich fertig ist.\n'
      'Die Handschrift hat sich deutlich verbessert: Buchstaben klar geformt, Zeilen werden gut eingehalten.',
};

// ── Dashboard observation subtitles by observationId ─────────────────────────
const obsSub = <int, String>{
  92397: 'Beim Rollenspiel bildet Max spontan Sätze auf Ital. – weit über den eingeübten Dialog hinaus.',
  19358: 'Lernberatung Feb.: Lesen auf Silbenebene gut; Fokus auf Satzschreiben und Nomen-Großschreibung.',
  31417: 'Mrz./Apr.: Max bringt unbekannte Osterbrauche ein – aufmerksam und fragend im Unterrichtsgesp...',
  84341: "Max entdeckt b/d-Verwechslung selbst und zeichnet Merkbild 'd wie Dach' für die Klasse.",
  95909: 'Kooperationsspiel: Max schlichtet Streit spontan und schlägt Kompromiss vor – ohne Aufforderung.',
  86622: 'Bis 15.4.: Ausflugformular unterschrieben und 2,00 € Fahrtbeitrag mitgeben.',
  66155: 'Apr.-Kontakt: Vater berichtet – Max singt Religionslieder zu Hause; Gebet für Gottesdienst einüben.',
  86484: 'Mrz.-Kontakt: Max baut Ital.-Sätze zu Hause ein; tägliche App-Übungen vereinbart.',
  65333: '11.11.: Max entdeckt Fünfergruppen-Strategie eigenständig und erklärt sie der Klasse.',
  94012: 'Apr.-Kontakt: Max liest freiwillig; Themen Dinosaurier/Tiere für Bibliotheksauswahl empfohlen.',
  76542: 'Jan./Feb.: Max interpretiert Gleichnis eigenständig – reifes Denken und echtes Verständnis.',
  91959: 'Max illustriert Vokabelkärtchen freiwillig, überarbeitet sie und präsentiert sie der Klasse.',
  59009: 'Sep./Okt.: Ausdauernd bei schwierigen Aufgaben; Heftführung ordentlich; Ziffern klar.',
  52487: 'Jan./Feb.: Fragt gezielt nach; gibt nicht auf; Handschrift deutlich verbessert.',
  72296: 'Heute war ein schwieriger Tag – morgen starten wir frisch neu. Du schaffst das, Max!',
  65461: 'Max arbeitet am zuverlässigsten, wenn Aufgaben klar formuliert und der Ablauf vorhersehbar sind.',
  37760: 'Kinderrat: Deine Beiträge im Kreisgespräch sind durchdacht und werden von allen gehört.',
  80686: 'Übe weiter +1/–1 an der Zahlenreihe – du bist schon fast am Ziel!',
  67422: 'Hefteinträge zu den Ziffern bitte bis Montag vollständig beenden.',
  55082: 'Max mostra entusiasmo nelle attività in italiano e impara velocemente.',
  39451: 'Nov./Dez.: Max meldet sich regelmäßig und bringt treffende Beiträge.',
  18392: 'Heft vollständig und ordentlich – Einträge klar strukturiert und sorgfältig.',
  54313: 'Kreative Aufgaben: Max arbeitet mit viel Energie und Eigeninitiative.',
  12757: 'Max, deine Naturbeobachtungen sind treffend – du fragst genau das Richtige!',
  85525: 'Ich bemühe mich, ordentlich zu arbeiten und Aufgaben sorgfältig zu erledigen.',
  66498: 'Sprechstunde: Lernentwicklung positiv; gemeinsam an Schreibtempo arbeiten vereinbart.',
  54473: 'Sep./Okt.: Max bringt sich aktiv ein und hält die Klassenregeln zuverlässig ein.',
  35112: 'Sep./Okt.: Mündliche Beteiligung gut; treffende Beiträge; selbstständiges Arbeiten.',
  34931: 'Max bemüht sich, konzentriert zu bleiben – bei langen Phasen fällt das manchmal noch schwer.',
  80292: 'Sep./Okt.: Meldet sich aktiv; konstruktive Beiträge; gute Fortschritte im Unterrichtsverhalten.',
  68800: 'Alle geübten Laute sicher benennen – ausgezeichnet! Weiter so fleißig!',
  63269: 'Alle geübten Laute den Bildern richtig zuordnen. Prima! Täglich weiterüben.',
  62565: 'ä, ö, ü, Au, Ei, Eu – alle Laute mit Bildern verbunden. Sehr gut!',
  10282: 'A, E, I, O, U – alle Laute erkannt und Bildern zugeordnet. Täglich weiterüben!',
  61173: '– zählt fehlerfrei bis 30; – zählt flexibel weiter; – zählt rückwärts von 10 sicher',
};

// ── Certificate: new Fachnoten (subject → [1.Semester, 2.Semester]) ──────────
const _certFachnoten = <String, List<String>>{
  'Bewegung und Sport': ['gut', 'sehr gut'],
  'Deutsch': ['ausgezeichnet', 'sehr gut'],
  'Italienisch': ['sehr gut', 'gut'],
  'KuTE': ['gut', 'ausgezeichnet'],
  'Mathematik': ['sehr gut', 'ausgezeichnet'],
  'Musik': ['ausgezeichnet', 'sehr gut'],
  'NatGeGeo': ['sehr gut', 'gut'],
  'Religion': ['gut', 'sehr gut'],
  'Verhalten': ['ausgezeichnet', 'sehr gut'],
  'Latein': ['gut', ''],
};

// ── Certificate: new Verhalten texts ─────────────────────────────────────────
const _verhText1 =
    'du bist mit viel Energie und Freude in das Schuljahr gestartet und hast '
    'schnell neue Freundschaften geschlossen. Im Unterricht meldest du dich '
    'regelmäßig und bringst überlegte Beiträge ein. Schriftliche Aufgaben '
    'erledigst du sorgfältig und mit sichtbarer Ausdauer. Manchmal fällt es '
    'dir noch schwer, die nötige Ruhe zu finden, wenn es um konzentriertes '
    'Einzelarbeiten geht – das gelingt dir aber bereits besser. Behalte deine '
    'Freude am Lernen und dein offenes Wesen, das schätzen wir sehr.';

const _verhText2 =
    'das zweite Schulhalbjahr zeigt, wie sehr du gewachsen bist – nicht nur '
    'im Wissen, sondern auch in deiner Persönlichkeit. Du übernimmst gerne '
    'Verantwortung, hilfst anderen spontan und bist ein geschätztes Mitglied '
    'unserer Klasse. Deine Neugier und deine Bereitschaft, Neues auszuprobieren, '
    'machen dich zu einem besonderen Lernenden. Beim selbstständigen Arbeiten '
    'zeigst du mehr Ausdauer als zu Beginn des Jahres. Wir freuen uns auf '
    'alles, was du im nächsten Schuljahr noch entdecken wirst.\n'
    'Deine Lehrerinnen';

// ── Certificate: competence rows [oldLabel, newLabel, sem1Stars, sem2Stars] ──
const _certCompetences = <List<Object>>[
  [
    'verhält sich höflich und respektvoll',
    'zeigt Respekt und Wertschätzung im Umgang mit anderen',
    3,
    4,
  ],
  [
    'hält sich an die Schulordnung',
    'kennt die Schulregeln und hält sie zuverlässig ein',
    4,
    4,
  ],
  [
    'reagiert bei Konflikten angemessen',
    'geht mit Konflikten besonnen und lösungsorientiert um',
    3,
    3,
  ],
  [
    'beteiligt sich aktiv und interessiert am Unterricht',
    'bringt sich engagiert und aufmerksam in den Unterricht ein',
    4,
    4,
  ],
  [
    'arbeitet sauber, fleißig und übersichtlich',
    'arbeitet geordnet, sorgfältig und mit gutem Überblick',
    3,
    4,
  ],
  [
    'arbeitet zielführend und ausdauernd, zeigt ein angemessenes Arbeitstempo',
    'bleibt bei der Arbeit fokussiert und hält ein angemessenes Tempo',
    3,
    3,
  ],
  [
    'kann sich im Mündlichen klar und verständlich ausdrücken',
    'drückt sich mündlich klar und für andere verständlich aus',
    4,
    4,
  ],
  [
    'versteht schriftliche sowie mündliche Arbeitsaufträge und setzt sie um',
    'versteht Aufgaben – schriftlich wie mündlich – und setzt sie um',
    3,
    4,
  ],
  [
    'erledigt Hausaufgaben zuverlässig und termingerecht',
    'gibt Hausaufgaben vollständig und pünktlich ab',
    4,
    3,
  ],
  [
    'erfasst neue Lerninhalte und kann sie wiedergeben',
    'nimmt neue Lerninhalte rasch auf und gibt sie treffend wieder',
    3,
    4,
  ],
  ['kann Gelerntes anwenden', 'wendet Erlerntes auf neue Situationen an', 4, 3],
  [
    'erkennt Zusammenhänge',
    'erkennt Verbindungen zwischen verschiedenen Themen',
    3,
    4,
  ],
  ['Arbeitsverhalten', 'Arbeitsverhalten', 3, 4],
  ['Lernverhalten', 'Lernverhalten', 4, 4],
];

// ── Certificate HTML patcher ──────────────────────────────────────────────────
String _patchCertificate(String html) {
  var h = html;
  const tdV = '<td class="padding-cell" style="vertical-align: top;">';
  const tdP = '<td class="padding-cell">';

  // 1. Fachnoten rows (except Verhalten – handled below)
  for (final entry in _certFachnoten.entries) {
    final subject = entry.key;
    if (subject == 'Verhalten') continue;
    final g1 = entry.value[0];
    final g2 = entry.value[1];
    final subjectEsc = RegExp.escape(subject);

    if (subject == 'Latein') {
      // Only 1 semester grade; 2nd <td> is empty
      final p = RegExp(
        '<tr>$tdV$subjectEsc</td>'
        "<td[^>]*><span class='green'>[^<]*</span></td>"
        '<td></td>'
        '<td[^>]*></td>'
        '<td></td></tr>',
      );
      h = h.replaceFirst(
        p,
        "<tr>${tdV}$subject</td>"
        "${tdV}<span class='green'>$g1</span></td>"
        '<td></td>${tdV}</td><td></td></tr>',
      );
    } else {
      final p = RegExp(
        '<tr>$tdV$subjectEsc</td>'
        "<td[^>]*><span class='green'>[^<]*</span></td>"
        '<td></td>'
        "<td[^>]*><span class='green'>[^<]*</span></td>"
        '<td></td></tr>',
      );
      h = h.replaceFirst(
        p,
        "<tr>${tdV}$subject</td>"
        "${tdV}<span class='green'>$g1</span></td>"
        '<td></td>'
        "${tdV}<span class='green'>$g2</span></td>"
        '<td></td></tr>',
      );
    }
  }

  // 2. Verhalten row (contains long free-text blocks)
  final verhG1 = _certFachnoten['Verhalten']![0];
  final verhG2 = _certFachnoten['Verhalten']![1];
  final verhPattern = RegExp(
    r'<tr><td class="padding-cell" style="vertical-align: top;">Verhalten</td>.*?</tr>',
    dotAll: true,
  );
  final newVerhRow = "<tr>${tdV}Verhalten</td>"
      "${tdV}<span class='green'>$verhG1</span> &middot; Lieber Max,\n$_verhText1 </td>"
      '<td></td>'
      "${tdV}<span class='green'>$verhG2</span> &middot; Lieber Max,\n$_verhText2\n</td>"
      '<td></td></tr>';
  h = h.replaceFirst(verhPattern, newVerhRow);

  // 3. Sterne competence rows
  for (final comp in _certCompetences) {
    final oldLabel = comp[0] as String;
    final newLabel = comp[1] as String;
    final sem1 = comp[2] as int;
    final sem2 = comp[3] as int;
    final p = RegExp(
      '<tr>$tdP${RegExp.escape(oldLabel)}</td>'
      r'<td class="padding-cell">\d von 4 Sterne</td>'
      r'<td></td>'
      r'<td class="padding-cell">\d von 4 Sterne</td>'
      r'<td></td></tr>',
    );
    h = h.replaceFirst(
      p,
      '<tr>$tdP$newLabel</td>'
          '${tdP}$sem1 von 4 Sterne</td>'
          '<td></td>'
          '${tdP}$sem2 von 4 Sterne</td>'
          '<td></td></tr>',
    );
  }
  return h;
}

// ── Attachment originalName replacements (real filenames → fictional) ─────────
const _attachNames = <String, String>{
  'Flex und Flo (bau) S. 36 und 37.png': 'Rechenwelt_Heft_S36-37.png',
  'Elternbrief zu den Nachbaraufgaben.pdf': 'Elternbrief_Mathematik.pdf',
  'Alltagsmathematik.pdf': 'Mathematik_Arbeitsblatt.pdf',
  'Liebe Eltern.docx': 'Elternbrief.docx',
};

/// Recursively walks [node] and replaces any [originalName] values found in
/// [_attachNames] with their anonymized equivalents.
int _anonymizeAttachNames(dynamic node) {
  var count = 0;
  if (node is Map) {
    if (node.containsKey('originalName')) {
      final cur = node['originalName'] as String?;
      if (cur != null && _attachNames.containsKey(cur)) {
        node['originalName'] = _attachNames[cur]!;
        count++;
      }
    }
    for (final v in node.values) count += _anonymizeAttachNames(v);
  } else if (node is List) {
    for (final v in node) count += _anonymizeAttachNames(v);
  }
  return count;
}

// ── Absence reason replacements by absence-group date ────────────────────────
// Only groups with a non-empty existing reason are updated.
const absReason = <String, String>{
  '2026-02-05': 'Scharlach (ärztlich bestätigt)',
  '2026-01-21': 'Zahnarzttermin (kieferorthopädisch)',
  '2025-12-18': 'Windpocken',
  '2025-12-16': 'Windpocken (Karenzzeit)',
  '2025-11-19': 'Vorsorgeuntersuchung U9 beim Kinderarzt',
  '2025-10-22': 'Schulimpfung Hepatitis A',
};

// ── Message subject replacements by messageId ────────────────────────────────
const msgSubjects = <int, String>{
  31241: 'Projektwoche "Natur und Wasser": 12.–16. Mai',
  42768: 'Unterrichtsausfall am Mittwoch, 3. Juni',
  16839: 'Lernberatungsgespräch – Terminvereinbarung',
  72991: 'Bitte bis Freitag: Foto für Schülerausweis',
  82684: 'Sportfest am Dienstag, 29. April',
  77621: 'Ausflug Naturpark: Freitag, 11. April',
  26341: 'Schuljahresabschlussfeier: Freitag, 27. Juni, 10 Uhr',
  47363: 'Elternabend: Donnerstag, 6. November, 19:30 Uhr',
  20993: 'Berichtigung: Buchcheck am Montag, nicht Freitag',
  31012: 'Buchcheck: Schulbücher auf Vollständigkeit prüfen',
  45755: 'Oktober-Brief: Erste Wochen in der 1A',
  77286: 'Halbjahreszeugnis: Ausgabe am 30. Jänner',
  34050: 'Kleider-Tauschbörse für Grundschüler',
  22021: 'Gesunde Jause: Bitte keine Süßigkeiten',
  39102: 'Herzlich willkommen in der 1A!',
};

// ── Message body texts by messageId (plain text; stored as Quill delta JSON) ─
const msgTexts = <int, String>{
  31241: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'vom 12. bis 16. Mai findet unsere Projektwoche "Natur und Wasser" statt.\n\n'
      'Die Kinder erkunden an drei Tagen das Bachbett in der Nähe der Schule und führen einfache '
      'Wasserexperimente durch. Am Freitag werden die Ergebnisse im Klassenzimmer ausgestellt.\n\n'
      'Bitte geben Sie Ihrem Kind mit:\n'
      '– Gummistiefel oder alte Schuhe\n'
      '– Wechselkleidung\n'
      '– Trinkflasche\n\n'
      'Wir freuen uns auf eine spannende Woche!\n\n'
      'Testfrau Christine\n',
  42768: 'Sehr geehrte Eltern und Erziehungsberechtigte,\n\n'
      'am Mittwoch, dem 3. Juni, findet eine schulinterne Lehrerkonferenz statt.\n\n'
      'Der Unterricht endet an diesem Tag um 11:30 Uhr. Bitte sorgen Sie dafür, dass Ihr Kind '
      'zu dieser Zeit abgeholt werden kann oder den Heimweg sicher alleine schafft.\n\n'
      'Die Nachmittagsbetreuung entfällt an diesem Tag.\n\n'
      'Vielen Dank für Ihr Verständnis.\n\n'
      'Leiter Demo\n',
  16839: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'im Rahmen der halbjährlichen Lernberatung lade ich Sie zu einem Gespräch über den '
      'Lernstand Ihres Kindes ein.\n\n'
      'Freie Termine:\n'
      '– Dienstag, 18. Februar, 15:00–17:30 Uhr\n'
      '– Mittwoch, 19. Februar, 14:30–17:00 Uhr\n\n'
      'Bitte tragen Sie sich über das digitale Register für einen Termin ein. Ein Gespräch '
      'dauert jeweils 15 Minuten.\n\n'
      'Ich freue mich auf den Austausch!\n\n'
      'Musterfrau Anna\n',
  72991: 'Liebe Eltern,\n\n'
      'bitte geben Sie Ihrem Kind bis Freitag, 14. März, ein aktuelles Passfoto mit in die Schule.\n\n'
      'Das Foto wird für den neuen Schülerausweis benötigt, der ab dem kommenden Schuljahr gilt.\n\n'
      'Größe: 3,5 × 4,5 cm. Bitte den Namen auf der Rückseite vermerken.\n\n'
      'Alternativ: Foto als JPEG per E-Mail ans Schulsekretariat schicken.\n\n'
      'Vielen Dank!\n'
      'Testfrau Christine\n',
  82684: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'am Dienstag, dem 29. April, findet das Schulsportfest statt.\n\n'
      'Die Kinder nehmen an verschiedenen Stationen teil: Weitsprung, Staffellauf, '
      'Balancierparcours, Ballzielwerfen. Im Vordergrund steht das gemeinsame Bewegen – '
      'eine Siegerehrung gibt es nicht.\n\n'
      'Bitte geben Sie mit:\n'
      '– Sportkleidung, die schmutzig werden darf\n'
      '– Sonnencreme (aufgetragen von zu Hause)\n'
      '– Trinkflasche\n\n'
      'Zuschauer sind von 10:00–12:00 Uhr herzlich willkommen!\n\n'
      'Testfrau Christine\n',
  77621: 'Liebe Eltern,\n\n'
      'am Freitag, dem 11. April, unternimmt die Klasse 1A einen Ausflug in den Naturpark.\n\n'
      'Wir erkunden einen Naturlehrpfad und lernen einheimische Tiere und Pflanzen kennen. '
      'Eine Waldpädagogin begleitet uns.\n\n'
      'Bitte mitbringen:\n'
      '– Festes Schuhwerk und wetterfeste Jacke\n'
      '– Jause und Trinkflasche\n'
      '– Unterschriebene Einverständniserklärung + 3,00 € im Kuvert\n\n'
      'Abfahrt: 8:15 Uhr pünktlich! Rückkehr: ca. 13:30 Uhr\n\n'
      'Testfrau Christine\n',
  26341: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'wir laden Sie herzlich zur Schuljahresabschlussfeier der Klasse 1A ein!\n\n'
      'Termin: Freitag, 27. Juni, 10:00 Uhr\n'
      'Ort: Schulaula, Erdgeschoss\n\n'
      'Die Kinder präsentieren Lieder, ein kleines Theaterstück und selbst gestaltete Werke.\n\n'
      'Im Anschluss gibt es einen kleinen Umtrunk im Schulhof.\n\n'
      'Mit herzlichen Grüßen\n'
      'Testfrau Christine\n',
  47363: 'Sehr geehrte Eltern und Erziehungsberechtigte,\n\n'
      'wir laden Sie herzlich zum Elternabend der Klasse 1A ein.\n\n'
      'Termin: Donnerstag, 6. November, 19:30 Uhr\n'
      'Ort: Klassenzimmer 1A, 1. Obergeschoss\n\n'
      'Themen:\n'
      '– Klassenelternrat wählen\n'
      '– Lehrplan und Jahresplanung\n'
      '– Hausaufgaben und Unterstützung zu Hause\n'
      '– Ausflüge und geplante Vorhaben\n\n'
      'Wir freuen uns auf einen guten Austausch!\n\n'
      'Testfrau Christine\n',
  20993: 'Liebe Eltern,\n\n'
      'in meiner gestrigen Mitteilung zum Buchcheck hat sich ein Fehler eingeschlichen.\n\n'
      'Der Buchcheck findet am MONTAG, 17. März, statt – nicht am Freitag wie angegeben.\n\n'
      'Entschuldigung für die Verwirrung!\n\n'
      'Testfrau Christine\n',
  31012: 'Liebe Eltern,\n\n'
      'bitte überprüfen Sie gemeinsam mit Ihrem Kind die Schulmaterialien.\n\n'
      'Kontrollieren Sie:\n'
      '– Alle Schulbücher und Hefte vorhanden und beschriftet?\n'
      '– Fehlen Seiten oder sind Bücher stark beschädigt?\n'
      '– Federmäppchen vollständig?\n\n'
      'Beschädigte Bücher können um 5,00 € Selbstbehalt beim Schulsekretariat nachbestellt werden.\n\n'
      'Vielen Dank!\n'
      'Testfrau Christine\n',
  45755: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'sechs Wochen Schule liegen hinter uns – Zeit für einen kurzen Rückblick.\n\n'
      'Die Klasse hat sich gut zusammengefunden; alle Kinder kennen bereits den Tagesablauf.\n\n'
      'Lernstand:\n'
      '– Lesen: Buchstaben bis zum L eingeführt\n'
      '– Schreiben: erste Lernwörter geübt\n'
      '– Mathematik: Zahlen bis 10, erste Additionsaufgaben\n\n'
      'Bitte beachten:\n'
      '– Schulmäppchen täglich kontrollieren\n'
      '– Lesekarte täglich mitbringen\n'
      '– Hausaufgaben unterschreiben\n\n'
      'Herzliche Grüße\n'
      'Testfrau Christine\n',
  77286: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'das erste Schulhalbjahr neigt sich dem Ende.\n\n'
      'Die Halbjahreszeugnisse werden am Donnerstag, 30. Jänner, ausgeteilt. '
      'Bitte stellen Sie sicher, dass Ihr Kind an diesem Tag anwesend ist.\n\n'
      'Das Zeugnis enthält Leistungsberichte in allen Fächern sowie Einschätzungen '
      'zu Lern- und Sozialverhalten.\n\n'
      'Bei Fragen vereinbaren Sie bitte einen Gesprächstermin.\n\n'
      'Mit herzlichen Grüßen\n'
      'Testfrau Christine\n',
  34050: 'Liebe Eltern,\n\n'
      'unsere Schule organisiert eine Kleider-Tauschbörse für Grundschüler!\n\n'
      'So funktioniert\'s:\n'
      '– Gut erhaltene Kleidung (Größe 110–134) bis Mittwoch, 19. März, ins Sekretariat bringen\n'
      '– Am Freitag, 21. März, dürfen alle Familien stöbern und mitnehmen\n\n'
      'Erlöse aus nicht abgeholten Stücken gehen an die Schulbücherei.\n\n'
      'Testfrau Christine\n',
  22021: 'Liebe Eltern,\n\n'
      'bitte geben Sie Ihrem Kind eine gesunde Jause mit.\n\n'
      'Bitte KEIN:\n'
      '– Schokolade, Gummibärchen, Chips\n'
      '– Süßgetränke oder gesüßte Fruchtsäfte\n\n'
      'Gute Alternativen:\n'
      '– Brot mit Käse oder Aufschnitt, Obst, Gemüsesticks\n'
      '– Wasser oder ungesüßter Tee\n\n'
      'Eine gesunde Jause stärkt Konzentration und tut Körper und Umwelt gut.\n\n'
      'Vielen Dank!\n'
      'Testfrau Christine\n',
  39102: 'Liebe Eltern und Erziehungsberechtigte,\n\n'
      'herzlich willkommen in der 1A – wir freuen uns sehr, Ihr Kind bei uns begrüßen zu dürfen!\n\n'
      'Wichtigste Infos:\n'
      '– Unterrichtszeiten: Mo–Fr, 8:00–12:50 Uhr (Mi bis 12:05 Uhr)\n'
      '– Pause: 10:00–10:20 Uhr im Schulhof\n'
      '– Hausaufgaben: täglich; bitte bis zum nächsten Tag erledigen\n\n'
      'Bitte ab Montag mitbringen:\n'
      '– Alle Schulmaterialien laut Materialliste (liegt bei)\n'
      '– Turnbeutel mit Hallenschuhen\n'
      '– Trinkflasche (bitte beschriften!)\n\n'
      'Bei Fragen: Ich bin täglich von 7:45–8:00 Uhr erreichbar.\n\n'
      'Auf ein schönes gemeinsames Schuljahr!\n\n'
      'Testfrau Christine\n',
};

// ── Homework (gradeGroup) text generators per subject ────────────────────────
// The dashboard repeats only a handful of homework strings across ~163 entries.
// To make every Merkheft entry distinct we interleave several activity families
// per subject and assign the generated unique texts to the sorted gradeGroup ids.

/// Interleaves [families] round-by-round (family 0 round 0, family 1 round 0, …)
/// and returns the first [need] entries. Throws if pools are too small or a
/// duplicate is produced.
List<String> _interleave(List<List<String>> families, int need) {
  final res = <String>[];
  for (var round = 0; res.length < need; round++) {
    for (final fam in families) {
      if (round < fam.length) {
        res.add(fam[round]);
        if (res.length == need) break;
      }
    }
    if (round > 200) {
      throw StateError('homework pools too small: have ${res.length}, need $need');
    }
  }
  if (res.toSet().length != res.length) {
    throw StateError('duplicate homework text generated');
  }
  return res;
}

final List<List<String>> _germanFamilies = <List<String>>[
  [
    for (final l in ['Mm', 'Ll', 'Oo', 'Tt', 'Nn', 'Rr', 'Hh', 'Kk'])
      'Buchstabe $l: Hefteintrag und Schwungübung fertigstellen.'
  ],
  [
    for (final s in [
      'und, ist, das',
      'wir, ihr, sie',
      'Mama, Oma, Opa',
      'Hund, Katze, Maus',
      'rot, blau, grün',
      'Tür, Uhr, Ohr',
      'Tag, Nacht, Zeit',
      'ich, du, er'
    ])
      'Lernwörter üben: $s – jedes Wort 3× schreiben.'
  ],
  [for (var i = 0; i < 8; i++) 'Lesepass Stufe ${i + 1}: den Text laut und deutlich vorlesen.'],
  [
    for (final t in [
      'Silben lesen',
      'erste Wörter',
      'Reimwörter',
      'Anlaute hören',
      'Gegensätze',
      'Selbstlaute',
      'Mitlaute',
      'Wortarten'
    ])
      'Anton-App: Übungen zum Thema „$t" abschließen.'
  ],
  [
    for (final w in [
      'To-ma-te',
      'Ba-na-ne',
      'Scho-ko-la-de',
      'E-le-fant',
      'Som-mer-tag',
      'Win-ter-zeit',
      'Ka-rot-te',
      'Pa-pa-gei'
    ])
      'Silbenbögen zeichnen und klatschen: $w.'
  ],
  [
    for (final r in ['Haus', 'Maus', 'Baum', 'Katze', 'Hand', 'Licht', 'Stein', 'Wald'])
      'Drei Reimwörter zu „$r" finden und aufschreiben.'
  ],
  [
    for (final s in [
      'Oma, Ofen, Obst',
      'Lampe, Leiter, Lupe',
      'Tisch, Tasche, Turm',
      'Nase, Nest, Nuss',
      'Rose, Ratte, Rad',
      'Sonne, Salat, Suppe',
      'Igel, Insel, Iglu',
      'Esel, Eis, Ente'
    ])
      'Diktatwörter üben: $s.'
  ],
  [
    for (final b in [
      'auf dem Spielplatz',
      'im Garten',
      'beim Einkaufen',
      'im Schnee',
      'am Bauernhof',
      'im Schwimmbad',
      'auf dem Markt',
      'beim Picknick'
    ])
      'Drei Sätze zum Bild „$b" schreiben.'
  ],
  [
    for (final s in [
      'Ball, Apfel, Schule',
      'Blume, Auto, Haus',
      'Buch, Tisch, Stuhl',
      'Hund, Vogel, Fisch',
      'Brot, Milch, Käse',
      'Sonne, Mond, Stern',
      'Wald, Berg, See',
      'Hose, Jacke, Schuh'
    ])
      'Nomen mit Artikel aufschreiben: $s.'
  ],
  [
    for (final s in [
      'Affe, Ball, Cola, Dose',
      'Ente, Fisch, Gans, Hut',
      'Igel, Jacke, Kuh, Lampe',
      'Maus, Nest, Ofen, Pilz',
      'Rose, Sonne, Tür, Uhu',
      'Vogel, Wal, Zaun, Ast',
      'Birne, Clown, Dach, Esel',
      'Gabel, Hase, Kerze, Lupe'
    ])
      'Wörter nach dem ABC ordnen: $s.'
  ],
  [for (var i = 0; i < 8; i++) 'Leseheft Seite ${8 + i * 2}: zweimal laut vorlesen.'],
  [
    for (final t in [
      'Das Wetter',
      'Mein Haustier',
      'Der Herbst',
      'Meine Familie',
      'Die große Pause',
      'Mein Frühstück',
      'Mein Wochenende',
      'Der Schulweg'
    ])
      'Abschreibübung „$t": sauber ins Heft übertragen.'
  ],
  [
    for (final g in ['Sch sch', 'ei', 'au', 'ch', 'ie', 'eu', 'pf', 'st'])
      'Wörter mit „$g" sammeln und aufschreiben.'
  ],
];

final List<List<String>> _mathFamilies = <List<String>>[
  [for (var i = 0; i < 6; i++) 'Plusaufgaben bis 20: Arbeitsblatt ${i + 1} rechnen.'],
  [for (var i = 0; i < 6; i++) 'Minusaufgaben bis 20: Heftseite ${12 + i} bearbeiten.'],
  [
    for (final s in ['1 und 9', '2 und 8', '3 und 7', '4 und 6', '5 und 5', 'gemischt'])
      'Verliebte Zahlen üben: $s.'
  ],
  [
    for (final t in [
      'Vorgänger eintragen',
      'Nachfolger eintragen',
      'rückwärts schreiben',
      'Lücken füllen',
      'in Zweierschritten zählen',
      'Nachbarzahlen finden'
    ])
      'Zahlenreihe bis 20: $t.'
  ],
  [
    for (final t in [
      'bis 10',
      'bis 14',
      'bis 18',
      'bis 20',
      'gemischt',
      'mit Zahlenmauer'
    ])
      'Verdoppeln und Halbieren $t üben.'
  ],
  [
    for (final t in [
      'Äpfel im Korb',
      'Murmeln in der Dose',
      'Kinder im Bus',
      'Blumen im Beet',
      'Kekse auf dem Teller',
      'Stifte im Mäppchen'
    ])
      'Sachaufgabe lösen: $t.'
  ],
  [for (var i = 0; i < 6; i++) 'Rechenwelt Heft Seite ${20 + i * 4}–${21 + i * 4} bearbeiten.'],
  [
    for (final t in [
      'Formen nachzeichnen',
      'Muster fortsetzen',
      'Würfel zählen',
      'Symmetrie ergänzen',
      'Körper benennen',
      'Bauplan nachbauen'
    ])
      'Geometrie: $t.'
  ],
];

final List<List<String>> _italianFamilies = <List<String>>[
  [
    for (final s in ['rosso e blu', 'giallo e verde', 'bianco e nero', 'arancione e viola'])
      'Ripassare i colori: $s.'
  ],
  [
    for (final s in ['fino a 10', 'fino a 15', 'fino a 20', 'a ritroso da 10'])
      'Contare $s in italiano.'
  ],
  [
    for (final s in ['la scuola', 'la famiglia', 'gli animali', 'i giorni della settimana'])
      'Imparare le parole: $s.'
  ],
  [
    for (final s in ['a pagina 12', 'a pagina 24', 'a pagina 36', 'a pagina 40'])
      'Ascoltare e ripetere il dialogo $s.'
  ],
  [for (var i = 1; i <= 4; i++) 'Completare le frasi sul quaderno: esercizio $i.'],
  [
    for (final s in ['dei colori', 'dei numeri', 'degli animali', 'delle stagioni'])
      'Leggere e memorizzare la filastrocca $s.'
  ],
];

const _natGeGeoHw = <String>[
  'Steckbrief zum Lieblingstier ausfüllen und ein Bild dazu zeichnen.',
  'Drei Eigenschaften des Wassers aufschreiben.',
  'Sachtext „Tiere im Wald" zweimal lesen und Schlüsselwörter markieren.',
  'Hefteintrag „Tiere im Winter" mit Zeichnung fertigstellen.',
  'Das Wetter drei Tage lang beobachten und Symbole eintragen.',
  'Frühblüher im Garten suchen und benennen.',
  'Die vier Jahreszeiten in die richtige Reihenfolge bringen.',
  'Ein gesundes Frühstück auf dem Teller-Arbeitsblatt zusammenstellen.',
  'Blätter verschiedener Bäume sammeln und einkleben.',
  'Den Tagesablauf mit Bildern der Uhr darstellen.',
  'Drei heimische Vögel benennen und anmalen.',
  'Müll richtig trennen: Bilder den Tonnen zuordnen.',
];

const _religionHw = <String>[
  'Ein Bild zum Gleichnis vom verlorenen Schaf malen.',
  'Die Geschichte der Arche Noah nacherzählen.',
  'Drei Dinge aufschreiben, für die du dankbar bist.',
  'Arbeitsblatt zum Thema Schöpfung fertigstellen.',
  'Kreuzworträtsel zu biblischen Begriffen lösen.',
  'Das Lied „Lass uns miteinander" für den Gottesdienst üben.',
  'Ein kurzes Dankgebet aufschreiben oder malen.',
  'Ein Adventkalender-Türchen gestalten und beschriften.',
  'Eine Kerze für den Friedensgruß verzieren.',
  'Das Kreuzzeichen üben und ins Heft zeichnen.',
  'Eine Geschichte von Sankt Martin nacherzählen.',
  'Ein Bild der Heiligen Familie ausmalen.',
];

const _musikHw = <String>[
  'Das Lied der Woche „Es tönen die Lieder" zweimal singen.',
  'Eine Rhythmusübung im 4/4-Takt dreimal klatschen.',
  'Notenzeilen zeichnen und die Noten beschriften.',
  'Das Musikrätsel auf dem Arbeitsblatt lösen.',
  'Das Bewegungslied für die Aufführung einüben.',
  'Hohe und tiefe Töne hören und unterscheiden.',
  'Ein Faschingslied auswendig lernen.',
  'Mit Körperinstrumenten einen Rhythmus erfinden.',
  'Lieblingslied aussuchen und der Klasse vorstellen.',
  'Den Takt zu einem Lied mitklatschen.',
  'Laute und leise Töne mit Symbolen aufschreiben.',
  'Ein einfaches Lied auf dem Glockenspiel üben.',
];

/// Returns a unique homework text per id for the given subject [label].
Map<int, String> _buildHomework(String label, List<int> sortedIds) {
  final n = sortedIds.length;
  List<String> texts;
  switch (label) {
    case 'Mathematik':
      texts = _interleave(_mathFamilies, n);
      break;
    case 'Italienisch':
      texts = _interleave(_italianFamilies, n);
      break;
    case 'Deutsch':
      texts = _interleave(_germanFamilies, n);
      break;
    case 'NatGeGeo':
      texts = _natGeGeoHw.take(n).toList();
      break;
    case 'Religion':
      texts = _religionHw.take(n).toList();
      break;
    case 'Musik':
      texts = _musikHw.take(n).toList();
      break;
    default:
      return {};
  }
  if (texts.length < n) {
    throw StateError('not enough homework texts for $label: ${texts.length}/$n');
  }
  return {for (var i = 0; i < n; i++) sortedIds[i]: texts[i]};
}

// ── Calendar lesson-content text generators per subject ──────────────────────
// The captured calendar holds ~492 real classroom log entries (lessonContents)
// with personal/typo-laden teacher input. We replace each with a clean, generic,
// subject-appropriate lesson-log line. Each entry is "<Prefix> <Topic>." and the
// (prefix, topic) pairs are unique, so every generated text is distinct.

const _logPrefixes = <String>[
  'Wir üben:', 'Stationenarbeit:', 'Einführung:', 'Wiederholung:',
  'Vertiefung:', 'Partnerarbeit:', 'Arbeitsheft-Übungen:', 'Tafelbild und Beispiele:',
  'Freiarbeit:', 'Lernspiel:', 'Hefteintrag:', 'Wochenrückblick:'
];

const _deTopics = <String>[
  'die Buchstabeneinführung Mm', 'die Buchstabeneinführung Ss', 'Lautanalyse und Anlaute',
  'das Silbenlesen', 'das Schreiben erster Wörter', 'die Lernwörter der Woche',
  'das Lesetraining mit dem Leseblatt', 'die Arbeit im Buchstabenheft', 'Reimwörter und Lautspiele',
  'das Lesen und Schreiben von Sätzen', 'die Anlauttabelle', 'das Bilderbuch der Woche'
];
const _maTopics = <String>[
  'Plusaufgaben bis 20', 'Minusaufgaben bis 20', 'das Verdoppeln und Halbieren',
  'die verliebten Zahlen', 'die Zahlzerlegungen', 'die Zahlenreihe bis 20',
  'die Nachbarzahlen', 'geometrische Formen', 'geometrische Körper',
  'Sachaufgaben', 'Mengen und Anzahlen', 'das Rechnen am Zwanzigerfeld'
];
const _ngTopics = <String>[
  'die Jahreszeiten', 'der Herbst und seine Früchte', 'die Tiere im Winter',
  'die Orientierung links und rechts', 'die Frühblüher', 'die Wetterbeobachtung',
  'die gesunde Ernährung', 'der Tag- und Nachtwechsel'
];
const _reTopics = <String>[
  'die Schöpfungsgeschichte', 'Erntedank und Dankbarkeit', 'Geschichten aus der Bibel',
  'das Kirchenjahr', 'die Adventszeit', 'Jesus und seine Freunde',
  'das Miteinander in der Gemeinschaft', 'die Feste im Jahreskreis'
];
const _spTopics = <String>[
  'das Geräteturnen', 'Lauf- und Fangspiele', 'Ballspiele und Koordination',
  'eine Bewegungslandschaft', 'Kooperationsspiele', 'Gleichgewicht und Balancieren',
  'rhythmische Bewegung', 'Staffelspiele'
];
const _kuTopics = <String>[
  'das Malen mit Wasserfarben', 'eine Collage', 'das Arbeiten mit Ölkreiden',
  'das Plastizieren mit Knete', 'Drucktechniken', 'ein Jahreszeitenbild',
  'Faltarbeiten', 'ein gebasteltes Geschenk'
];
const _muTopics = <String>[
  'Lieder der Jahreszeit', 'Rhythmusübungen', 'Bodypercussion',
  'das Kennenlernen von Instrumenten', 'Bewegungslieder', 'hohe und tiefe Töne',
  'das Anhören eines Musikstücks', 'Faschingslieder'
];
const _itPrefixes = <String>[
  'Ripasso:', 'Esercizi:', 'Gioco linguistico:', 'Ascolto e ripetizione:',
  'Lettura:', 'Canzone:', 'Lavoro a coppie:', 'Quaderno:'
];
const _itTopics = <String>[
  'i colori', 'i numeri fino a 20', 'gli oggetti scolastici', 'gli animali',
  'la famiglia', 'i saluti', 'una filastrocca', 'i giorni della settimana'
];
const _wsLog = <String>[
  'Wir basteln weihnachtliche Geschenke und Dekorationen.',
  'Wir gestalten Weihnachtskarten und kleine Tonarbeiten.',
  'Wir verzieren Kerzenhalter für den Adventstisch.',
  'Wir fertigen Fensterbilder zum Thema Winter.',
];

/// Builds [need] unique "<prefix> <topic>." lines (prefix outer, topic inner).
List<String> _logTexts(List<String> prefixes, List<String> topics, int need) {
  final res = <String>[];
  final t = topics.length;
  final cap = prefixes.length * topics.length;
  for (var i = 0; i < cap && res.length < need; i++) {
    res.add('${prefixes[i ~/ t]} ${topics[i % t]}.');
  }
  if (res.length < need) {
    throw StateError('lesson-content pool too small: need $need, have $cap');
  }
  return res;
}

/// Returns a unique lesson-content text per id for the given [subject].
Map<int, String> _buildLessonContents(String subject, List<int> sortedIds) {
  final n = sortedIds.length;
  if (n == 0) return {};
  if (subject == 'Vormittagspause') {
    return {for (final id in sortedIds) id: 'Pausenaufsicht'};
  }
  List<String> texts;
  switch (subject) {
    case 'Deutsch':
      texts = _logTexts(_logPrefixes, _deTopics, n);
      break;
    case 'Mathematik':
      texts = _logTexts(_logPrefixes, _maTopics, n);
      break;
    case 'NatGeGeo':
      texts = _logTexts(_logPrefixes, _ngTopics, n);
      break;
    case 'Religion':
      texts = _logTexts(_logPrefixes, _reTopics, n);
      break;
    case 'Bewegung und Sport':
      texts = _logTexts(_logPrefixes, _spTopics, n);
      break;
    case 'KuTE':
      texts = _logTexts(_logPrefixes, _kuTopics, n);
      break;
    case 'Musik':
      texts = _logTexts(_logPrefixes, _muTopics, n);
      break;
    case 'Italienisch':
      texts = _logTexts(_itPrefixes, _itTopics, n);
      break;
    case 'Latein':
      texts = _wsLog.take(n).toList();
      break;
    default:
      return {};
  }
  return {for (var i = 0; i < n; i++) sortedIds[i]: texts[i]};
}

/// Recursively visits every lesson object (`isLesson == 1`) in a calendar
/// response tree and invokes [fn] on it.
void _forEachLesson(dynamic node, void Function(Map<String, dynamic> lesson) fn) {
  if (node is Map) {
    if (node['isLesson'] == 1 && node['lesson'] is Map) {
      fn((node['lesson'] as Map).cast<String, dynamic>());
    }
    for (final v in node.values) {
      _forEachLesson(v, fn);
    }
  } else if (node is List) {
    for (final v in node) {
      _forEachLesson(v, fn);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

void updateGrade(Map<String, dynamic> g) {
  final id = g['id'] as int;
  if (gName.containsKey(id)) g['name'] = gName[id];
  if (gDesc.containsKey(id)) g['description'] = gDesc[id];
  for (final c in (g['competences'] as List? ?? [])) {
    final key = '$id|${c['typeName']}';
    if (cDesc.containsKey(key)) c['description'] = cDesc[key];
  }
}

void main() {
  final file = File('assets/demo/capture.json');
  final raw = file.readAsStringSync();
  final data = jsonDecode(raw) as List<dynamic>;

  // ── Pre-pass: collect homework ids (dashboard + calendar exams) per subject
  // and lesson-content ids per subject so generated texts can be assigned
  // deterministically by sorted id. ──────────────────────────────────────────
  final hwIdsByLabel = <String, Set<int>>{};
  final lcIdsBySubject = <String, Set<int>>{};
  for (final item in data) {
    final addr = item['address'] as String;
    final resp = item['response'];
    if (addr.contains('dashboard/dashboard') && resp is List) {
      for (final day in resp) {
        for (final di in (day['items'] as List? ?? [])) {
          if (di['type'] == 'gradeGroup') {
            final label = (di['label'] ?? '').toString();
            hwIdsByLabel.putIfAbsent(label, () => <int>{}).add(di['id'] as int);
          }
        }
      }
    } else if (addr.contains('calendar/student')) {
      _forEachLesson(resp, (lesson) {
        final subj = lesson['subject'];
        final sname = subj is Map ? (subj['name'] ?? '').toString() : '';
        for (final lc in (lesson['lessonContents'] as List? ?? [])) {
          lcIdsBySubject.putIfAbsent(sname, () => <int>{}).add(lc['id'] as int);
        }
        for (final he in [
          ...(lesson['homeworkExams'] as List? ?? []),
          ...(lesson['homeworkExamsOther'] as List? ?? [])
        ]) {
          hwIdsByLabel.putIfAbsent(sname, () => <int>{}).add(he['id'] as int);
        }
      });
    }
  }
  final hwTextById = <int, String>{};
  hwIdsByLabel.forEach((label, ids) {
    final sorted = ids.toList()..sort();
    hwTextById.addAll(_buildHomework(label, sorted));
  });
  final lcTextById = <int, String>{};
  lcIdsBySubject.forEach((subject, ids) {
    final sorted = ids.toList()..sort();
    lcTextById.addAll(_buildLessonContents(subject, sorted));
  });

  int cntGrade = 0, cntDetail = 0, cntDash = 0, cntMsg = 0, cntAbs = 0, cntCal = 0, cntCert = 0;

  for (final item in data) {
    final addr = item['address'] as String;
    final resp = item['response'];

    if (addr.contains('entry/getGrade')) {
      final r = resp as Map<String, dynamic>;
      final id = r['id'] as int;
      final hasCompUpdate = (r['competences'] as List? ?? [])
          .any((c) => cDesc.containsKey('$id|${(c as Map)['typeName']}'));
      if (gDesc.containsKey(id) || gName.containsKey(id) || hasCompUpdate) {
        updateGrade(r);
        cntGrade++;
      }
    } else if (addr.contains('subject_detail')) {
      if (resp is String) {
        final inner = jsonDecode(resp) as Map<String, dynamic>;
        bool changed = false;
        for (final g in (inner['grades'] as List? ?? [])) {
          final old = g['description'];
          updateGrade(g as Map<String, dynamic>);
          if (g['description'] != old) changed = true;
        }
        for (final o in (inner['observations'] as List? ?? [])) {
          final id = o['id'] as int;
          if (obsNote.containsKey(id)) {
            o['note'] = obsNote[id];
            changed = true;
          }
        }
        if (changed) {
          item['response'] = jsonEncode(inner);
          cntDetail++;
        }
      }
    } else if (addr.contains('dashboard/absences')) {
      if (resp is Map) {
        for (final ab in (resp['absences'] as List? ?? [])) {
          final date = ab['date'] as String;
          final cur = ab['reason'];
          if (absReason.containsKey(date) && cur != null && cur.toString().isNotEmpty) {
            final newR = absReason[date]!;
            ab['reason'] = newR;
            for (final item in (ab['group'] as List? ?? [])) {
              if (item['reason'] != null && item['reason'].toString().isNotEmpty) {
                item['reason'] = newR;
              }
            }
            cntAbs++;
          }
        }
      }
    } else if (addr.contains('student/certificate')) {
      if (resp is String) {
        final patched = _patchCertificate(resp);
        if (patched != resp) {
          item['response'] = patched;
          cntCert++;
        }
      }
    } else if (addr.contains('getMyMessages')) {
      if (resp is List) {
        cntMsg += _anonymizeAttachNames(resp);
        for (final msg in resp) {
          final m = msg as Map<String, dynamic>;
          final id = m['id'] as int;
          bool changed = false;
          if (msgSubjects.containsKey(id)) {
            m['subject'] = msgSubjects[id];
            changed = true;
          }
          if (msgTexts.containsKey(id)) {
            m['text'] = jsonEncode({
              'ops': [
                {'insert': msgTexts[id]}
              ]
            });
            changed = true;
          }
          if (changed) cntMsg++;
        }
      }
    } else if (addr.contains('dashboard/dashboard')) {
      if (resp is List) {
        for (final day in resp) {
          for (final di in (day['items'] as List? ?? [])) {
            final id = di['id'] as int;
            switch (di['type']) {
              case 'observation':
                if (obsSub.containsKey(id)) {
                  di['subtitle'] = obsSub[id];
                  cntDash++;
                }
                break;
              case 'gradeGroup':
                if (hwTextById.containsKey(id)) {
                  di['subtitle'] = hwTextById[id];
                  cntDash++;
                }
                break;
              case 'grade':
                final sub = gName[id] ?? gradeDashExtra[id];
                if (sub != null) {
                  di['subtitle'] = sub;
                  cntDash++;
                }
                break;
            }
          }
        }
      }
    } else if (addr.contains('calendar/student')) {
      cntCal += _anonymizeAttachNames(resp);
      _forEachLesson(resp, (lesson) {
        for (final lc in (lesson['lessonContents'] as List? ?? [])) {
          final id = lc['id'] as int;
          if (lcTextById.containsKey(id)) {
            lc['name'] = lcTextById[id];
            cntCal++;
          }
        }
        for (final he in [
          ...(lesson['homeworkExams'] as List? ?? []),
          ...(lesson['homeworkExamsOther'] as List? ?? [])
        ]) {
          final id = he['id'] as int;
          if (hwTextById.containsKey(id)) {
            he['name'] = hwTextById[id];
            cntCal++;
          }
        }
      });
    }
  }

  const encoder = JsonEncoder.withIndent('  ');
  final encoded = encoder.convert(data);
  // Dart escapes all non-ASCII chars as \uXXXX; convert back to literal UTF-8
  // to match the original file format and keep the git diff minimal.
  // The negative lookbehind (?<!\\) prevents touching \\uXXXX sequences inside
  // subject_detail response strings where \\ is itself an escaped backslash.
  final unescaped = encoded.replaceAllMapped(
    RegExp(r'(?<!\\)\\u([0-9a-fA-F]{4})'),
    (m) {
      final cp = int.parse(m.group(1)!, radix: 16);
      if (cp < 0x20) return m.group(0)!; // keep control chars escaped
      return String.fromCharCode(cp);
    },
  );
  // The original capture.json uses CRLF line endings; preserve them.
  file.writeAsStringSync(unescaped.replaceAll('\n', '\r\n'));

  print('Done. getGrade: $cntGrade | subject_detail: $cntDetail | '
      'dashboard items: $cntDash | messages: $cntMsg | absences: $cntAbs | '
      'calendar entries: $cntCal | certificate: $cntCert');
}
