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
  grades;

  String title(BuildContext context) {
    final l = tr(context);
    return switch (this) {
      subjectsCalendar => l.settingsBlockSubjectsCalendar,
      merkheft => l.settingsSectionHomework,
      classbook => l.settingsClassbook,
      overview => l.settingsHomeworkOverview,
      absences => l.settingsAbsences,
      grades => l.settingsSectionGrades,
    };
  }

  /// What is in the block, so a closed one still says so.
  String summary(BuildContext context) {
    final l = tr(context);
    return switch (this) {
      subjectsCalendar => l.settingsBlockSummarySubjectsCalendar,
      merkheft => l.settingsBlockSummaryMerkheft,
      classbook || overview => l.settingsBlockSummaryEntryView,
      absences => l.settingsBlockSummaryAbsences,
      grades => l.settingsBlockSummaryGrades,
    };
  }

  Widget get body => switch (this) {
        subjectsCalendar => const SubjectsCalendarBlock(),
        merkheft => const MerkheftBlock(),
        classbook => const ClassbookBlock(),
        overview => const OverviewBlock(),
        absences => const AbsencesBlock(),
        grades => const GradesBlock(),
      };
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
  /// Marks the block that is scrolled to.
  final _target = GlobalKey();

  ContentBlock? get _targetBlock =>
      ContentBlock.values.where(widget.initiallyExpanded.contains).firstOrNull;

  @override
  void initState() {
    super.initState();
    // With six headers and one block open, the one asked for can sit below
    // the fold on a small screen or with large text.
    if (_targetBlock == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _target.currentContext;
      if (context != null) Scrollable.ensureVisible(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageScaffold(
      title: tr(context).settingsCategoryContent,
      children: [
        for (final block in ContentBlock.values)
          KeyedSubtree(
            key: block == _targetBlock ? _target : null,
            child: SettingsExpandableSection(
              title: block.title(context),
              summary: block.summary(context),
              initiallyExpanded: widget.initiallyExpanded.contains(block),
              children: [block.body],
            ),
          ),
      ],
    );
  }
}
