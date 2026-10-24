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
import 'package:dr/lesson_times.dart';
import 'package:dr/providers/lesson_times_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Beginn und Ende jeder Schulstunde, für die Schule des angemeldeten Kontos.
///
/// Die Zeiten gelten für alle Konten dieser Schule. Wo nichts eingestellt ist,
/// gelten die Zeiten des Portals.
class LessonTimesPage extends ConsumerWidget {
  const LessonTimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = tr(context);
    final school = ref.watch(schoolKeyProvider);
    final host = school == null ? null : Uri.parse(school).host;
    final portal = ref.watch(portalLessonTimesProvider);
    final overrides = ref.watch(lessonTimeOverridesProvider);
    final times = ref.watch(lessonTimesProvider);
    final hours = times.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(l.settingsLessonTimes),
        actions: [
          if (overrides.isNotEmpty && school != null)
            TextButton(
              onPressed: () =>
                  ref.read(settingsProvider.notifier).resetLessonTimes(school),
              child: Text(l.lessonTimesResetAll),
            ),
        ],
      ),
      body: hours.isEmpty || school == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.lessonTimesEmpty, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: context.systemInsets,
              children: [
                if (host != null && host.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: Text(l.lessonTimesSchool(host)),
                    subtitle: Text(l.lessonTimesHint),
                  ),
                for (final hour in hours)
                  _LessonTimeTile(
                    hour: hour,
                    time: times[hour]!,
                    portalTime: portal[hour],
                    custom: overrides.containsKey(hour),
                    onPickStart: () =>
                        _pick(context, ref, school, hour, times, end: false),
                    onPickEnd: () =>
                        _pick(context, ref, school, hour, times, end: true),
                    onReset: () => ref
                        .read(settingsProvider.notifier)
                        .resetLessonTime(school, hour),
                  ),
              ],
            ),
    );
  }

  /// Asks for the start or the end of [hour] and applies what follows from it
  /// (see [editLessonTime]).
  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    String school,
    int hour,
    LessonTimes times, {
    required bool end,
  }) async {
    final current = times[hour]!;
    final minutes = end ? current.end : current.start;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: end
          ? tr(context).lessonTimesEnd(hour)
          : tr(context).lessonTimesStart(hour),
    );
    if (picked == null || !context.mounted) return;

    final value = picked.hour * 60 + picked.minute;
    final changes = editLessonTime(
      times,
      hour,
      start: end ? null : value,
      end: end ? value : null,
    );
    if (changes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context).lessonTimesInvalid)),
      );
      return;
    }
    if (changes.isEmpty) return;
    ref.read(settingsProvider.notifier).setLessonTimes(school, changes);
  }
}

class _LessonTimeTile extends StatelessWidget {
  const _LessonTimeTile({
    required this.hour,
    required this.time,
    required this.portalTime,
    required this.custom,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onReset,
  });

  final int hour;
  final LessonTime time;
  final LessonTime? portalTime;
  final bool custom;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onReset;

  static String _range(LessonTime t) =>
      '${formatMinutes(t.start)} – ${formatMinutes(t.end)}';

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    final showsPortal = custom && portalTime != null;
    return ListTile(
      leading: const Icon(Icons.schedule_rounded),
      title: Text(l.lessonTimesHour(hour)),
      subtitle: Text(
        showsPortal
            ? '${_range(time)} · ${l.lessonTimesCustom}\n'
                '${l.lessonTimesPortal}: ${_range(portalTime!)}'
            : _range(time),
      ),
      isThreeLine: showsPortal,
      onTap: onPickStart,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: l.lessonTimesEditEnd(hour),
            onPressed: onPickEnd,
          ),
          if (custom)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: l.lessonTimesResetHour(hour),
              onPressed: onReset,
            ),
        ],
      ),
    );
  }
}
