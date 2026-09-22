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
import 'package:dr/data.dart';
import 'package:dr/notification_type.dart';

bool isNotificationTypeEnabled(Notification n, SettingsState settings) {
  switch (normalizedNotificationType(n.type)) {
    case notificationTypeMessage:
      return settings.notifyMessages;
    case notificationTypeGrade:
      return settings.notifyGrades;
    case notificationTypeObservation:
      return settings.notifyObservations;
    case notificationTypeHomework:
      return settings.notifyHomework;
    case notificationTypeEntry:
    case notificationTypeClassbook:
      return settings.notifyClassbook;
    default:
      return true;
  }
}
