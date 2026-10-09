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
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/widgets/settings_headers.dart';
import 'package:dr/ui/settings/widgets/settings_page_scaffold.dart';
import 'package:dr/ui/settings/widgets/view_option_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How homework, the class register and absences are laid out.
class HomeworkSettingsPage extends ConsumerWidget {
  const HomeworkSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return SettingsPageScaffold(
      title: l.settingsCategoryHomework,
      children: [
        SettingsSectionHeader(l.settingsSectionHomework),
        for (final entry in <DashboardViewMode, String>{
          DashboardViewMode.list: l.settingsViewList,
          DashboardViewMode.month: l.settingsViewMonth,
          DashboardViewMode.week: l.settingsViewWeek,
        }.entries)
          RadioListTile<DashboardViewMode>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: s.dashboardViewMode,
            onChanged: (mode) {
              if (mode != null) notifier.setDashboardViewMode(mode);
            },
          ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.fiber_new_rounded),
          title: Text(l.settingsMarkNewEntries),
          value: s.dashboardMarkNewOrChangedEntries,
          onChanged: notifier.setMarkNewOrChanged,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.content_copy_rounded),
          title: Text(l.settingsIgnoreDuplicates),
          value: s.dashboardDeduplicateEntries,
          onChanged: notifier.setDeduplicate,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.crop_square_rounded),
          title: Text(l.settingsFrameTestsRed),
          value: s.dashboardColorTestsInRed,
          onChanged: notifier.setDashboardColorTestsInRed,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.palette_outlined),
          title: Text(l.settingsColorHomework),
          value: s.dashboardColorBorders,
          onChanged: notifier.setDashboardColorBorders,
        ),
        SettingsSectionHeader(l.settingsClassbook),
        ArrangementTiles(
          value: s.classbookViewMode,
          onChanged: notifier.setClassbookViewMode,
        ),
        DisplayModeTiles(
          value: s.classbookDisplayMode,
          onChanged: notifier.setClassbookDisplayMode,
          offerTimeline: true,
          timelineEnabled:
              s.classbookViewMode == ClassbookViewMode.chronological,
        ),
        SettingsSectionHeader(l.settingsHomeworkOverview),
        ArrangementTiles(
          value: s.homeworkViewMode,
          onChanged: notifier.setHomeworkViewMode,
        ),
        DisplayModeTiles(
          value: s.homeworkDisplayMode,
          onChanged: notifier.setHomeworkDisplayMode,
        ),
        SettingsSectionHeader(l.settingsAbsences),
        DisplayModeTiles(
          value: s.absencesDisplayMode,
          onChanged: notifier.setAbsencesDisplayMode,
        ),
        SettingsSectionHeader(l.settingsSectionGeneral),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.delete_outline_rounded),
          title: Text(l.settingsAskWhenDeleting),
          value: s.askWhenDelete,
          onChanged: notifier.setAskWhenDelete,
        ),
      ],
    );
  }
}
