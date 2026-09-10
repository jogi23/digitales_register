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

import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/course_content_provider.dart';
import 'package:flutter/material.dart';

/// Das Material eines Fachs: Themen, darunter ihre Einträge.
class CourseContentPage extends StatelessWidget {
  final List<CourseSubject> subjects;
  final CourseContentState state;

  /// Das Kürzel eines Fachs für die Auswahl oben.
  final String Function(String subject) subjectLabel;

  final ValueChanged<CourseSubject> onSubjectSelected;
  final ValueChanged<CourseEntry> onEntrySelected;

  const CourseContentPage({
    super.key,
    required this.subjects,
    required this.state,
    required this.subjectLabel,
    required this.onSubjectSelected,
    required this.onEntrySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (subjects.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final subject in subjects)
                  ChoiceChip(
                    label: Text(subjectLabel(subject.name)),
                    tooltip: subject.name,
                    selected: state.subject == subject,
                    showCheckmark: false,
                    onSelected: (_) => onSubjectSelected(subject),
                  ),
              ],
            ),
          ),
        const Divider(),
        Expanded(child: _Inhalt(state: state, onEntry: onEntrySelected)),
      ],
    );
  }
}

class _Inhalt extends StatelessWidget {
  final CourseContentState state;
  final ValueChanged<CourseEntry> onEntry;

  const _Inhalt({required this.state, required this.onEntry});

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _Meldung(text: tr(context).courseContentFailed);
    }
    final course = state.course;
    if (course == null) {
      return _Meldung(text: tr(context).courseContentPickSubject);
    }
    // Der Server antwortet mit id 0, wenn für Klasse und Fach nichts
    // angelegt ist. Das ist kein Fehler, sondern eine Auskunft.
    if (!course.exists || course.topics.isEmpty) {
      return _Meldung(text: tr(context).courseContentEmpty);
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom,
      ),
      itemCount: course.topics.length,
      itemBuilder: (context, index) {
        final topic = course.topics[index];
        return ExpansionTile(
          initiallyExpanded: course.topics.length == 1,
          title: Text(topic.title),
          subtitle: Text(tr(context).courseContentEntryCount(
            topic.entries.length,
          )),
          children: [
            for (final entry in topic.entries)
              _EntryTile(entry: entry, onTap: () => onEntry(entry)),
          ],
        );
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  final CourseEntry entry;
  final VoidCallback onTap;

  const _EntryTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(
        switch (entry.type) {
          CourseEntryType.file => Icons.insert_drive_file,
          CourseEntryType.link => Icons.link,
          CourseEntryType.text => Icons.notes,
          CourseEntryType.unknown => Icons.help_outline,
        },
        color: theme.colorScheme.primary,
      ),
      title: Text(entry.title),
      // Eine unbekannte Art lässt sich nicht sinnvoll öffnen; sie stehen zu
      // lassen ist ehrlicher, als sie zu verschweigen.
      enabled: entry.type != CourseEntryType.unknown,
      onTap: onTap,
    );
  }
}

class _Meldung extends StatelessWidget {
  final String text;

  const _Meldung({required this.text});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
}

/// Zeigt den Text eines Eintrags, der keine Datei und kein Link ist.
Future<void> showCourseText(BuildContext context, CourseEntry entry) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.title),
        content: SingleChildScrollView(
          child: SelectableText(entry.text ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context).commonOk),
          ),
        ],
      ),
    );
