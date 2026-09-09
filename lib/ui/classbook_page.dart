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

class ClassbookPage extends StatefulWidget {
  final List<ClassbookEntry> entries;
  final ClassbookViewMode viewMode;
  final bool loading;

  const ClassbookPage({
    super.key,
    required this.entries,
    required this.viewMode,
    this.loading = false,
  });

  @override
  State<ClassbookPage> createState() => _ClassbookPageState();
}

class _ClassbookPageState extends State<ClassbookPage> {
  /// Null means every subject; only the filtered arrangement uses it.
  String? _subjectFilter;

  @override
  void didUpdateWidget(ClassbookPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A filter for a subject that has no entries any more would show an empty
    // page with no hint why.
    if (_subjectFilter != null &&
        !classbookSubjects(widget.entries).contains(_subjectFilter)) {
      _subjectFilter = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            widget.loading
                ? tr(context).classbookLoading
                : tr(context).classbookEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return switch (widget.viewMode) {
      ClassbookViewMode.chronological => _ByDay(entries: widget.entries),
      ClassbookViewMode.bySubject => _BySubject(entries: widget.entries),
      ClassbookViewMode.filtered => Column(
          children: [
            _SubjectFilter(
              subjects: classbookSubjects(widget.entries),
              selected: _subjectFilter,
              onChanged: (subject) =>
                  setState(() => _subjectFilter = subject),
            ),
            Expanded(
              child: _ByDay(
                entries: _subjectFilter == null
                    ? widget.entries
                    : widget.entries
                        .where((e) => e.subject == _subjectFilter)
                        .toList(),
              ),
            ),
          ],
        ),
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

class _SubjectFilter extends StatelessWidget {
  final List<String> subjects;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _SubjectFilter({
    required this.subjects,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DropdownButtonFormField<String?>(
        initialValue: selected,
        decoration: InputDecoration(
          labelText: tr(context).classbookSubjectFilter,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          DropdownMenuItem<String?>(
            child: Text(tr(context).classbookAllSubjects),
          ),
          for (final subject in subjects)
            DropdownMenuItem<String?>(value: subject, child: Text(subject)),
        ],
        onChanged: onChanged,
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
    ];

    return ListTile(
      dense: true,
      leading: Icon(Icons.school, color: theme.colorScheme.primary),
      title: Text(entry.content.name),
      subtitle: Text(untertitel.join(" · ")),
      trailing: entry.content.typeName.isEmpty
          ? null
          : Text(
              entry.content.typeName,
              style: theme.textTheme.labelSmall,
            ),
    );
  }
}
