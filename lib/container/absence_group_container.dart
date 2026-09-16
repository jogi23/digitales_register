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

import 'package:dr/data.dart';
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/ui/absence.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AbsenceGroupContainer extends ConsumerWidget {
  final int group;
  final Color? tileColor;

  /// Gives a reason for this absence; null leaves out the button.
  final void Function(int group)? onJustify;

  const AbsenceGroupContainer({
    super.key,
    required this.group,
    this.tileColor,
    this.onJustify,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final absenceGroup =
        ref.watch(absencesProvider.select((s) => s.absences[group]));
    final l = tr(context);
    final fromTo = absenceGroupRange(context, absenceGroup);
    var duration = "";
    if (absenceGroup.hours != 0) {
      duration += l.absenceHours(absenceGroup.hours);
    }
    if (absenceGroup.minutes != 0) {
      if (duration != "") duration += ", ";
      duration += l.absenceMinutes(absenceGroup.minutes);
    }
    String justifiedString;
    switch (absenceGroup.justified) {
      case AbsenceJustified.justified:
        justifiedString = absenceGroup.reasonSignature != null &&
                absenceGroup.reasonTimestamp != null
            ? l.absenceJustifiedAs(
                    DateFormat("EE d.M.yyyy", l.localeName)
                        .format(absenceGroup.reasonTimestamp!),
                    DateFormat("HH:mm").format(absenceGroup.reasonTimestamp!),
                    absenceGroup.reasonSignature!,
                  )
            : l.absenceJustified;
      case AbsenceJustified.forSchool:
        justifiedString = l.absenceForSchool;
      case AbsenceJustified.notJustified:
        justifiedString = l.absenceNotJustified;
      default:
        justifiedString = l.absenceNotYetJustified;
    }
    // Absences the register has settled are not up for a reason any more.
    final settled = absenceGroup.justified == AbsenceJustified.justified ||
        absenceGroup.justified == AbsenceJustified.forSchool;
    return AbsenceGroupWidget(
      tileColor: tileColor,
      onJustify: onJustify == null || settled ? null : () => onJustify!(group),
      vm: AbsencesViewModel(
        fromTo,
        duration,
        justifiedString,
        absenceGroup.reason,
        absenceGroup.justified,
        absenceGroup.note,
      ),
    );
  }
}

/// The days and lessons an absence covers, e.g. "Mo 5.2.2026, 3. - 5. h".
///
/// Also what the reason dialog shows above its fields, so the reader can see
/// which absence they are about to sign for.
String absenceGroupRange(BuildContext context, AbsenceGroup group) {
  final l = tr(context);
  if (group.absences.isEmpty) return "";
  final first = group.absences.last; //<--- flip is intentional
  final last = group.absences.first; //<---
  var fromTo = "";
  if (first.date == last.date) {
    fromTo += "${DateFormat("EE d.M.yyyy", l.localeName).format(first.date)}, ";
    if (first == last) {
      fromTo += "${first.hour}. h";
    } else {
      fromTo += "${first.hour}. - ${last.hour}. h";
    }
  } else {
    fromTo +=
        "${DateFormat("EE d.M.yyyy", l.localeName).format(first.date)} ${first.hour}. h - "
        "${DateFormat("EE d.M.yyyy", l.localeName).format(last.date)} ${last.hour}. h ";
  }
  return fromTo;
}

class AbsencesViewModel {
  final String fromTo;
  final String duration;
  final String justifiedString;
  final String? reason;
  final String? note;
  final AbsenceJustified justified;

  AbsencesViewModel(
    this.fromTo,
    this.duration,
    this.justifiedString,
    this.reason,
    this.justified,
    this.note,
  );
}
