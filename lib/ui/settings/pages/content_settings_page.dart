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
import 'package:dr/ui/settings/blocks/grades_block.dart';
import 'package:dr/ui/settings/blocks/homework_blocks.dart';
import 'package:dr/ui/settings/blocks/subjects_calendar_block.dart';
import 'package:dr/ui/settings/widgets/settings_expandable_section.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:flutter/material.dart';

/// The groups of the content page, in the order it lists them.
enum ContentBlock {
  subjectsCalendar,
  merkheft,
  classbook,
  overview,
  absences,
  grades,
}

/// How the app shows what the school provides: subjects, calendar, homework
/// diary, class register, overview, absences and grades — each behind a header
/// of its own.
class ContentSettingsPage extends StatefulWidget {
  const ContentSettingsPage({
    super.key,
    this.initiallyExpanded = const {},
  });

  /// The blocks that start open; the others start closed. The first of them
  /// is scrolled into view.
  final Set<ContentBlock> initiallyExpanded;

  @override
  State<ContentSettingsPage> createState() => _ContentSettingsPageState();
}

class _ContentSettingsPageState extends State<ContentSettingsPage> {
  final _positions = {
    for (final block in ContentBlock.values) block: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    // With six headers and one block open, the one asked for can sit below
    // the fold on a small screen or with large text.
    final target = ContentBlock.values
        .where(widget.initiallyExpanded.contains)
        .firstOrNull;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _positions[target]!.currentContext;
      if (context != null) Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final blocks =
        <ContentBlock, ({String title, String summary, Widget body})>{
      ContentBlock.subjectsCalendar: (
        title: l.settingsBlockSubjectsCalendar,
        summary: l.settingsBlockSummarySubjectsCalendar,
        body: const SubjectsCalendarBlock(),
      ),
      ContentBlock.merkheft: (
        title: l.settingsSectionHomework,
        summary: l.settingsBlockSummaryMerkheft,
        body: const MerkheftBlock(),
      ),
      ContentBlock.classbook: (
        title: l.settingsClassbook,
        summary: l.settingsBlockSummaryEntryView,
        body: const ClassbookBlock(),
      ),
      ContentBlock.overview: (
        title: l.settingsHomeworkOverview,
        summary: l.settingsBlockSummaryEntryView,
        body: const OverviewBlock(),
      ),
      ContentBlock.absences: (
        title: l.settingsAbsences,
        summary: l.settingsBlockSummaryAbsences,
        body: const AbsencesBlock(),
      ),
      ContentBlock.grades: (
        title: l.settingsSectionGrades,
        summary: l.settingsBlockSummaryGrades,
        body: const GradesBlock(),
      ),
    };
    return SettingsPageScaffold(
      title: l.settingsCategoryContent,
      // Six headers: all built, so the block asked for can be scrolled to.
      cacheExtent: 4000,
      children: [
        for (final entry in blocks.entries)
          KeyedSubtree(
            key: _positions[entry.key],
            child: SettingsExpandableSection(
              // Remembers whether it is open while it is scrolled out of the
              // lazily built list.
              key: PageStorageKey(entry.key),
              title: entry.value.title,
              summary: entry.value.summary,
              initiallyExpanded: widget.initiallyExpanded.contains(entry.key),
              children: [entry.value.body],
            ),
          ),
      ],
    );
  }
}
