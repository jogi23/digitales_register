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
import 'package:dr/l10n/l10n.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/provider_container.dart' as pc;
import 'package:dr/providers/settings_provider.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class TestSettingsNotifier extends SettingsNotifier {
  final SettingsState initial;

  TestSettingsNotifier(this.initial);

  @override
  SettingsState build() => initial;
}

/// Pumps [home] the way the settings pages live in the app: German locale,
/// a [DynamicTheme] above, and the settings provider seeded with [settings].
Future<ProviderContainer> pumpSettings(
  WidgetTester tester,
  Widget home, {
  SettingsState? settings,
  bool demo = false,
  double textScale = 1,
  List<Override> overrides = const [],
  GlobalKey<NavigatorState>? navigatorKey,
  RouteFactory? onGenerateRoute,
}) async {
  final container = ProviderContainer(
    overrides: [
      settingsProvider.overrideWith(
        () => TestSettingsNotifier(settings ?? SettingsState()),
      ),
      isDemoProvider.overrideWith((ref) => demo),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  pc.providerContainer = container;
  final app = UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de'), Locale('it'), Locale('en')],
      navigatorKey: navigatorKey,
      onGenerateRoute: onGenerateRoute,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: home,
    ),
  );
  await tester.pumpWidget(
    DynamicTheme(
      data: (brightness, overridePlatform, seedColor) => ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: brightness,
      ),
      themedWidgetBuilder: (context, data) => app,
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// The two Android accessibility guidelines the settings pages must meet.
Future<void> expectMeetsGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

/// Blocks as the content page shows them once open: their rows in a scroll view.
Widget blockHost(List<Widget> blocks) => Scaffold(
      body: SingleChildScrollView(child: Column(children: blocks)),
    );
