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
import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// One line of the classbook: what was taught in a single lesson.
///
/// Flattened out of the calendar, where the same entries sit inside their
/// hour. The classbook asks a different question — "what did we do in
/// German lately" — and that answer is spread across days there.
/// Die Art, die fast jeder Eintrag trägt; nur Abweichungen sind erwähnenswert.
const ordinaryLessonType = 'Fachunterricht';

class ClassbookEntry {
  final UtcDateTime date;
  final int fromHour;
  final String subject;
  final List<String> teachers;
  final LessonContent content;

  const ClassbookEntry({
    required this.date,
    required this.fromHour,
    required this.subject,
    required this.teachers,
    required this.content,
  });
}

/// Every lesson content in [days], newest lesson first.
///
/// Hours without an entry are left out: an empty lesson says nothing, and
/// carrying it would bury the ones that do.
List<ClassbookEntry> classbookEntries(Iterable<CalendarDay> days) {
  final entries = <ClassbookEntry>[
    for (final day in days)
      for (final hour in day.hours)
        for (final content in hour.lessonContents)
          ClassbookEntry(
            date: day.date,
            fromHour: hour.fromHour,
            subject: hour.subject,
            teachers: [
              for (final teacher in hour.teachers) teacher.fullName,
            ],
            content: content,
          ),
  ];
  entries.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    return byDate != 0 ? byDate : a.fromHour.compareTo(b.fromHour);
  });
  return entries;
}

/// The subjects that actually carry entries, alphabetically.
List<String> classbookSubjects(List<ClassbookEntry> entries) {
  final subjects = {for (final entry in entries) entry.subject}.toList();
  subjects.sort();
  return subjects;
}

class ClassbookPage extends StatelessWidget {
  final List<ClassbookEntry> entries;
  final ClassbookViewMode viewMode;
  final bool loading;

  /// Die gewählten Fächer; leer heißt alle.
  ///
  /// Sie liegt in den Einstellungen und damit beim Konto, nicht im Widget:
  /// Wer sie einmal gesetzt hat, findet sie beim nächsten Öffnen wieder.
  final List<String> selectedSubjects;
  final ValueChanged<List<String>> onSelectedSubjectsChanged;

  /// Das Kürzel eines Fachs, für die Chips der Mehrfachauswahl.
  ///
  /// Gereicht statt selbst nachgeschlagen: Die Kürzel liegen in einem
  /// Provider, und die Seite bleibt ohne einen prüfbar.
  final String Function(String subject) subjectLabel;

  const ClassbookPage({
    super.key,
    required this.entries,
    required this.viewMode,
    required this.selectedSubjects,
    required this.onSelectedSubjectsChanged,
    required this.subjectLabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            loading
                ? tr(context).classbookLoading
                : tr(context).classbookEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Ein Fach, das keine Einträge mehr hat, würde die Liste leeren, ohne
    // dass ein Grund zu sehen wäre.
    final vorhanden = classbookSubjects(entries);
    final gewaehlt =
        selectedSubjects.where(vorhanden.contains).toList();

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
                entries: gewaehlt.isEmpty
                    ? entries
                    : entries
                        .where((e) => gewaehlt.contains(e.subject))
                        .toList(),
              ),
            ),
          ],
        ),
      ClassbookViewMode.bySubject => _BySubject(entries: entries),
    };
  }
}

/// Day after day, newest first — the shape the homework list already uses.
class _ByDay extends StatelessWidget {
  final List<ClassbookEntry> entries;

  const _ByDay({required this.entries});

  @override
  Widget build(BuildContext context) {
    final byDate = <UtcDateTime, List<ClassbookEntry>>{};
    for (final entry in entries) {
      byDate.putIfAbsent(entry.date, () => []).add(entry);
    }
    final dates = byDate.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: dates.length,
      itemBuilder: (context, index) {
        final date = dates[index];
        return _DaySection(date: date, entries: byDate[date]!);
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  final UtcDateTime date;
  final List<ClassbookEntry> entries;

  const _DaySection({required this.date, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            DateFormat("EEEE, d. MMMM y", tr(context).localeName)
                .format(date),
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        for (final entry in entries) _EntryTile(entry: entry, showDate: false),
        const Divider(height: 1),
      ],
    );
  }
}

/// One expandable row per subject, its entries underneath.
class _BySubject extends StatelessWidget {
  final List<ClassbookEntry> entries;

  const _BySubject({required this.entries});

  @override
  Widget build(BuildContext context) {
    final bySubject = <String, List<ClassbookEntry>>{};
    for (final entry in entries) {
      bySubject.putIfAbsent(entry.subject, () => []).add(entry);
    }
    final subjects = bySubject.keys.toList()..sort();

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final own = bySubject[subject]!;
        return ExpansionTile(
          title: Text(subject),
          subtitle: Text(tr(context).classbookEntryCount(own.length)),
          children: [
            for (final entry in own) _EntryTile(entry: entry, showDate: true),
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
  final ClassbookEntry entry;

  /// The day headline already carries the date when the entries are grouped
  /// by day; grouped by subject there is none.
  final bool showDate;

  const _EntryTile({required this.entry, required this.showDate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final untertitel = <String>[
      if (showDate)
        DateFormat("EE d.M.yy", tr(context).localeName)
            .format(entry.date),
      if (!showDate) entry.subject,
      "${entry.fromHour}. h",
      if (entry.teachers.isNotEmpty) entry.teachers.join(", "),
      // Die Art nur, wenn sie vom Regelfall abweicht: Sie steht sonst an
      // jeder einzelnen Zeile und engt den eigentlichen Eintrag ein.
      if (entry.content.typeName.isNotEmpty &&
          entry.content.typeName != ordinaryLessonType)
        entry.content.typeName,
    ];

    return ListTile(
      dense: true,
      leading: Icon(Icons.school, color: theme.colorScheme.primary),
      title: Text(entry.content.name),
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
