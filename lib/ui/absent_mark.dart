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
import 'package:flutter/material.dart';

/// The mark of a lesson the pupil missed (#350).
const absentIcon = Icons.person_off_outlined;

/// Says what the mark means: it is not obvious which absences count.
Future<void> showAbsentInfo(BuildContext context) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(absentIcon),
        title: Text(tr(context).lessonAbsent),
        content: Text(tr(context).lessonAbsentInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(context).commonOkCaps),
          ),
        ],
      ),
    );

/// „Abwesend“ with its icon, as a line in a lesson's details. Tapping it
/// explains the mark.
class AbsentMark extends StatelessWidget {
  const AbsentMark({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return Tooltip(
      message: tr(context).lessonAbsentInfoTooltip,
      child: InkWell(
        onTap: () => showAbsentInfo(context),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(absentIcon, size: 18, color: error),
              const SizedBox(width: 6),
              Text(
                tr(context).lessonAbsent,
                style: theme.textTheme.bodyMedium?.copyWith(color: error),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
