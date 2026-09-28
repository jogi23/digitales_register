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
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final configProvider = StateProvider<Config?>((_) => null);

/// How many stars the signed-in school rates competences on — six until its
/// page has been read.
final competenceScaleProvider = Provider<int>(
  (ref) =>
      ref.watch(configProvider)?.competenceScale ??
      Config.defaultCompetenceScale,
);

/// How many days of the week are school days: six when the setting asks for
/// it, otherwise what the school's page says, Monday to Friday until then.
final daysInWeekProvider = Provider<int>(
  (ref) => ref.watch(settingsProvider.select((s) => s.sixDayWeek))
      ? 6
      : ref.watch(configProvider)?.daysInWeek ?? Config.defaultDaysInWeek,
);

/// Keeps [schoolDaysInWeek] in step with [daysInWeekProvider] from now on.
void keepDaysInWeekInSync(ProviderContainer container) {
  container.listen<int>(
    daysInWeekProvider,
    (_, days) => schoolDaysInWeek = days,
    fireImmediately: true,
  );
}
