# Updates demo texts in assets/demo/capture.json.
# Run from repo root: powershell -File tool/update_demo_texts.ps1

$ErrorActionPreference = 'Stop'
$captureFile = Resolve-Path (Join-Path $PSScriptRoot '..\assets\demo\capture.json')

$json = [System.IO.File]::ReadAllText($captureFile, [System.Text.Encoding]::UTF8)
$data = $json | ConvertFrom-Json

# ─── Grade descriptions (entry/getGrade + subject_detail) by gradeId ─────────
$gDesc = @{
    13278 = "Max stellt seinen Lösungsweg klar und nachvollziehbar vor. Er hört anderen aufmerksam zu und bringt eigene Ideen ein."
    42098 = "Die Fingerbilder werden sicher und schnell erkannt. Max nennt die Anzahl direkt, ohne einzeln zu zählen."
    39256 = "Max arbeitet mit Freude und Ausdauer an den Bastelarbeiten. Die Ergebnisse sind kreativ und sorgfältig ausgeführt."
    98696 = "Max setzt sich offen mit dem Thema auseinander und bringt persönliche Gedanken ein."
    81482 = "Sehr präzise und geduldige Faltarbeit. Die Knicke sitzen exakt und das Ergebnis ist ordentlich."
    21395 = "Additionsaufgaben mit +0 und +1 werden sicher und selbstständig gelöst."
    87397 = "Max löst die 10er-Minusaufgaben zuverlässig. Die Strategie ist gut eingeübt."
    65302 = "Vergleichszeichen werden korrekt eingesetzt. Max erkennt Zahlenbeziehungen sicher."
    14165 = "Einfache Subtraktionsaufgaben werden konzentriert und methodisch bearbeitet."
    13905 = "Das Konzept der Kraft der 5 ist verstanden. Erste Aufgaben werden sicher gelöst."
    22280 = "Sorgfältige Faltarbeit. Anweisungen werden Schritt für Schritt umgesetzt."
    38657 = "Geometrische Körper werden richtig erkannt, benannt und nach Merkmalen sortiert."
    40495 = "Max zählt sicher vorwärts und rückwärts. Das flexible Weiterzählen von beliebigen Zahlen gelingt zuverlässig."
    76237 = "Das Forschungsprojekt ist liebevoll gestaltet. Max präsentiert sein Thema mit Begeisterung und gutem Fachwissen."
    88907 = "Additionsaufgaben wurden selbstständig und korrekt bearbeitet. Max arbeitet konzentriert."
    13478 = "Max nimmt engagiert am Sportunterricht teil. Er hält die Regeln ein und unterstützt die Gruppe."
    83563 = "Die Lesehausaufgabe wurde zuverlässig erledigt. Max liest zunehmend flüssiger."
    36062 = "Auch die zweite Seite wurde vollständig bearbeitet. Wörter werden sicher und korrekt gelesen."
    46421 = "Das Heft ist vollständig und sorgfältig geführt. Einträge sind klar und übersichtlich gestaltet."
    54597 = "Max gibt die Geschichte anschaulich wieder und erfasst die Botschaft vom Vertrauen gut."
    32431 = "Max meldet sich regelmäßig und beteiligt sich aktiv an Unterrichtsgesprächen. Seine Beiträge sind treffend."
    33416 = "Gute Mitarbeit. Max hört aufmerksam zu und bringt passende Gedanken ein."
    65392 = "Das Forschungsprojekt ist ansprechend gestaltet und gut recherchiert. Max präsentiert sein Thema souverän."
}

# ─── Competence descriptions by "gradeId|typeName" ───────────────────────────
$cDesc = @{
    "93810|Zahl: Orientierung im Zahlenraum 12"          = "Zahlen bis 12 werden sicher erkannt und der Reihe nach geordnet."
    "39256|Kreative Gestaltung"                           = "Kreative Ideen werden eigenständig umgesetzt und ansprechend präsentiert."
    "98696|Einzigartigkeit"                               = "Das Thema wurde mit Offenheit und persönlichem Engagement erarbeitet."
    "81482|Geometrie"                                     = "Geometrische Formen werden korrekt erkannt und präzise dargestellt."
    "40495|Zahl: zählen, vergleichen und ordnen"          = "Zahlenreihen werden sicher beherrscht und zuverlässig angewendet."
    "76237|Auseinandersetzung mit einem persönlichen Thema" = "Das Thema wurde selbstständig erarbeitet und anschaulich aufbereitet."
    "13478|Bewegungs- und Sportspiele: Sportspielen teil" = "Spielregeln werden eingehalten; das Spiel wird kooperativ mitgestaltet."
    "83563|Lesen: die Buchstaben erkennen und richtig lesen" = "Buchstaben werden sicher erkannt und korrekt gelesen."
    "36062|Lesen: Wörter lesen und verstehen"             = "Wörter werden korrekt gelesen und der Inhalt wird gut verstanden."
    "46421|Heftführung"                                   = "Hefteinträge sind vollständig, sauber und gut gestaltet."
    "54597|Daniel in der Löwengrube"                      = "Die Botschaft der Geschichte wurde erkannt und verständlich wiedergegeben."
    "32431|Mündliche Mitarbeit"                           = "Regelmäßige und wertvolle Beteiligung am Unterrichtsgespräch."
    "33416|Mündliche Mitarbeit"                           = "Beiträge sind passend und zeigen ein gutes Verständnis der Themen."
    "65392|Auseinandersetzung mit einem persönlichen Thema" = "Gute Grundlagen sind vorhanden; diese werden weiter ausgebaut."
}

