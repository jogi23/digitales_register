// Copyright (C) 2021 Michael Debertol
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

import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/grades_chart_legend_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChartLegendEntryContainer extends ConsumerWidget {
  final String subjectName;

  const ChartLegendEntryContainer({super.key, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider).subjectThemes[subjectName];
    if (theme == null) return const SizedBox.shrink();
    return GradesChartLegendEntry(
      config: theme,
      name: subjectName,
      setThickness: (thickness) => ref
          .read(settingsProvider.notifier)
          .setSubjectTheme(MapEntry(subjectName, theme.rebuild((b) => b..thick = thickness))),
    );
  }
}
