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
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/subject_appearance_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How subjects are named and coloured, and what the calendar shows of them.
class SubjectsCalendarBlock extends ConsumerWidget {
  const SubjectsCalendarBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(l.settingsNicksAndColors),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const SubjectAppearancePage(),
            ),
          ),
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.format_color_fill_rounded),
          title: Text(l.settingsColorLessons),
          value: s.calendarColorBackground,
          onChanged: notifier.setCalendarColorBackground,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.schedule_rounded),
          title: Text(l.settingsShowTimes),
          value: s.calendarShowTimes,
          onChanged: notifier.setCalendarShowTimes,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.unfold_more_rounded),
          title: Text(l.settingsShowAllDetails),
          subtitle: Text(l.settingsShowAllDetailsHint),
          value: s.calendarShowAllDetails,
          onChanged: notifier.setCalendarShowAllDetails,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.calendar_view_week_rounded),
          title: Text(l.settingsSixDayWeek),
          subtitle: Text(l.settingsSixDayWeekHint),
          value: s.sixDayWeek,
          onChanged: notifier.setSixDayWeek,
        ),
      ],
    );
  }
}
