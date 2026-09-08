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

import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/account_avatar_button.dart';
import 'package:dr/ui/account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestLoginNotifier extends LoginNotifier {
  final LoginState initial;
  _TestLoginNotifier(this.initial);
  @override
  LoginState build() => initial;
}

const _login = LoginState(
  loggedIn: true,
  username: 'eltern1',
  url: 'https://schule.example',
  otherAccounts: [
    OtherAccount(username: 'eltern2', url: 'https://schule.example'),
  ],
);

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loginProvider.overrideWith(() => _TestLoginNotifier(_login)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            appBar: null,
            body: Center(child: AccountAvatarButton()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the avatar opens the account card', (tester) async {
    await pumpPage(tester);
    expect(find.byType(AccountSheet), findsNothing);

    await tester.tap(find.byType(AccountAvatarButton));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSheet), findsOneWidget);
  });

  testWidgets('the card comes down from the top', (tester) async {
    // It belongs to the avatar in the app bar, not to the bottom edge.
    await pumpPage(tester);
    await tester.tap(find.byType(AccountAvatarButton));
    await tester.pumpAndSettle();

    final card = tester.getRect(find.byType(AccountSheet).first);
    final screen = tester.getSize(find.byType(MaterialApp));
    final content = tester.getRect(find.byType(SingleChildScrollView).first);

    expect(card.top, 0);
    // Sized by its content, so it does not reach the bottom of the screen.
    expect(content.bottom, lessThan(screen.height));
  });

  testWidgets('lists the other account to switch to', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byType(AccountAvatarButton));
    await tester.pumpAndSettle();

    expect(find.text('eltern2'), findsOneWidget);
  });

  testWidgets('tapping outside closes it', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.byType(AccountAvatarButton));
    await tester.pumpAndSettle();

    // Near the bottom edge, where the card is not.
    await tester.tapAt(Offset(
      tester.getSize(find.byType(MaterialApp)).width / 2,
      tester.getSize(find.byType(MaterialApp)).height - 10,
    ));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSheet), findsNothing);
  });
}
