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
import 'package:dr/services/diagnostics_export.dart';
import 'package:dr/ui/diagnostics_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExport implements DiagnosticsExport {
  int calls = 0;
  DiagnosticsExportResult result = DiagnosticsExportResult.shared;

  @override
  Future<DiagnosticsExportResult> share(List<NetworkProtocolItem> items) async {
    calls++;
    return result;
  }
}

void main() {
  late _FakeExport export;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    export = _FakeExport();
  });

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    bool enabled = false,
  }) async {
    final c = ProviderContainer(overrides: [
      diagnosticsExportProvider.overrideWithValue(export),
    ]);
    addTearDown(c.dispose);
    c.read(settingsProvider.notifier).setDiagnosticsEnabled(enabled);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(children: const [DiagnosticsSettingsTiles()]),
        ),
      ),
    ));
    return c;
  }

  testWidgets('the share entry shows only while the switch is on',
      (tester) async {
    await pump(tester);
    expect(find.text('Diagnose-Protokoll'), findsOneWidget);
    expect(find.text('Protokoll teilen'), findsNothing);

    await tester.tap(find.text('Diagnose-Protokoll'));
    await tester.pumpAndSettle();
    expect(find.text('Protokoll teilen'), findsOneWidget);
  });

  testWidgets('switching on stores the setting and off clears it',
      (tester) async {
    final c = await pump(tester);
    await tester.tap(find.text('Diagnose-Protokoll'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).diagnosticsEnabled, isTrue);

    await tester.tap(find.text('Diagnose-Protokoll'));
    await tester.pumpAndSettle();
    expect(c.read(settingsProvider).diagnosticsEnabled, isFalse);
  });

  testWidgets('sharing asks first and does nothing on cancel', (tester) async {
    await pump(tester, enabled: true);
    await tester.tap(find.text('Protokoll teilen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Noten, Absenzen und Mitteilungen'),
        findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(export.calls, 0);
  });

  testWidgets('confirming shares the log', (tester) async {
    await pump(tester, enabled: true);
    await tester.tap(find.text('Protokoll teilen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();
    expect(export.calls, 1);
    expect(find.text('Nichts aufgezeichnet'), findsNothing);
  });

  testWidgets('an empty log says so', (tester) async {
    export.result = DiagnosticsExportResult.empty;
    await pump(tester, enabled: true);
    await tester.tap(find.text('Protokoll teilen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();
    expect(find.text('Nichts aufgezeichnet'), findsOneWidget);
  });
}
