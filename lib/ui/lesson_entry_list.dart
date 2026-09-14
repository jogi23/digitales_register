// Copyright (C) 2026 Johannes Feichter
//
// This file is part of digitales_register.
//
// digitales_register is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// digitales_register is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with digitales_register.  If not, see <http://www.gnu.org/licenses/>.

import 'package:dr/app_state.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/ui/entry_card.dart';
import 'package:dr/ui/layout.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Eine Zeile über eine einzelne Stunde: was darin unterrichtet oder
/// aufgegeben wurde.
///
/// Flach gezogen aus dem Kalender, wo dieselben Angaben in ihrer Stunde
/// stecken. Klassenbuch und Hausaufgaben-Übersicht stellen eine andere
/// Frage — "was hatten wir zuletzt in Deutsch" —, und deren Antwort liegt
/// dort über Tage verstreut.
class LessonEntry {
  final UtcDateTime date;
  final int fromHour;

  /// Die letzte Stunde, wenn die Einheit über mehrere geht; sonst [fromHour].
  final int toHour;

  /// Beginn und Ende laut Stundenplan. Ältere gespeicherte Stände haben sie
  /// nicht; dann bleibt die Uhrzeit weg.
  final UtcDateTime? from;
  final UtcDateTime? to;

  final String subject;
  final List<String> teachers;

  /// Was in der Zeile steht - der Unterrichtseintrag oder die Aufgabe.
  final String title;

  /// Die Art, wie sie der Server nennt: "Fachunterricht", "Hausaufgabe",
  /// "Mündliche Prüfung".
  final String typeName;

  const LessonEntry({
    required this.date,
    required this.fromHour,
    int? toHour,
    this.from,
    this.to,
    required this.subject,
    required this.teachers,
    required this.title,
    required this.typeName,
  }) : toHour = toHour ?? fromHour;
}

/// The subjects that actually carry entries, alphabetically.
List<String> entrySubjects(List<LessonEntry> entries) {
  final subjects = {for (final entry in entries) entry.subject}.toList();
  subjects.sort();
  return subjects;
}

/// Die Einträge einer Stunde beisammen: Zwei Inhalte derselben Stunde sind
/// eine Karte und ein Punkt auf der Zeitleiste, nicht zwei.
///
/// Erwartet [entries] so sortiert, wie sie aus dem Kalender kommen - die
/// Einträge einer Stunde stehen dann nebeneinander.
List<List<LessonEntry>> lessonsOf(List<LessonEntry> entries) {
  final lessons = <List<LessonEntry>>[];
  for (final entry in entries) {
    final previous = lessons.isEmpty ? null : lessons.last.first;
    if (previous != null &&
        previous.date == entry.date &&
        previous.fromHour == entry.fromHour &&
        previous.subject == entry.subject) {
      lessons.last.add(entry);
    } else {
      lessons.add([entry]);
    }
  }
  return lessons;
}

/// Whether [lesson] is over at [at] (default: now) — by its end time where
/// the timetable has one, otherwise by its day.
bool lessonIsOver(List<LessonEntry> lesson, {UtcDateTime? at}) {
  final moment = at ?? now;
  final end = lesson.last.to;
  if (end != null) return end.isBefore(moment);
  return lesson.last.date
      .isBefore(UtcDateTime(moment.year, moment.month, moment.day));
}

class LessonEntryList extends StatelessWidget {
  final List<LessonEntry> entries;
  final ClassbookViewMode viewMode;

  /// Liste, Karten oder Zeitleiste. Die Zeitleiste zeigt einen Tagesablauf
  /// und gibt es deshalb nur nach Tagen; nach Fach werden daraus Karten.
  final EntryDisplayMode displayMode;
  final bool loading;

  /// Die gewählten Fächer; leer heißt alle.
  ///
  /// Sie liegt in den Einstellungen und damit beim Konto, nicht im Widget:
  /// Wer sie einmal gesetzt hat, findet sie beim nächsten Öffnen wieder.
  final List<String> selectedSubjects;
  final ValueChanged<List<String>> onSelectedSubjectsChanged;

  /// Was steht, solange nichts geladen ist, und was, wenn nichts da ist.
  final String loadingText;
  final String emptyText;

