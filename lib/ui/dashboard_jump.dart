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

import 'package:dr/utc_date_time.dart';
import 'package:flutter/foundation.dart';

/// A request to bring one day into view in the month or week view.
///
/// The list view scrolls to an entry; the calendar views have no scroll
/// position to move, so they are told which day to open instead.
///
/// [serial] counts the requests: asking for the same day twice has to arrive
/// twice, because the button walks through the new entries in turn and may
/// come back to a day it has already shown.
@immutable
class DashboardJumpRequest {
  final UtcDateTime date;
  final int serial;

  const DashboardJumpRequest(this.date, this.serial);

  @override
  bool operator ==(Object other) =>
      other is DashboardJumpRequest &&
      other.date == date &&
      other.serial == serial;

  @override
  int get hashCode => Object.hash(date, serial);
}

/// Carries [DashboardJumpRequest]s from the dashboard to whichever calendar
/// view is currently built.
typedef DashboardJumpNotifier = ValueNotifier<DashboardJumpRequest?>;
