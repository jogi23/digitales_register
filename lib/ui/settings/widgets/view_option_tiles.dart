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
import 'package:dr/ui/settings/widgets/settings_headers.dart';
import 'package:flutter/material.dart';

/// List, cards and — where [offerTimeline] — the timeline. With
/// [timelineEnabled] false it stays visible but cannot be picked, and says
/// why, rather than vanishing when the arrangement changes.
class DisplayModeTiles extends StatelessWidget {
  const DisplayModeTiles({
    super.key,
    required this.value,
    required this.onChanged,
    this.offerTimeline = false,
    this.timelineEnabled = true,
  });

  final EntryDisplayMode value;
  final ValueChanged<EntryDisplayMode> onChanged;
  final bool offerTimeline;
  final bool timelineEnabled;

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return Column(
      children: [
        SettingsSubheader(l.settingsDisplay),
        for (final entry in <EntryDisplayMode, String>{
          EntryDisplayMode.list: l.displayList,
          EntryDisplayMode.cards: l.displayCards,
          if (offerTimeline) EntryDisplayMode.timeline: l.displayTimeline,
        }.entries)
          RadioListTile<EntryDisplayMode>(
            title: Text(entry.value),
            subtitle: entry.key == EntryDisplayMode.timeline && !timelineEnabled
                ? Text(l.displayTimelineOnlyByDay)
                : null,
            value: entry.key,
            groupValue: value,
            onChanged:
                entry.key == EntryDisplayMode.timeline && !timelineEnabled
                    ? null
                    : (mode) {
                        if (mode != null) onChanged(mode);
                      },
          ),
      ],
    );
  }
}

/// By day or by subject — classbook and homework each have their own.
class ArrangementTiles extends StatelessWidget {
  const ArrangementTiles({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final ClassbookViewMode value;
  final ValueChanged<ClassbookViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = tr(context);
    return Column(
      children: [
        SettingsSubheader(l.settingsClassbookView),
        for (final entry in <ClassbookViewMode, String>{
          ClassbookViewMode.chronological: l.classbookViewChronological,
          ClassbookViewMode.bySubject: l.classbookViewBySubject,
        }.entries)
          RadioListTile<ClassbookViewMode>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: value,
            onChanged: (mode) {
              if (mode != null) onChanged(mode);
            },
          ),
      ],
    );
  }
}