  /// Die Art, die fast jeder Eintrag trägt; nur Abweichungen davon sind
  /// erwähnenswert und stehen dann im Untertitel.
  final String ordinaryType;

  /// Das Kürzel eines Fachs, für die Chips der Mehrfachauswahl.
  ///
  /// Gereicht statt selbst nachgeschlagen: Die Kürzel liegen in einem
  /// Provider, und die Seite bleibt ohne einen prüfbar.
  final String Function(String subject) subjectLabel;

  const LessonEntryList({
    super.key,
    required this.entries,
    required this.viewMode,
    this.displayMode = EntryDisplayMode.list,
    required this.selectedSubjects,
    required this.onSelectedSubjectsChanged,
    required this.subjectLabel,
    required this.loadingText,
    required this.emptyText,
    required this.ordinaryType,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loading ? loadingText : emptyText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Ein Fach, das keine Einträge mehr hat, würde die Liste leeren, ohne
    // dass ein Grund zu sehen wäre.
    final vorhanden = entrySubjects(entries);
    final gewaehlt = selectedSubjects.where(vorhanden.contains).toList();

    return switch (viewMode) {
      ClassbookViewMode.chronological => Column(
          children: [
            _SubjectFilter(
              subjects: vorhanden,
              selected: gewaehlt,
              onChanged: onSelectedSubjectsChanged,
              label: subjectLabel,
            ),
            Expanded(
              child: _ByDay(
                ordinaryType: ordinaryType,
                displayMode: displayMode,
                entries: gewaehlt.isEmpty
                    ? entries
                    : entries
                        .where((e) => gewaehlt.contains(e.subject))
                        .toList(),
              ),
            ),
          ],
        ),
      ClassbookViewMode.bySubject => _BySubject(
          entries: entries,
          ordinaryType: ordinaryType,
          displayMode: displayMode == EntryDisplayMode.timeline
              ? EntryDisplayMode.cards
              : displayMode,
        ),
    };
  }
}

/// Day after day, newest first — the shape the homework list already uses.
class _ByDay extends StatelessWidget {
  final List<LessonEntry> entries;
  final String ordinaryType;
  final EntryDisplayMode displayMode;

