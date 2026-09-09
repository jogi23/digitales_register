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

import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/classbook_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassbookPageContainer extends ConsumerWidget {
  const ClassbookPageContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(calendarProvider);
    // Der Kalender ist die Quelle: Jede geladene Woche bringt die Einträge
    // schon mit, das Klassenbuch ordnet sie nur anders an.
    return ClassbookPage(
      entries: classbookEntries(calendar.days.values),
      viewMode: ref.watch(settingsProvider).classbookViewMode,
      loading: calendar.loadingWeeks.isNotEmpty,
    );
  }
}
