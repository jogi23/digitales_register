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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/notification_type.dart';
import 'package:dr/notification_visibility.dart';
import 'package:dr/system_notifications.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

/// The kinds of notification the portal knows, spelled as it sends them —
/// `notificationTypes` in its web client, `/v2/scripts/main.min.js` (#290).
const _portalTypes = {
  'criticalObservation',
  'observation',
  'grade',
  'substituteLesson',
  'lessonTeacherChanged',
  'passwordChanged',
  'absence',
  'absenceReason',
  'absenceAdvance',
  'homeWork',
  'exam',
  'message',
  'messageShared',
  'custom',
  'absenceReasonAdvanceForClass',
};

Notification _of(String type) => Notification(
      (b) => b
        ..id = 1
        ..title = type
        ..type = type
        ..timeSent = UtcDateTime(2026, 9, 25),
    );

/// The portal's kinds that [settings] keeps out.
Set<String> _hidden(SettingsState settings) => {
      for (final type in _portalTypes)
        if (!isNotificationTypeEnabled(_of(type), settings)) type,
    };

void main() {
  final all = SettingsState();

  test('with every setting on, every kind comes through', () {
    expect(_hidden(all), isEmpty);
  });

  test('each setting answers for its kinds of the portal (#290)', () {
    expect(
      _hidden(all.copyWith(notifyMessages: false)),
      {'message', 'messageShared'},
    );
    expect(_hidden(all.copyWith(notifyGrades: false)), {'grade'});
    expect(
      _hidden(all.copyWith(notifyObservations: false)),
      {'observation', 'criticalObservation'},
    );
    expect(
      _hidden(all.copyWith(notifyHomework: false)),
      {'homeWork', 'exam'},
    );
    expect(
      _hidden(all.copyWith(notifyAbsences: false)),
      {
        'absence',
        'absenceReason',
        'absenceAdvance',
        'absenceReasonAdvanceForClass',
      },
    );
  });

  test('what no setting speaks for always comes through', () {
    final none = all.copyWith(
      notifyClassbook: false,
      notifyMessages: false,
      notifyGrades: false,
      notifyObservations: false,
      notifyHomework: false,
      notifyAbsences: false,
    );
    expect(
      _portalTypes.difference(_hidden(none)),
      {'substituteLesson', 'lessonTeacherChanged', 'passwordChanged', 'custom'},
    );
  });

  group('what a system notification is about (#297)', () {
    test('every kind of the portal has a label, in every language', () {
      for (final language in ['de', 'en', 'it']) {
        final l = lookupL(Locale(language));
        for (final type in _portalTypes) {
          final kind = notificationKindOf(type);
          expect(kind, isNotNull, reason: type);
          expect(l.systemNotificationsKind(kind!), isNotEmpty,
              reason: '$type in $language');
        }
      }
    });

    test('stands in front of the text', () {
      final l = lookupL(const Locale('de'));
      expect(withKind(l, _of('homeWork')), 'Hausaufgabe · homeWork');
      expect(withKind(l, _of('exam')), 'Prüfung · exam');
      expect(withKind(l, _of('messageShared')), 'Mitteilung · messageShared');
      expect(
        withKind(l, _of('substituteLesson')),
        'Kalender · substituteLesson',
      );
    });

    test('a kind the app does not know leaves the text as it is', () {
      final l = lookupL(const Locale('de'));
      expect(withKind(l, _of('somethingNew')), 'somethingNew');
    });
  });
}
