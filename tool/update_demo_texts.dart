// Replaces demo texts in assets/demo/capture.json.
// Run from repo root: dart run tool/update_demo_texts.dart

import 'dart:convert';
import 'dart:io';

// ── Grade descriptions by gradeId ────────────────────────────────────────────
const gDesc = <int, String>{
  13278: 'Max stellt seinen Lösungsweg klar und nachvollziehbar vor. Er hört anderen aufmerksam zu und bringt eigene Ideen ein.',
  42098: 'Die Fingerbilder werden sicher und schnell erkannt. Max nennt die Anzahl direkt, ohne einzeln zu zählen.',
  39256: 'Max arbeitet mit Freude und Ausdauer an den Bastelarbeiten. Die Ergebnisse sind kreativ und sorgfältig ausgeführt.',
  98696: 'Max setzt sich offen mit dem Thema auseinander und bringt persönliche Gedanken ein.',
  81482: 'Sehr präzise und geduldige Faltarbeit. Die Knicke sitzen exakt und das Ergebnis ist ordentlich.',
  21395: 'Additionsaufgaben mit +0 und +1 werden sicher und selbstständig gelöst.',
  87397: 'Max löst die 10er-Minusaufgaben zuverlässig. Die Strategie ist gut eingeübt.',
  65302: 'Vergleichszeichen werden korrekt eingesetzt. Max erkennt Zahlenbeziehungen sicher.',
  14165: 'Einfache Subtraktionsaufgaben werden konzentriert und methodisch bearbeitet.',
  13905: 'Das Konzept der Kraft der 5 ist verstanden. Erste Aufgaben werden sicher gelöst.',
  22280: 'Sorgfältige Faltarbeit. Anweisungen werden Schritt für Schritt umgesetzt.',
  38657: 'Geometrische Körper werden richtig erkannt, benannt und nach Merkmalen sortiert.',
  40495: 'Max zählt sicher vorwärts und rückwärts. Das flexible Weiterzählen von beliebigen Zahlen gelingt zuverlässig.',
  76237: 'Das Forschungsprojekt ist liebevoll gestaltet. Max präsentiert sein Thema mit Begeisterung und gutem Fachwissen.',
  88907: 'Additionsaufgaben wurden selbstständig und korrekt bearbeitet. Max arbeitet konzentriert.',
  13478: 'Max nimmt engagiert am Sportunterricht teil. Er hält die Regeln ein und unterstützt die Gruppe.',
  83563: 'Die Lesehausaufgabe wurde zuverlässig erledigt. Max liest zunehmend flüssiger.',
  36062: 'Auch die zweite Seite wurde vollständig bearbeitet. Wörter werden sicher und korrekt gelesen.',
  46421: 'Das Heft ist vollständig und sorgfältig geführt. Einträge sind klar und übersichtlich gestaltet.',
  54597: 'Max gibt die Geschichte anschaulich wieder und erfasst die zentrale Botschaft gut.',
  32431: 'Max meldet sich regelmäßig und beteiligt sich aktiv an Unterrichtsgesprächen. Seine Beiträge sind treffend.',
  33416: 'Gute Mitarbeit. Max hört aufmerksam zu und bringt passende Gedanken ein.',
  65392: 'Das Forschungsprojekt ist ansprechend gestaltet und gut recherchiert. Max präsentiert sein Thema souverän.',
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

// ── Observation notes (subject_detail) by observationId ─────────────────────
const obsNote = <int, String>{
  31417: 'Mündliche Mitarbeit März/April:\n'
      'Max beteiligt sich regelmäßig am Unterrichtsgespräch. Er formuliert seine Gedanken klar und hört anderen aufmerksam zu.\n'
      'Die Hausaufgaben werden zuverlässig erledigt und vollständig mitgebracht.\n'
      'Im Umgang mit Lernmaterialien zeigt Max Sorgfalt. Das Heft ist ordentlich geführt.',
  66155: 'Sprechstunde mit dem Vater von Max.\n'
      'Besprochen wurde die Entwicklung im Unterricht sowie die bisherigen Leistungen. Max macht gute Fortschritte, besonders im mündlichen Bereich.\n'
      'Vereinbart: Übungsroutinen zu Hause beibehalten und auf vollständige Hefteinträge achten.',
  76542: 'Mündliche Mitarbeit Januar/Februar:\n'
      'Max nimmt regelmäßig am Unterrichtsgespräch teil. Er meldet sich häufig und bringt gute Beiträge ein.\n'
      'Auch bei anspruchsvolleren Aufgaben gibt Max nicht auf. Er arbeitet ausdauernd und konzentriert.\n'
      'Das Arbeitstempo ist gut; Max schließt Aufgaben meist pünktlich ab.',
  95909: 'Max geht respektvoll mit allen Mitschülerinnen und Mitschülern um. Er akzeptiert unterschiedliche Meinungen und sucht gemeinsam nach Lösungen.\n'
      'In der Klasse verhält sich Max rücksichtsvoll. Er achtet auf die Bedürfnisse anderer und bietet Hilfe an.\n'
      'Auch in schwierigen Situationen zeigt Max gute Selbstkontrolle. Konflikte werden ruhig und sachlich gelöst.',
};

// ── Dashboard observation subtitles by observationId ─────────────────────────
const obsSub = <int, String>{
  92397: 'Max comprende i contenuti proposti e li applica con sicurezza. Partecipa volent...',
  19358: 'Oggi mi sono impegnato a lavorare con attenzione e sono riuscito a finire tutto...',
  31417: 'Mündliche Mitarbeit März/April: Max beteiligt sich regelmäßig am Unterrichtsge...',
  84341: 'Max hatte heute einen schwierigen Tag. Die Konzentration fiel schwer, weshalb e...',
  95909: 'Max, heute hast du etwas Schönes gezeigt: Du hast einem Mitschüler geholfen, oh...',
  86622: 'Bitte Klebstoff nachkaufen.',
  66155: 'Sprechstunde mit dem Vater von Max. Entwicklung im Unterricht und Leistungen be...',
  86484: "Colloquio con il padre di Max. Si è parlato degli aspetti sociali e dell'impegno...",
  65333: 'Max, es könnte helfen, die Hausaufgaben gleichmäßig auf die Woche zu verteilen....',
  94012: 'Sprechstunde mit den Eltern von Max. Aktuelle Lernentwicklung und Sozialverhalt...',
  76542: 'Mündliche Mitarbeit Januar/Februar: Max nimmt regelmäßig am Unterrichtsgesprä...',
  91959: 'Max collabora in modo attivo durante le lezioni. Dimostra interesse e partecipaz...',
  59009: 'Max, in letzter Zeit läuft es richtig gut! Du freust dich selbst über deine Fort...',
  52487: 'Max arbeitet sehr konzentriert und in einem angemessenen Arbeitstempo. Er erledi...',
  72296: 'Max, heute war ein schwieriger Tag. Du hast wenig geschafft und dich kaum konzen...',
  65461: 'Max arbeitet am besten, wenn er klare Aufgaben bekommt und den Ablauf kennt. Unt...',
  37760: 'Kinderrat: Es gelingt dir gut, an Kreisgesprächen teilzunehmen. Du bringst dein...',
  80686: 'Lieber Max, übe weiterhin das Eines-mehr und Eines-weniger, besonders mit dem +1...',
  67422: 'Mathematik: Hefteinträge zu den Ziffern bitte bis Montag fertig beenden.',
  55082: 'Max mostra interesse e partecipa con entusiasmo alle attività della lezione.',
  39451: 'Mündliche Mitarbeit November/Dezember: Max meldet sich regelmäßig und bringt gut...',
  18392: 'Heftführung: Deine Einträge sind vollständig und ordentlich gestaltet. Weiter so...',
  54313: 'Du zeigst Interesse an kreativen Aufgaben und arbeitest je nach Thema mit großem...',
  12757: 'Max, du beobachtest die Natur genau und stellst gute Fragen. Dein Interesse an n...',
  85525: 'Ich bemühe mich, ordentlich zu arbeiten und meine Aufgaben sorgfältig zu erledigen.',
  66498: 'Sprechstunde mit dem Vater von Max. Sozial-, Lern- und Arbeitsverhalten besprochen.',
  54473: 'September/Oktober: Max bringt sich gerne in den Unterricht ein und hält die Rege...',
  35112: 'Mündliche Mitarbeit September/Oktober: Max beteiligt sich an mündlichen Aktivitä...',
  34931: 'Max bemüht sich beim Arbeiten konzentriert zu bleiben, gelingt dies aber nicht im...',
  80292: 'September/Oktober: Max beteiligt sich aktiv am mündlichen Unterricht und meldet s...',
  68800: 'Kann alle geübten Laute sicher benennen. Sehr gut! Weiter so!',
  63269: 'Kann alle geübten Laute den Bildern richtig zuordnen. Weiterhin fleißig üben!',
  62565: 'Kann alle geübten Laute mit Bildern verbinden: ä, ö, ü, Au, Ei, Eu.',
  10282: 'Kann alle geübten Laute mit Bildern verbinden: A, E, I, O, U. Täglich weiterüben!',
  61173: '- zählt fehlerfrei bis 30; - zählt flexibel weiter; - zählt sicher rückwärts von...',
};

// ── Dashboard homework (gradeGroup) subtitles by gradeGroupId ────────────────
const hwSub = <int, String>{
  // Mathematik (38)
  95181: 'Addieren und Subtrahieren bis 20 üben – Arbeitsblatt fertigstellen.',
  64987: 'Flex & Flo Seite 24–25 bearbeiten.',
  38893: '5 Rechengeschichten aufschreiben und lösen.',
  57052: 'Tauschaufgaben: a + b = b + a – Beispiele aufschreiben.',
  89131: 'Zahlen bis 20 ordnen, Vorgänger und Nachfolger aufschreiben.',
  26361: 'Verdoppelungsaufgaben bis 20 auswendig lernen.',
  69429: 'Halbierungsaufgaben üben – Arbeitsblatt beenden.',
  89840: 'Geometrische Formen zeichnen und beschriften.',
  38785: 'Minusaufgaben mit dem Zwanziger-Rechenrahmen üben.',
  99733: 'Zahlenstrahl bis 20 beschriften und Aufgaben einzeichnen.',
  45093: 'Einer und Zehner darstellen: Stäbchen zeichnen.',
  61856: 'Rechenaufgaben im Zahlenraum bis 20 – Heftseite fertigstellen.',
  70142: 'Addieren und Subtrahieren bis 20 üben – Arbeitsblatt fertigstellen.',
  42325: 'Flex & Flo Seite 24–25 bearbeiten.',
  44438: '5 Rechengeschichten aufschreiben und lösen.',
  74686: 'Tauschaufgaben: a + b = b + a – Beispiele aufschreiben.',
  60432: 'Zahlen bis 20 ordnen, Vorgänger und Nachfolger aufschreiben.',
  71348: 'Verdoppelungsaufgaben bis 20 auswendig lernen.',
  99353: 'Halbierungsaufgaben üben – Arbeitsblatt beenden.',
  69470: 'Geometrische Formen zeichnen und beschriften.',
  74042: 'Minusaufgaben mit dem Zwanziger-Rechenrahmen üben.',
  57576: 'Zahlenstrahl bis 20 beschriften und Aufgaben einzeichnen.',
  50306: 'Einer und Zehner darstellen: Stäbchen zeichnen.',
  19071: 'Rechenaufgaben im Zahlenraum bis 20 – Heftseite fertigstellen.',
  89507: 'Addieren und Subtrahieren bis 20 üben – Arbeitsblatt fertigstellen.',
  82603: 'Flex & Flo Seite 24–25 bearbeiten.',
  92719: '5 Rechengeschichten aufschreiben und lösen.',
  40007: 'Tauschaufgaben: a + b = b + a – Beispiele aufschreiben.',
  18834: 'Zahlen bis 20 ordnen, Vorgänger und Nachfolger aufschreiben.',
  27342: 'Verdoppelungsaufgaben bis 20 auswendig lernen.',
  22363: 'Halbierungsaufgaben üben – Arbeitsblatt beenden.',
  63883: 'Geometrische Formen zeichnen und beschriften.',
  95649: 'Minusaufgaben mit dem Zwanziger-Rechenrahmen üben.',
  65296: 'Zahlenstrahl bis 20 beschriften und Aufgaben einzeichnen.',
  68082: 'Einer und Zehner darstellen: Stäbchen zeichnen.',
  95477: 'Rechenaufgaben im Zahlenraum bis 20 – Heftseite fertigstellen.',
  38016: 'Addieren und Subtrahieren bis 20 üben – Arbeitsblatt fertigstellen.',
  65444: 'Flex & Flo Seite 24–25 bearbeiten.',
  // Italienisch (18)
  81426: 'Ripetere i colori e i numeri fino a 10.',
  30926: 'Ascoltare e ripetere il dialogo a pagina 38.',
  22156: 'Completare le frasi sul quaderno italiano.',
  91070: 'Imparare le parole nuove della settimana.',
  20458: 'Colorare e incollare le immagini sul quaderno.',
  70589: 'Leggere la filastrocca e imparare a memoria.',
  40021: 'Ripetere i colori e i numeri fino a 10.',
  51245: 'Ascoltare e ripetere il dialogo a pagina 38.',
  30033: 'Completare le frasi sul quaderno italiano.',
  82512: 'Imparare le parole nuove della settimana.',
  54587: 'Colorare e incollare le immagini sul quaderno.',
  49117: 'Leggere la filastrocca e imparare a memoria.',
  24662: 'Ripetere i colori e i numeri fino a 10.',
  21226: 'Ascoltare e ripetere il dialogo a pagina 38.',
  82063: 'Completare le frasi sul quaderno italiano.',
  14117: 'Imparare le parole nuove della settimana.',
  41850: 'Colorare e incollare le immagini sul quaderno.',
  34050: 'Leggere la filastrocca e imparare a memoria.',
  // Deutsch (89)
  68878: 'Wörter mit Sch schreiben üben.',
  87236: 'Lesehausaufgabe: Text im Leseheft zweimal vorlesen.',
  46463: 'Hefteintrag zum Buchstaben beenden.',
  23396: 'Buchstaben mit Tinte nachspuren, Wörter abschreiben.',
  15695: 'Lernwörter der Woche 3× aufschreiben.',
  59615: 'Satzdiktat einüben.',
  57400: 'Fehler aus dem Diktat verbessern.',
  96673: '3 Sätze zum Bild aufschreiben.',
  47930: 'Silben klatschen und unterstreichen – Arbeitsblatt fertigstellen.',
  59823: 'Schreibung von ie und ei üben.',
  31319: 'Lesekarte einpacken.',
  37460: 'Anton-App: Übungen abschließen.',
  97841: 'Diktatwörter 5× aufschreiben und vorlesen.',
  99593: 'Nomen aufschreiben und Artikel dazuschreiben.',
  93227: 'Wörter nach dem Abc ordnen.',
  59735: 'Brief fertigschreiben.',
  45382: 'Buchstaben Ch: Hefteintrag und Arbeitsblatt beenden.',
  83000: 'Verben aus dem Text heraussuchen und aufschreiben.',
  17331: 'Sätze aus Wörtern zusammensetzen und aufschreiben.',
  14207: 'Leseübung: Lesepass bis Stufe 4.',
  62581: 'Wörter mit Sch schreiben üben.',
  18675: 'Lesehausaufgabe: Text im Leseheft zweimal vorlesen.',
  37653: 'Hefteintrag zum Buchstaben beenden.',
  94259: 'Buchstaben mit Tinte nachspuren, Wörter abschreiben.',
  28726: 'Lernwörter der Woche 3× aufschreiben.',
  28301: 'Satzdiktat einüben.',
  83579: 'Fehler aus dem Diktat verbessern.',
  80644: '3 Sätze zum Bild aufschreiben.',
  62350: 'Silben klatschen und unterstreichen – Arbeitsblatt fertigstellen.',
  38746: 'Schreibung von ie und ei üben.',
  21915: 'Lesekarte einpacken.',
  16175: 'Anton-App: Übungen abschließen.',
  30969: 'Diktatwörter 5× aufschreiben und vorlesen.',
  99192: 'Nomen aufschreiben und Artikel dazuschreiben.',
  88172: 'Wörter nach dem Abc ordnen.',
  18326: 'Brief fertigschreiben.',
  60019: 'Buchstaben Ch: Hefteintrag und Arbeitsblatt beenden.',
  11504: 'Verben aus dem Text heraussuchen und aufschreiben.',
  99166: 'Sätze aus Wörtern zusammensetzen und aufschreiben.',
  80381: 'Leseübung: Lesepass bis Stufe 4.',
  24621: 'Wörter mit Sch schreiben üben.',
  66985: 'Lesehausaufgabe: Text im Leseheft zweimal vorlesen.',
  10425: 'Hefteintrag zum Buchstaben beenden.',
  93748: 'Buchstaben mit Tinte nachspuren, Wörter abschreiben.',
  76540: 'Lernwörter der Woche 3× aufschreiben.',
  36071: 'Satzdiktat einüben.',
  79514: 'Fehler aus dem Diktat verbessern.',
  10074: '3 Sätze zum Bild aufschreiben.',
  12552: 'Silben klatschen und unterstreichen – Arbeitsblatt fertigstellen.',
  41385: 'Schreibung von ie und ei üben.',
  17592: 'Lesekarte einpacken.',
  73699: 'Anton-App: Übungen abschließen.',
  79822: 'Diktatwörter 5× aufschreiben und vorlesen.',
  31643: 'Nomen aufschreiben und Artikel dazuschreiben.',
  79163: 'Wörter nach dem Abc ordnen.',
  77839: 'Brief fertigschreiben.',
  87110: 'Buchstaben Ch: Hefteintrag und Arbeitsblatt beenden.',
  40161: 'Verben aus dem Text heraussuchen und aufschreiben.',
  17716: 'Sätze aus Wörtern zusammensetzen und aufschreiben.',
  19287: 'Leseübung: Lesepass bis Stufe 4.',
  41195: 'Wörter mit Sch schreiben üben.',
  46500: 'Lesehausaufgabe: Text im Leseheft zweimal vorlesen.',
  73624: 'Hefteintrag zum Buchstaben beenden.',
  38080: 'Buchstaben mit Tinte nachspuren, Wörter abschreiben.',
  80678: 'Lernwörter der Woche 3× aufschreiben.',
  34957: 'Satzdiktat einüben.',
  96374: 'Fehler aus dem Diktat verbessern.',
  65519: '3 Sätze zum Bild aufschreiben.',
  98259: 'Silben klatschen und unterstreichen – Arbeitsblatt fertigstellen.',
  17944: 'Schreibung von ie und ei üben.',
  62772: 'Lesekarte einpacken.',
  28373: 'Anton-App: Übungen abschließen.',
  46509: 'Diktatwörter 5× aufschreiben und vorlesen.',
  70637: 'Nomen aufschreiben und Artikel dazuschreiben.',
  42742: 'Wörter nach dem Abc ordnen.',
  19880: 'Brief fertigschreiben.',
  22833: 'Buchstaben Ch: Hefteintrag und Arbeitsblatt beenden.',
  16630: 'Verben aus dem Text heraussuchen und aufschreiben.',
  80855: 'Sätze aus Wörtern zusammensetzen und aufschreiben.',
  11934: 'Leseübung: Lesepass bis Stufe 4.',
  40982: 'Wörter mit Sch schreiben üben.',
  73653: 'Lesehausaufgabe: Text im Leseheft zweimal vorlesen.',
  73092: 'Hefteintrag zum Buchstaben beenden.',
  31579: 'Buchstaben mit Tinte nachspuren, Wörter abschreiben.',
  59672: 'Lernwörter der Woche 3× aufschreiben.',
  69638: 'Satzdiktat einüben.',
  47388: 'Fehler aus dem Diktat verbessern.',
  82845: '3 Sätze zum Bild aufschreiben.',
  13: 'Silben klatschen und unterstreichen – Arbeitsblatt fertigstellen.',
  // NatGeGeo (5)
  55082: 'Hefteintrag zum Thema Tiere im Winter fertigstellen.',
  36365: 'Sachtext zweimal lesen und Schlüsselwörter unterstreichen.',
  62296: 'Zeichnung zum Thema Jahreszeiten fertigstellen.',
  31798: '3 Eigenschaften des Wassers aufschreiben.',
  17685: 'Steckbrief zum Lieblingstier ausfüllen.',
  // Religion (8)
  35203: 'Bibelgeschichte nochmals lesen und Bild dazu zeichnen.',
  94939: 'Lied für den Gottesdienst einüben.',
  57447: 'Arbeitsblatt zum Thema Advent fertigstellen.',
  20322: 'Bild zum Gleichnis malen.',
  50857: '3 Dinge aufschreiben, für die du dankbar bist.',
  71993: 'Kreuzworträtsel zu biblischen Begriffen lösen.',
  22224: 'Bibelgeschichte nochmals lesen und Bild dazu zeichnen.',
  96752: 'Lied für den Gottesdienst einüben.',
  // Musik (5)
  23238: 'Lied der Woche zu Hause zweimal singen.',
  41571: 'Rhythmusübung klatschen – Takt 3× üben.',
  94696: 'Notenzeilen zeichnen und Noten beschriften.',
  82132: 'Musikrätsel auf dem Arbeitsblatt lösen.',
  44760: 'Lied für die Aufführung einüben.',
};

// ─────────────────────────────────────────────────────────────────────────────

void updateGrade(Map<String, dynamic> g) {
  final id = g['id'] as int;
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

  int cntGrade = 0, cntDetail = 0, cntDash = 0;

  for (final item in data) {
    final addr = item['address'] as String;
    final resp = item['response'];

    if (addr.contains('entry/getGrade')) {
      final r = resp as Map<String, dynamic>;
      final id = r['id'] as int;
      final hasCompUpdate = (r['competences'] as List? ?? [])
          .any((c) => cDesc.containsKey('$id|${(c as Map)['typeName']}'));
      if (gDesc.containsKey(id) || hasCompUpdate) {
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
    } else if (addr.contains('dashboard/dashboard')) {
      if (resp is List) {
        for (final day in resp) {
          for (final di in (day['items'] as List? ?? [])) {
            if (di['type'] == 'observation') {
              final id = di['id'] as int;
              if (obsSub.containsKey(id)) {
                di['subtitle'] = obsSub[id];
                cntDash++;
              }
            } else if (di['type'] == 'gradeGroup') {
              final id = di['id'] as int;
              if (hwSub.containsKey(id)) {
                di['subtitle'] = hwSub[id];
                cntDash++;
              }
            }
          }
        }
      }
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

  print('Done. getGrade: $cntGrade | subject_detail: $cntDetail | dashboard obs: $cntDash');
}
