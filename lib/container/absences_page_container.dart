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

import 'package:collection/collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/container/absence_group_container.dart';
import 'package:dr/data.dart';
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/ui/absence_entry.dart';
import 'package:dr/ui/absences_page.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AbsencesPageContainer extends ConsumerWidget {
  const AbsencesPageContainer({super.key});

  /// How many lessons a day has at this school, taken from the weeks the
  /// calendar has loaded. Ten until something is loaded — the lesson pickers
  /// need a range before the first week arrives.
  static int hourCount(CalendarState calendar) {
    var latest = 0;
    for (final day in calendar.days.values) {
      for (final hour in day.hours) {
        if (hour.toHour > latest) latest = hour.toHour;
      }
    }
    return latest > 0 ? latest : 10;
  }

  /// Reports an absence still to come, then says whether it went through.
  Future<void> _report(BuildContext context, WidgetRef ref) async {
    final l = tr(context);
    final input = await Navigator.of(context).push<FutureAbsenceInput>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => FutureAbsencePage(
          hourCount: hourCount(ref.read(calendarProvider)),
          signature: ref.read(settingsProvider).messageSignature,
        ),
      ),
    );
    if (input == null) return;
    // Whoever signs here signs the next one too, as with the messages.
    ref.read(settingsProvider.notifier).setMessageSignature(input.signature);
    final done = await ref.read(absencesProvider.notifier).addFutureAbsence(
          startDate: _dateOnly(input.startDate),
          endDate: _dateOnly(input.endDate),
          startHour: input.startHour,
          endHour: input.endHour,
          reason: input.reason,
          signature: input.signature,
          note: input.note,
        );
    showSnackBar(done ? l.absenceReportSaved : l.absenceSaveFailed);
  }

  /// Takes a report back, after asking.
  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    FutureAbsence absence,
  ) async {
    final l = tr(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.absenceReportDeleteQuestion),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final done =
        await ref.read(absencesProvider.notifier).removeFutureAbsence(absence);
    showSnackBar(done ? l.absenceReportDeleted : l.absenceSaveFailed);
  }

  /// Asks for a reason for the absence at [index] and sends it.
  Future<void> _justify(
    BuildContext context,
    WidgetRef ref,
    int index,
  ) async {
    final l = tr(context);
    final state = ref.read(absencesProvider);
    if (index < 0 || index >= state.absences.length) return;
    final group = state.absences[index];
    // The active list is what a school lets pick right now; where it is
    // empty, every form it has is better than none at all.
    final declarations = state.activeSelfDeclarations.isNotEmpty
        ? state.activeSelfDeclarations.toList()
        : state.selfDeclarations.toList();
    final input = await showAbsenceReasonDialog(
      context,
      absence: absenceGroupRange(context, group),
      reason: group.reason,
      signature:
          group.reasonSignature ?? ref.read(settingsProvider).messageSignature,
      declarations: declarations,
      declarationActive: state.selfDeclarationActive,
      declarationMandatory: state.selfDeclarationMandatory,
      declaration:
          declarations.firstWhereOrNull((d) => d.id == group.selfDeclarationId),
      declarationInput: group.selfDeclarationInput ?? "",
    );
    if (input == null) return;
    ref.read(settingsProvider.notifier).setMessageSignature(input.signature);
    final done = await ref.read(absencesProvider.notifier).saveReason(
          group,
          reason: input.reason,
          signature: input.signature,
          selfDeclaration: input.selfDeclaration,
          selfDeclarationInput: input.selfDeclarationInput,
        );
    showSnackBar(done ? l.absenceReasonSaved : l.absenceSaveFailed);
  }

  static UtcDateTime _dateOnly(DateTime date) =>
      UtcDateTime(date.year, date.month, date.day);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(absencesProvider);
    final noInternet = ref.watch(noInternetProvider);
    return AbsencesPage(
      onRefresh: ref.read(absencesProvider.notifier).load,
      state: state,
      noInternet: noInternet,
      displayMode:
          ref.watch(settingsProvider.select((s) => s.absencesDisplayMode)),
      // Whether this account may write is the register's call, and the only
      // thing that tells a pupil from a parent here.
      onReport: state.canEdit ? () => _report(context, ref) : null,
      onRemoveFuture:
          state.canEdit ? (absence) => _remove(context, ref, absence) : null,
      onJustify:
          state.canEdit ? (index) => _justify(context, ref, index) : null,
    );
  }
}