# ─── Observation notes (subject_detail) by observationId ─────────────────────
$obsNote = @{
    31417 = "Mündliche Mitarbeit März/April:`nMax beteiligt sich regelmäßig am Unterrichtsgespräch. Er formuliert seine Gedanken klar und hört anderen aufmerksam zu.`nDie Hausaufgaben werden zuverlässig erledigt und vollständig mitgebracht.`nIm Umgang mit Lernmaterialien zeigt Max Sorgfalt. Das Heft ist ordentlich geführt."
    66155 = "Sprechstunde mit dem Vater von Max.`nBesprochen wurde die Entwicklung im Unterricht sowie die Leistungen. Max macht gute Fortschritte, besonders im mündlichen Bereich.`nVereinbart: Übungsroutinen zu Hause beibehalten und auf vollständige Hefteinträge achten."
    76542 = "Mündliche Mitarbeit Januar/Februar:`nMax nimmt regelmäßig am Unterrichtsgespräch teil. Er meldet sich häufig und bringt gute Beiträge ein.`nAuch bei anspruchsvolleren Aufgaben gibt Max nicht auf. Er arbeitet ausdauernd und konzentriert.`nDas Arbeitstempo ist gut; Max schließt Aufgaben meist pünktlich ab."
    95909 = "Max geht respektvoll mit allen Mitschülerinnen und Mitschülern um. Er akzeptiert unterschiedliche Meinungen und sucht gemeinsam nach Lösungen.`nIn der Klasse verhält sich Max rücksichtsvoll. Er achtet auf die Bedürfnisse anderer und bietet Hilfe an.`nAuch in schwierigen Situationen zeigt Max gute Selbstkontrolle. Konflikte werden ruhig und sachlich gelöst."
}

