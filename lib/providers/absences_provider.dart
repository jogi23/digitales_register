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

import 'dart:convert';

import 'package:built_collection/built_collection.dart';
import 'package:dr/app_state.dart';
import 'package:dr/data.dart';
import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

@visibleForTesting
AbsencesState parseAbsencesFromJson(dynamic json) =>
    tryParse(getMap(json)!, _parseAbsencesMap);

const _absencesUrl = "api/student/dashboard/absences";
const _absenceReasonUrl = "api/student/dashboard/absence_reason";
const _absenceFutureUrl = "api/student/dashboard/absence_future";
const _removeAbsenceFutureUrl = "api/student/dashboard/remove_absence_future";

final _dateFormat = DateFormat("yyyy-MM-dd");

/// What the register made of a write: `true` when it took it, `false` when it
/// refused, and `null` when it said nothing to go by.
///
/// `absence_future` and `remove_absence_future` both answer `{"success":
/// true}` -- verified against the register on 2026-09-17. A request that never
/// arrived, or an endpoint that stays silent, gives `null`, and then only the
/// reloaded list can say whether the write landed.
@visibleForTesting
bool? wroteOk(dynamic response) => switch (response) {
      {'success': final bool ok} => ok,
      _ => null,
    };

class AbsencesNotifier extends Notifier<AbsencesState> {
  @override
  AbsencesState build() => AbsencesState();

  void reset() {
    state = AbsencesState();
  }

  void restore(AbsencesState saved) => state = saved;

  Future<void> load() async {
    if (ref.read(noInternetProvider)) return;
    final dynamic response = await wrapper.send(_absencesUrl);
    if (response != null) {
      state = tryParse(getMap(response)!, _parseAbsencesMap);
    }
  }

  /// Gives a reason for an absence, and signs it.
  ///
  /// The whole group goes back to the register the way it came, with only the
  /// reason fields replaced -- that is what the portal sends, and the
  /// register may well insist on the rest being there.
  Future<bool> saveReason(
    AbsenceGroup group, {
    required String reason,
    required String signature,
    SelfDeclaration? selfDeclaration,
    String selfDeclarationInput = "",
  }) async {
    final raw = group.raw;
    if (raw == null) return false;
    final payload = json.decode(raw) as Map<String, dynamic>
      ..["reason"] = reason
      ..["reason_signature"] = signature
      // The portal sends the device's clock along; the register keeps its own
      // record of when the request came in.
      ..["reason_timestamp"] = DateTime.now().toUtc().toIso8601String()
      ..["selfdecl_id"] = selfDeclaration?.id ?? 0
      ..["selfdecl_input"] = selfDeclarationInput;
    final dynamic result = await wrapper.send(
      _absenceReasonUrl,
      args: {"absenceGroup": payload},
    );
    await load();
    // This one's answer is still unverified -- the portal throws it away, and
    // the test account had no absence to give a reason for. Its siblings say
    // `success`, so that is taken when it comes; otherwise the reloaded list
    // decides.
    return wroteOk(result) ?? (_groupFor(group)?.reason == reason);
  }

  /// Reports an absence that is still to come.
  Future<bool> addFutureAbsence({
    required UtcDateTime startDate,
    required UtcDateTime endDate,
    required int startHour,
    required int endHour,
    required String reason,
    required String signature,
    String note = "",
  }) async {
    final dynamic result = await wrapper.send(
      _absenceFutureUrl,
      args: {
        "futureAbsence": {
          "startDate": _dateFormat.format(startDate),
          "endDate": _dateFormat.format(endDate),
          // Lesson numbers of the school's time grid, not times of day.
          "startTime": startHour,
          "endTime": endHour,
          "reason": reason,
          "reason_signature": signature,
          // The portal leaves the note out and the register stores null for
          // it, so an empty one is left out here too.
          if (note.isNotEmpty) "note": note,
        },
      },
    );
    await load();
    return wroteOk(result) ??
        state.futureAbsences.any(
          (a) =>
              a.startDate == startDate &&
              a.endDate == endDate &&
              a.startHour == startHour &&
              a.endHour == endHour,
        );
  }

  /// Takes a reported absence back.
  Future<bool> removeFutureAbsence(FutureAbsence absence) async {
    final raw = absence.raw;
    if (raw == null) return false;
    final dynamic result = await wrapper.send(
      _removeAbsenceFutureUrl,
      args: {"futureAbsence": json.decode(raw)},
    );
    await load();
    return wroteOk(result) ??
        !state.futureAbsences.any(
          (a) =>
              a.startDate == absence.startDate &&
              a.startHour == absence.startHour &&
              a.endDate == absence.endDate &&
              a.endHour == absence.endHour,
        );
  }

