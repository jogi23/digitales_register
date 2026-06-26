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

import 'package:dr/providers/certificate_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/ui/certificate.dart';
import 'package:dr/ui/no_internet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import '../../fixtures/api_fixtures.dart';

// ---------------------------------------------------------------------------
// Test notifier
// ---------------------------------------------------------------------------

class _TestCertificateNotifier extends CertificateNotifier {
  final CertificateState _initial;
  _TestCertificateNotifier(this._initial);

  @override
  CertificateState build() => _initial;
}

// ---------------------------------------------------------------------------
// Widget builder
// ---------------------------------------------------------------------------

Widget _build(CertificateState state, {bool noInternet = false}) {
  return ProviderScope(
    overrides: [
      certificateProvider.overrideWith(
        () => _TestCertificateNotifier(state),
      ),
      noInternetProvider.overrideWith(
        () => _NoInternetStub(noInternet),
      ),
    ],
    child: const MaterialApp(home: Certificate()),
  );
}

class _NoInternetStub extends NoInternetNotifier {
  final bool _value;
  _NoInternetStub(this._value);

  @override
  bool build() => _value;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(loadFixtures);

  group('loading state', () {
    testWidgets('shows progress indicator when online and no data',
        (tester) async {
      await tester.pumpWidget(_build(const CertificateState()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NoInternet), findsNothing);
    });

    testWidgets('shows NoInternet when offline and no data', (tester) async {
      await tester.pumpWidget(
        _build(const CertificateState(), noInternet: true),
      );
      expect(find.byType(NoInternet), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('demo data from capture', () {
    late String demoHtml;

    setUpAll(() {
      demoHtml = fixtureFor('student/certificate') as String;
    });

    testWidgets('renders title from demo HTML', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zeugnis (Demo)'), findsOneWidget);
    });

    testWidgets('renders subject rows', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Deutsch'), findsOneWidget);
      expect(find.text('Mathematik'), findsOneWidget);
    });

    testWidgets('renders semester headers', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1. Semester'), findsOneWidget);
      expect(find.text('2. Semester'), findsOneWidget);
    });

    testWidgets('renders grade values', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pumpAndSettle();
      expect(find.text('gut'), findsWidgets);
      expect(find.text('sehr gut'), findsWidgets);
    });

    testWidgets('renders competency section header', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pump();
      // Section header present in the HTML
      expect(find.textContaining('Kompetenzen'), findsOneWidget);
    });

    testWidgets('shows AppBar title Zeugnis', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pump();
      expect(find.text('Zeugnis'), findsOneWidget);
    });

    testGoldens('demo zeugnis golden', (tester) async {
      await tester.pumpWidget(
        _build(CertificateState(html: demoHtml)),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('zeugnis_demo.png'),
      );
    });

    testGoldens('zeugnis loading golden', (tester) async {
      await tester.pumpWidget(_build(const CertificateState()));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('zeugnis_loading.png'),
      );
    });
  });
}