# ─── Dashboard observation subtitles by observationId ────────────────────────
$obsSub = @{
    92397 = "Max comprende i contenuti proposti e li applica con sicurezza. Partecipa volent..."
    19358 = "Oggi mi sono impegnato a lavorare con attenzione e sono riuscito a finire tutto..."
    31417 = "Mündliche Mitarbeit März/April: Max beteiligt sich regelmäßig am Unterrichtsge..."
    84341 = "Max hatte heute einen schwierigen Tag. Die Konzentration fiel schwer, weshalb e..."
    95909 = "Max, heute hast du etwas Schönes gezeigt: Du hast einem Mitschüler geholfen, oh..."
    86622 = "Bitte Klebstoff nachkaufen."
    66155 = "Sprechstunde mit dem Vater von Max. Entwicklung im Unterricht und Leistungen be..."
    86484 = "Colloquio con il padre di Max. Si è parlato degli aspetti sociali e dell'impegno..."
    65333 = "Max, es könnte helfen, die Hausaufgaben gleichmäßig auf die Woche zu verteilen...."
    94012 = "Sprechstunde mit den Eltern von Max. Aktuelle Lernentwicklung und Sozialverhalt..."
    76542 = "Mündliche Mitarbeit Januar/Februar: Max nimmt regelmäßig am Unterrichtsgesprä..."
    91959 = "Max collabora in modo attivo durante le lezioni. Dimostra interesse e partecipaz..."
    59009 = "Max, in letzter Zeit läuft es richtig gut! Du freust dich selbst über deine Fort..."
    52487 = "Max arbeitet sehr konzentriert und in einem angemessenen Arbeitstempo. Er erledigt..."
    72296 = "Max, heute war ein schwieriger Tag. Du hast wenig geschafft und dich kaum konzen..."
    65461 = "Max arbeitet am besten, wenn er klare Aufgaben bekommt und den Ablauf kennt. Unt..."
    37760 = "Kinderrat: Es gelingt dir gut, an Kreisgesprächen teilzunehmen. Du bringst deine..."
    80686 = "Lieber Max, übe weiterhin das Eines-mehr und Eines-weniger, besonders mit dem +1..."
    67422 = "Mathematik: Hefteinträge zu den Ziffern bitte bis Montag fertig beenden."
    55082 = "Max mostra interesse e partecipa con entusiasmo alle attività della lezione."
    39451 = "Mündliche Mitarbeit November/Dezember: Max meldet sich regelmäßig und bringt gut..."
    18392 = "Heftführung: Deine Einträge sind vollständig und ordentlich gestaltet. Weiter so..."
    54313 = "Du zeigst Interesse an kreativen Aufgaben und arbeitest je nach Thema mit großem..."
    12757 = "Max, du beobachtest die Natur genau und stellst gute Fragen. Dein Interesse an n..."
    85525 = "Ich bemühe mich, ordentlich zu arbeiten und meine Aufgaben sorgfältig zu erledigen."
    66498 = "Sprechstunde mit dem Vater von Max. Sozial-, Lern- und Arbeitsverhalten besprochen."
    54473 = "September/Oktober: Max bringt sich gerne in den Unterricht ein und hält die Rege..."
    35112 = "Mündliche Mitarbeit September/Oktober: Max beteiligt sich an mündlichen Aktivität..."
    34931 = "Max bemüht sich beim Arbeiten konzentriert zu bleiben, gelingt dies aber nicht im..."
    80292 = "September/Oktober: Max beteiligt sich aktiv am mündlichen Unterricht und meldet s..."
    68800 = "Kann alle geübten Laute sicher benennen. Sehr gut! Weiter so!"
    63269 = "Kann alle geübten Laute den Bildern richtig zuordnen. Weiterhin fleißig üben!"
    62565 = "Kann alle geübten Laute mit Bildern verbinden: ä, ö, ü, Au, Ei, Eu."
    10282 = "Kann alle geübten Laute mit Bildern verbinden: A, E, I, O, U. Täglich weiterüben!"
    61173 = "- zählt fehlerfrei bis 30; - zählt flexibel weiter; - zählt sicher rückwärts von..."
}

# ─── Helper to update grades + competences ───────────────────────────────────
function Update-Grade($g) {
    $id = [int]$g.id
    if ($gDesc.ContainsKey($id)) { $g.description = $gDesc[$id] }
    foreach ($c in $g.competences) {
        $key = "$id|$($c.typeName)"
        if ($cDesc.ContainsKey($key)) { $c.description = $cDesc[$key] }
    }
}

# ─── Process ──────────────────────────────────────────────────────────────────
$cntGrade = 0; $cntDetail = 0; $cntDash = 0

foreach ($item in $data) {
    $addr = $item.address

    if ($addr -like '*entry/getGrade*') {
        $id = [int]$item.response.id
        if ($gDesc.ContainsKey($id)) {
            Update-Grade $item.response
            $cntGrade++
        }
    }
    elseif ($addr -like '*subject_detail*') {
        $respStr = $item.response
        if ($respStr -is [string] -and $respStr.Length -gt 5) {
            $inner = $respStr | ConvertFrom-Json
            $changed = $false
            foreach ($g in $inner.grades) {
                $before = $g.description
                Update-Grade $g
                if ($g.description -ne $before) { $changed = $true }
            }
            foreach ($o in $inner.observations) {
                $oId = [int]$o.id
                if ($obsNote.ContainsKey($oId)) {
                    $o.note = $obsNote[$oId] -replace '`n', [char]10
                    $changed = $true
                }
            }
            if ($changed) {
                $item.response = ($inner | ConvertTo-Json -Depth 10 -Compress)
                $cntDetail++
            }
        }
    }
    elseif ($addr -like '*dashboard/dashboard*') {
        foreach ($day in $item.response) {
            foreach ($di in $day.items) {
                if ($di.type -eq 'observation') {
                    $oId = [int]$di.id
                    if ($obsSub.ContainsKey($oId)) {
                        $di.subtitle = $obsSub[$oId]
                        $cntDash++
                    }
                }
            }
        }
    }
}

# ─── Write back ───────────────────────────────────────────────────────────────
$out = $data | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($captureFile, $out, [System.Text.Encoding]::UTF8)

Write-Host "Done. entry/getGrade updated: $cntGrade | subject_detail: $cntDetail | dashboard obs: $cntDash"