  /// [group] in the state as it is now: the same absence, the way the
  /// register sees it after the reload.
  AbsenceGroup? _groupFor(AbsenceGroup group) {
    if (group.absences.isEmpty) return null;
    final first = group.absences.first;
    for (final candidate in state.absences) {
      if (candidate.absences.isEmpty) continue;
      final other = candidate.absences.first;
      if (other.date == first.date && other.hour == first.hour) {
        return candidate;
      }
    }
    return null;
  }
}

final absencesProvider =
    NotifierProvider<AbsencesNotifier, AbsencesState>(AbsencesNotifier.new);

AbsencesState _parseAbsencesMap(Map json) {
  final rawStats = getMap(json["statistics"])!;
  final stats = AbsenceStatisticBuilder()
    ..counter = getInt(rawStats["counter"])
    ..counterForSchool = getInt(rawStats["counterForSchool"])
    ..delayed = getInt(rawStats["delayed"])
    ..justified = getInt(rawStats["justified"])
    ..notJustified = getInt(rawStats["notJustified"])
    ..percentage = rawStats["percentage"]?.toString().isNotEmpty == true
        ? rawStats["percentage"].toString()
        : null;
  final absences = (json["absences"] as List).map(_parseAbsence);
  final futureAbsences =
      (json["futureAbsences"] as List).map(_parseFutureAbsence);
  final declarations = (json["selfDeclarationsList"] as List? ?? const [])
      .map(_parseSelfDeclaration);
  final activeDeclarations =
      (json["selfDeclarationsActiveList"] as List? ?? const [])
          .map(_parseSelfDeclaration);
  return AbsencesState(
    (b) => b
      ..statistic = stats
      ..absences = ListBuilder(absences)
      ..futureAbsences = ListBuilder(futureAbsences)
      ..canEdit = json["canEdit"] == true
      ..selfDeclarations = ListBuilder(declarations)
      ..activeSelfDeclarations = ListBuilder(activeDeclarations)
      ..selfDeclarationActive = json["isAbsencesSelfDeclarationActive"] == true
      ..selfDeclarationMandatory =
          json["isAbsencesSelfDeclarationMandatory"] == true
      ..lastFetched = UtcDateTime.now(),
  );
}

/// One of the school's forms. `inputmandatory` arrives as 0 or 1.
SelfDeclaration _parseSelfDeclaration(dynamic d) {
  return SelfDeclaration(
    (b) => b
      ..id = getInt(d["id"]) ?? 0
      ..title = getString(d["title"]) ?? ""
      ..text = getString(d["text"]) ?? ""
      ..version = getString(d["version"])
      ..inputMandatory = getInt(d["inputmandatory"]) == 1
      ..inputExplain = getString(d["inputexplain"]),
  );
}

AbsenceGroup _parseAbsence(dynamic g) {
  return AbsenceGroup(
    (b) => b
      ..raw = json.encode(g)
      ..selfDeclarationId = getInt(g["selfdecl_id"])
      ..selfDeclarationInput = getString(g["selfdecl_input"])
      ..justified = AbsenceJustified.fromInt(getInt(g["justified"])!)
      ..reasonSignature = getString(g["reason_signature"])
      ..reasonTimestamp = g["reason_timestamp"] is String
          ? UtcDateTime.tryParse(g["reason_timestamp"] as String)
          : null
      ..reason = getString(g["reason"])
      ..note = getString(g["note"])
      ..absences = ListBuilder(
        (g["group"] as List).map<Absence>(
          (dynamic a) {
            return Absence(
              (b) => b
                ..minutes = getInt(a["minutes"])
                ..date = UtcDateTime.parse(getString(a["date"])!)
                ..hour = getInt(a["hour"])
                ..minutesCameTooLate = getInt(a["minutes_begin"])
                ..minutesLeftTooEarly = getInt(a["minutes_end"]),
            );
          },
        ),
      )
      ..minutes = b.absences.build().fold<int>(
          0,
          (min, a) =>
              min +
              (a.minutes != 50
                  ? a.minutesCameTooLate + a.minutesLeftTooEarly
                  : 0))
      ..hours = b.absences
          .build()
          .fold<int>(0, (h, a) => h + (a.minutes == 50 ? 1 : 0)),
  );
}

FutureAbsence _parseFutureAbsence(dynamic absence) {
  return FutureAbsence(
    (b) => b
      ..raw = json.encode(absence)
      ..note = getString(absence["note"])
      ..startDate = UtcDateTime.parse(getString(absence["startDate"])!)
      ..endDate = UtcDateTime.parse(getString(absence["endDate"])!)
      ..startHour = getInt(absence["startTime"])
      ..endHour = getInt(absence["endTime"])
      ..justified = AbsenceJustified.fromInt(getInt(absence["justified"])!)
      ..reason = getString(absence["reason"])
      ..reasonSignature = getString(absence["reason_signature"])
      ..reasonTimestamp = absence["reason_timestamp"] is String
          ? UtcDateTime.tryParse(absence["reason_timestamp"] as String)
          : null,
  );
}
