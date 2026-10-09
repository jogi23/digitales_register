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

import 'package:deleteable_tile/deleteable_tile.dart';
import 'package:dr/app_state.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/settings/widgets/add_subject_dialog.dart';
import 'package:dr/ui/settings/widgets/settings_choice_tile.dart';
import 'package:dr/ui/settings/widgets/view_option_tiles.dart';
import 'package:dr/ui/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the grades page shows, how stars look, and which subjects stay out
/// of the average.
class GradesBlock extends ConsumerWidget {
  const GradesBlock({super.key});

  /// One palette entry, shown as a star in the colour it stands for so the
  /// choice can be made without applying it first.
  SettingsChoice<String> _starColorChoice(BuildContext context, String id) =>
      SettingsChoice(
        value: id,
        label: starColorName(context, id),
        leading:
            Icon(Icons.star, color: resolveStarColor(context, id), size: 20),
      );

  Future<void> _addExcluded(BuildContext context, WidgetRef ref) async {
    final ignored = ref.read(settingsProvider).ignoreForGradesAverage.toList();
    final available = ref
        .read(allSubjectsProvider)
        .where((subject) => !ignored.contains(subject))
        .toList();
    final subject = await showDialog<String>(
      context: context,
      builder: (context) => AddSubject(availableSubjects: available),
    );
    if (subject == null) return;
    // The list as it is now, not as it was before the dialog opened; and free
    // text, so the subject may already be on it.
    final current = ref.read(settingsProvider).ignoreForGradesAverage;
    if (current.contains(subject)) return;
    ref
        .read(settingsProvider.notifier)
        .setIgnoreForGradesAverage([...current, subject]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final excluded = s.ignoreForGradesAverage;
    return Column(
      children: [
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.show_chart_rounded),
          title: Text(l.settingsShowChart),
          value: s.showGradesDiagram,
          onChanged: notifier.setShowGradesDiagram,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.functions_rounded),
          title: Text(l.settingsShowAllSubjectsAverage),
          value: s.showAllSubjectsAverage,
          onChanged: notifier.setShowAllSubjectsAverage,
        ),
        SwitchListTile.adaptive(
          secondary: const Icon(Icons.calculate_outlined),
          title: Text(l.settingsShowSubjectAverage),
          value: s.showSubjectAverage,
          onChanged: notifier.setShowSubjectAverage,
        ),
        DisplayModeTiles(
          value: s.gradesDisplayMode,
          onChanged: notifier.setGradesDisplayMode,
        ),
        SettingsChoiceTile<String>(
          icon: Icons.star_rounded,
          title: l.settingsStarColor,
          hint: l.settingsStarColorSubtitle,
          value: s.starColor,
          choices: [
            _starColorChoice(context, accentStarColorId),
            for (final color in starColors) _starColorChoice(context, color.id),
          ],
          onChanged: notifier.setStarColor,
        ),
        ListTile(
          leading: const Icon(Icons.block_rounded),
          title: Text(l.settingsExcludeSubjects),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.settingsAddSubject,
            onPressed: () => _addExcluded(context, ref),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: excluded.isEmpty
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: ListTile(
              title: Text(
                l.settingsNoSubjectExcluded,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          secondChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final subject in excluded)
                Deleteable(
                  // Don't show an animation if this is the only item: the
                  // AnimatedCrossFade does a different one then.
                  showExitAnimation: excluded.length != 1,
                  showEntryAnimation: excluded.length != 1,
                  key: ValueKey(subject),
                  builder: (context, delete) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ListTile(
                      title: Text(subject),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: l.settingsRemoveSubject(subject),
                        onPressed: () async {
                          await delete();
                          // The live list: another row may have been removed
                          // while this one was animating out.
                          final current =
                              ref.read(settingsProvider).ignoreForGradesAverage;
                          notifier.setIgnoreForGradesAverage([
                            for (final other in current)
                              if (other != subject) other,
                          ]);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