  const _ByDay({
    required this.entries,
    required this.ordinaryType,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    final byDate = <UtcDateTime, List<LessonEntry>>{};
    for (final entry in entries) {
      byDate.putIfAbsent(entry.date, () => []).add(entry);
    }
    final dates = byDate.keys.toList();

    // Jeder Tag eine eigene Gruppe: Seine Überschrift bleibt beim Scrollen
    // oben stehen, bis der nächste Tag sie hinausschiebt - bei einem langen
    // Tag ist so immer zu sehen, zu welchem die Zeilen gehören.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: context.systemInsets,
          sliver: SliverMainAxisGroup(
            slivers: [
              for (final date in dates)
                SliverMainAxisGroup(
                  slivers: [
                    PinnedHeaderSliver(child: _DayHeader(date: date)),
                    SliverToBoxAdapter(
                      child: _DaySection(
                        entries: byDate[date]!,
                        ordinaryType: ordinaryType,
                        displayMode: displayMode,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Die Überschrift eines Tages als farbiges Band über die volle Breite.
///
/// Ein Band statt nur farbiger Schrift: Die Zeilen darunter wechseln zwischen
/// weiß und grau, und ohne Band lief ein Tag, der mit einer weißen Zeile
/// endet, in den nächsten über, der weiß beginnt.
class _DayHeader extends StatelessWidget {
  final UtcDateTime date;

  const _DayHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: ColoredBox(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            DateFormat("EEEE, d. MMMM y", tr(context).localeName).format(date),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// What one day holds, below its [_DayHeader].
class _DaySection extends StatelessWidget {
  final List<LessonEntry> entries;
  final String ordinaryType;
  final EntryDisplayMode displayMode;

  const _DaySection({
    required this.entries,
    required this.ordinaryType,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    final tint = alternateRowColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...switch (displayMode) {
          EntryDisplayMode.list => [
              for (final (i, entry) in entries.indexed)
                _EntryTile(
                  entry: entry,
                  showDate: false,
                  ordinaryType: ordinaryType,
                  tileColor: i.isOdd ? tint : null,
                ),
            ],
          EntryDisplayMode.cards => [
              for (final lesson in lessonsOf(entries))
                _LessonCard(
                  lesson: lesson,
                  showDate: false,
                  ordinaryType: ordinaryType,
                ),
            ],
          EntryDisplayMode.timeline => [
              _Timeline(
                lessons: lessonsOf(entries),
                ordinaryType: ordinaryType,
              ),
            ],
        },
      ],
    );
  }
}

/// One expandable row per subject, its entries underneath.
class _BySubject extends StatelessWidget {
  final List<LessonEntry> entries;
  final String ordinaryType;

  /// List or cards; the timeline has no day to show here.
  final EntryDisplayMode displayMode;

  const _BySubject({
    required this.entries,
    required this.ordinaryType,
    required this.displayMode,
  });

  @override
  Widget build(BuildContext context) {
    final bySubject = <String, List<LessonEntry>>{};
    for (final entry in entries) {
      bySubject.putIfAbsent(entry.subject, () => []).add(entry);
    }
    final subjects = bySubject.keys.toList()..sort();
    final tint = alternateRowColor(context);

    return ListView.builder(
      padding: context.systemInsets,
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final own = bySubject[subject]!;
        return ExpansionTile(
          title: Text(subject),
          subtitle: Text(tr(context).classbookEntryCount(own.length)),
          children: [
            if (displayMode == EntryDisplayMode.cards)
              for (final lesson in lessonsOf(own))
                _LessonCard(
                  lesson: lesson,
                  showDate: true,
                  ordinaryType: ordinaryType,
                )
            else
              for (final (i, entry) in own.indexed)
                _EntryTile(
                  entry: entry,
                  showDate: true,
                  ordinaryType: ordinaryType,
                  tileColor: i.isOdd ? tint : null,
                ),
          ],
        );
      },
    );
  }
}

/// Mehrfachauswahl der Fächer als Chips.
///
/// Chips statt eines Auswahlfeldes, weil bei mehreren gewählten Fächern
/// sonst nirgends stünde, welche es sind - ein Auswahlfeld zeigt immer nur
/// einen Wert.
class _SubjectFilter extends StatelessWidget {
  final List<String> subjects;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String Function(String subject) label;

  const _SubjectFilter({
    required this.subjects,
    required this.selected,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilterChip(
            label: Text(tr(context).classbookAllSubjects),
            selected: selected.isEmpty,
            showCheckmark: false,
            // Erneutes Antippen der bereits leeren Auswahl ändert nichts;
            // "alle" ist kein Zustand, den man abwählen könnte.
            onSelected: (_) => onChanged(const []),
          ),
          for (final subject in subjects)
            FilterChip(
              // Das Kürzel: Bei zehn Fächern nebeneinander füllen die vollen
              // Namen mehrere Zeilen, und die Liste rückt nach unten weg.
              label: Text(label(subject)),
              tooltip: subject,
              selected: selected.contains(subject),
              showCheckmark: false,
              onSelected: (an) => onChanged([
                for (final s in subjects)
                  if (s == subject ? an : selected.contains(s)) s,
              ]),
            ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LessonEntry entry;

  /// The day headline already carries the date when the entries are grouped
  /// by day; grouped by subject there is none.
  final bool showDate;

  final String ordinaryType;

  /// Every second row is tinted, so a long entry text does not run into the
  /// next one.
  final Color? tileColor;

  const _EntryTile({
    required this.entry,
    required this.showDate,
    required this.ordinaryType,
    this.tileColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final untertitel = <String>[
      if (showDate)
        DateFormat("EE d.M.yy", tr(context).localeName).format(entry.date),
      if (!showDate) entry.subject,
      "${entry.fromHour}. h",
      if (entry.teachers.isNotEmpty) entry.teachers.join(", "),
      // Die Art nur, wenn sie vom Regelfall abweicht: Sie steht sonst an
      // jeder einzelnen Zeile und engt den eigentlichen Eintrag ein.
      if (entry.typeName.isNotEmpty && entry.typeName != ordinaryType)
        entry.typeName,
    ];

    return ListTile(
      dense: true,
      tileColor: tileColor,
      leading: Icon(Icons.school, color: theme.colorScheme.primary),
      title: Text(entry.title),
      // Hervorgehoben, weil hier das Suchbare steht: Fach, Stunde,
      // Lehrperson. Der Eintragstext darüber ist oft lang, und ohne
      // Absetzung verschwimmt die Zuordnung zwischen den Zeilen.
      subtitle: Text(
        untertitel.join(" · "),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "1", or "1–2" for a lesson over two hours.
String _hours(List<LessonEntry> lesson) {
  final from = lesson.first.fromHour, to = lesson.last.toHour;
  return from == to ? '$from' : '$from–$to';
}

/// "07:50–08:45", or null when the timetable carried no times.
String? _times(BuildContext context, List<LessonEntry> lesson) {
  final from = lesson.first.from, to = lesson.last.to;
  if (from == null || to == null) return null;
  final format = DateFormat.Hm(tr(context).localeName);
  return '${format.format(from)}–${format.format(to)}';
}

/// What a card and a point on the timeline say about one lesson: time,
/// subject, every entry of it, and who taught.
class _LessonDetails extends StatelessWidget {
  final List<LessonEntry> lesson;

  /// Grouped by subject, the date takes the place of the subject.
  final bool showDate;
  final String ordinaryType;

  /// The timeline sets the time on a line of its own above the subject; a
  /// card has room for both side by side.
  final bool timeAbove;

  const _LessonDetails({
    required this.lesson,
    required this.showDate,
    required this.ordinaryType,
    required this.timeAbove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final first = lesson.first;
    final times = _times(context, lesson);
    final headline = showDate
        ? DateFormat("EE d.M.yy", tr(context).localeName).format(first.date)
        : first.subject;
    final headlineStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final timeStyle = theme.textTheme.bodyMedium?.copyWith(color: muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (timeAbove) ...[
          if (times != null) Text(times, style: timeStyle),
          Text(headline, style: headlineStyle),
        ] else
          Text.rich(
            TextSpan(
              children: [
                if (times != null)
                  TextSpan(text: '$times   ', style: timeStyle),
                TextSpan(text: headline, style: headlineStyle),
              ],
            ),
          ),
        for (final entry in lesson) ...[
          const SizedBox(height: 4),
          Text(entry.title, style: theme.textTheme.bodyLarge),
          if (entry.typeName.isNotEmpty && entry.typeName != ordinaryType)
            Text(
              entry.typeName,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
        ],
        if (first.teachers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.how_to_reg_outlined, size: 18, color: muted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  first.teachers.join(', '),
                  style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final List<LessonEntry> lesson;
  final bool showDate;
  final String ordinaryType;

  const _LessonCard({
    required this.lesson,
    required this.showDate,
    required this.ordinaryType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return EntryCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(
              _hours(lesson),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: _LessonDetails(
              lesson: lesson,
              showDate: showDate,
              ordinaryType: ordinaryType,
              timeAbove: false,
            ),
          ),
        ],
      ),
    );
  }
}

/// The lessons of one day down a line, a circle per lesson.
class _Timeline extends StatelessWidget {
  final List<List<LessonEntry>> lessons;
  final String ordinaryType;

  const _Timeline({required this.lessons, required this.ordinaryType});

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          for (final (i, lesson) in lessons.indexed)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        TimelineDot(
                          label: _hours(lesson),
                          over: lessonIsOver(lesson),
                        ),
                        if (i < lessons.length - 1)
                          Expanded(child: Container(width: 2, color: line)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: i < lessons.length - 1 ? 24 : 0,
                      ),
                      child: _LessonDetails(
                        lesson: lesson,
                        showDate: false,
                        ordinaryType: ordinaryType,
                        timeAbove: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The circle of one lesson on the timeline: filled green once the lesson is
/// over, an outline while it runs or is still to come.
class TimelineDot extends StatelessWidget {
  final String label;
  final bool over;

  const TimelineDot({super.key, required this.label, required this.over});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final green = Colors.green.shade600;
    return Container(
      height: 28,
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: over ? green.withValues(alpha: 0.2) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: over
            ? null
            : Border.all(color: theme.colorScheme.outline, width: 2),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: over ? green : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
