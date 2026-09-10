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
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/providers/subject_appearance_provider.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/homework_overview_page.dart';
import 'package:dr/ui/lesson_entry_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';

class HomeworkOverviewContainer extends ConsumerWidget {
  const HomeworkOverviewContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(calendarProvider);
    final settings = ref.watch(settingsProvider);
    final appearance = ref.watch(subjectAppearanceProvider);
    // Dieselbe Quelle wie das Klassenbuch: Jede Kalenderwoche bringt die
    // Aufgaben schon mit, nur eine andere Liste je Stunde.
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: Text(tr(context).menuHomeworkOverview),
        actions: const [AccountAvatarButton()],
      ),
      body: LessonEntryList(
        entries: homeworkEntries(calendar.days.values),
        viewMode: settings.classbookViewMode,
        selectedSubjects: settings.classbookSubjects,
        onSelectedSubjectsChanged:
            ref.read(settingsProvider.notifier).setClassbookSubjects,
        subjectLabel: (subject) => appearance.nickFor(subject) ?? subject,
        loading: calendar.loadingWeeks.isNotEmpty,
        loadingText: tr(context).homeworkOverviewLoading,
        emptyText: tr(context).homeworkOverviewEmpty,
        ordinaryType: ordinaryHomeworkType,
      ),
    );
  }
}
