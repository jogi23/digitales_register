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
import 'package:dr/ui/star_rating.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;
  _TestSettingsNotifier(this.initial);
  @override
  SettingsState build() => initial;
}

void main() {
  Widget stars(String starColor, {required Brightness brightness}) {
    return ProviderScope(
      overrides: [
        settingsProvider.overrideWith(
          () => _TestSettingsNotifier(SettingsState(starColor: starColor)),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: brightness,
        ),
        home: const Scaffold(body: StarRow(filled: 4)),
      ),
    );
  }

  /// The colour every star is drawn in — filled and empty share it.
  Color? drawnColor(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon).first).color;

  group('the palette', () {
    test('resolves a stored id', () {
      // The name is not part of the palette any more: it comes from the
      // translations, keyed by this id.
      expect(starColorById('amber')?.light, isNotNull);
    });

    test('has no entry for the accent colour', () {
      expect(starColorById(accentStarColorId), isNull);
    });

    test('falls back for an id it does not know', () {
      // A setting written by another version must not blank out the stars.
      expect(starColorById('chartreuse'), isNull);
    });

    test('gives every entry a distinct id', () {
      final ids = starColors.map((c) => c.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(ids, isNot(contains(accentStarColorId)));
    });

    test('gives every entry a shade per theme', () {
      // The point of two shades: one tone cannot suit both backgrounds.
      for (final color in starColors) {
        expect(
          color.resolve(Brightness.light),
          isNot(color.resolve(Brightness.dark)),
          reason: color.id,
        );
      }
    });
  });

  group('a row of stars', () {
    testWidgets('fills as many as the competence scored', (tester) async {
      await tester
          .pumpWidget(stars(accentStarColorId, brightness: Brightness.light));
      expect(find.byIcon(Icons.star), findsNWidgets(4));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });

    testWidgets('follows the accent colour by default', (tester) async {
      await tester
          .pumpWidget(stars(accentStarColorId, brightness: Brightness.light));
      final theme = Theme.of(tester.element(find.byType(StarRow)));
      expect(drawnColor(tester), theme.colorScheme.primary);
    });

    testWidgets('takes the chosen colour in light mode', (tester) async {
      await tester.pumpWidget(stars('amber', brightness: Brightness.light));
      expect(drawnColor(tester), starColorById('amber')!.light);
    });

    testWidgets('takes the darker shade in dark mode', (tester) async {
      // The bug this guards: a tone picked for white paper vanishes at night.
      await tester.pumpWidget(stars('amber', brightness: Brightness.dark));
      expect(drawnColor(tester), starColorById('amber')!.dark);
    });

    testWidgets('falls back to the accent colour for an unknown id',
        (tester) async {
      await tester
          .pumpWidget(stars('chartreuse', brightness: Brightness.light));
      final theme = Theme.of(tester.element(find.byType(StarRow)));
      expect(drawnColor(tester), theme.colorScheme.primary);
    });
  });
}
