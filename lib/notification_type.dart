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
import 'package:dr/utc_date_time.dart';
import 'package:dr/util.dart';

// The kinds of notification the portal knows, as its own web client lists
// them (`notificationTypes` in `/v2/scripts/main.min.js`, #290) — written in
// lower case, as [normalizedNotificationType] compares them.
const notificationTypeMessage = 'message';
const notificationTypeMessageShared = 'messageshared';
const notificationTypeGrade = 'grade';
const notificationTypeObservation = 'observation';
const notificationTypeCriticalObservation = 'criticalobservation';
const notificationTypeHomework = 'homework';
const notificationTypeExam = 'exam';
const notificationTypeAbsence = 'absence';
const notificationTypeAbsenceReason = 'absencereason';
const notificationTypeAbsenceAdvance = 'absenceadvance';
const notificationTypeAbsenceReasonAdvanceForClass =
    'absencereasonadvanceforclass';

// Not among the portal's kinds; the "Merkheft" setting still answers to them.
const notificationTypeClassbook = 'classbook';
const notificationTypeEntry = 'entry';

String normalizedNotificationType(String? type) => (type ?? '').toLowerCase();

/// Whether [n] is about a message — sent to the user or shared with them.
/// Its [Notification.objectId] is the message's id either way.
bool isMessageNotification(Notification n) =>
    switch (normalizedNotificationType(n.type)) {
      notificationTypeMessage || notificationTypeMessageShared => true,
      _ => false,
    };

/// Whether [n] is about homework or an exam.
bool isHomeworkNotification(Notification n) =>
    switch (normalizedNotificationType(n.type)) {
      notificationTypeHomework || notificationTypeExam => true,
      _ => false,
    };

/// Whether [n] is about an absence, its reason or one announced ahead.
bool isAbsenceNotification(Notification n) =>
    switch (normalizedNotificationType(n.type)) {
      notificationTypeAbsence ||
      notificationTypeAbsenceReason ||
      notificationTypeAbsenceAdvance ||
      notificationTypeAbsenceReasonAdvanceForClass =>
        true,
      _ => false,
    };

/// The notifications as `api/notification/unread` hands them over; entries
/// that do not parse are left out.
List<Notification> parseNotifications(List<dynamic> data) => data
    .map<Notification>(
      (dynamic n) => tryParse(
        getMap(n),
        (dynamic n) => Notification(
          (b) => b
            ..id = getInt(n["id"])
            ..title = getString(n["title"])
            ..type = getString(n["type"])
            ..objectId = getInt(n["objectId"])
            ..subTitle = getString(n["subTitle"])
            ..timeSent = UtcDateTime.parse(getString(n["timeSent"])!),
        ),
      ),
    )
    .toList();
