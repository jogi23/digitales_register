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

import 'package:dr/container/absence_group_container.dart';
import 'package:dr/data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AbsenceGroupWidget extends StatelessWidget {
  final AbsencesViewModel vm;
  final Color? tileColor;

  const AbsenceGroupWidget({super.key, required this.vm, this.tileColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isApproved = vm.justified == AbsenceJustified.justified ||
        vm.justified == AbsenceJustified.forSchool;
    final isRejected = vm.justified == AbsenceJustified.notJustified;

    final IconData iconData;
    final Color iconColor;
    if (isApproved) {
      iconData = Icons.check_circle;
      iconColor = Colors.green.shade600;
    } else if (isRejected) {
      iconData = Icons.cancel;
      iconColor = theme.colorScheme.error;
    } else {
      iconData = Icons.radio_button_unchecked;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    final title =
        vm.duration.isEmpty ? vm.fromTo : '${vm.fromTo} · ${vm.duration}';

    final subtitleParts = <String>[
      if (vm.reason?.isNotEmpty == true) vm.reason!,
      if (vm.note?.isNotEmpty == true) vm.note!,
    ];

    return ListTile(
      tileColor: tileColor,
      leading: Icon(iconData, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: theme.colorScheme.primary),
      ),
      subtitle: subtitleParts.isNotEmpty
          ? Text(subtitleParts.join(' · '))
          : null,
    );
  }
}

class FutureAbsenceWidget extends StatelessWidget {
  final FutureAbsence absence;
  final Color? tileColor;

  const FutureAbsenceWidget({
    super.key,
    required this.absence,
    this.tileColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    var fromTo = '';
    if (absence.startDate == absence.endDate) {
      fromTo += '${DateFormat("EE d.M.yyyy", "de").format(absence.startDate)}, ';
      if (absence.startHour == absence.endHour) {
        fromTo += '${absence.startHour}. h';
      } else {
        fromTo += '${absence.startHour}. - ${absence.endHour}. h';
      }
    } else {
      fromTo +=
          '${DateFormat("EE d.M.yyyy", "de").format(absence.startDate)} ${absence.startHour}. h'
          ' - ${DateFormat("EE d.M.yyyy", "de").format(absence.endDate)} ${absence.endHour}. h';
    }

    final isApproved = absence.justified == AbsenceJustified.justified ||
        absence.justified == AbsenceJustified.forSchool;
    final isRejected = absence.justified == AbsenceJustified.notJustified;

    final IconData iconData;
    final Color iconColor;
    if (isApproved) {
      iconData = Icons.check_circle;
      iconColor = Colors.green.shade600;
    } else if (isRejected) {
      iconData = Icons.cancel;
      iconColor = theme.colorScheme.error;
    } else {
      iconData = Icons.radio_button_unchecked;
      iconColor = theme.colorScheme.onSurfaceVariant;
    }

    final String justifiedString;
    switch (absence.justified) {
      case AbsenceJustified.justified:
        justifiedString = 'Entschuldigt';
      case AbsenceJustified.forSchool:
        justifiedString = 'Im Auftrag der Schule (entschuldigt)';
      case AbsenceJustified.notJustified:
        justifiedString = 'Nicht entschuldigt';
      default:
        justifiedString = 'Noch nicht entschuldigt';
    }

    final subtitleParts = <String>[
      if (absence.reason?.isNotEmpty == true) absence.reason!,
      if (absence.note?.isNotEmpty == true) absence.note!,
      if (absence.reasonTimestamp != null && absence.reasonSignature != null)
        '${DateFormat("EE d.M.yyyy \'um\' HH:mm", "de").format(absence.reasonTimestamp!)} als „${absence.reasonSignature}” eingetragen',
    ];

    return ListTile(
      tileColor: tileColor,
      leading: Icon(iconData, color: iconColor),
      title: Text(
        fromTo,
        style: TextStyle(color: theme.colorScheme.primary),
      ),
      subtitle: subtitleParts.isNotEmpty
          ? Text(subtitleParts.join('\n'))
          : null,
    );
  }
}
