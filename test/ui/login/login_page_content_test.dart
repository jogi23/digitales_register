import 'package:dr/container/login_page.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/login_page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../system_bars.dart';

void main() {
  LoginPageViewModel buildVm({
    required Map<String, String> servers,
    String? url,
    List<OtherAccount> otherAccounts = const <OtherAccount>[],
  }) {
    return LoginPageViewModel(
      error: null,
      loading: false,
      safeMode: false,
      noInternet: false,
      servers: servers,
      changePass: false,
      mustChangePass: false,
      username: null,
      url: url,
      otherAccounts: otherAccounts,
    );
  }

  testWidgets('school field updates when externalized school list loads',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPageContent(
          vm: buildVm(
            servers: const {},
            url: 'https://vinzentinum.digitalesregister.it',
          ),
          onLogin: (_, __, ___) {},
          setSaveNoPass: (_) {},
          onReload: () {},
          onChangePass: (_, __, ___, ____) {},
          onRequestPassReset: (_) {},
          onSelectAccount: (_) {},
        ),
      ),
    );

    expect(find.text('Andere Schule'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPageContent(
          vm: buildVm(
            servers: const {
              'Vinzentinum': 'https://vinzentinum.digitalesregister.it',
            },
            url: 'https://vinzentinum.digitalesregister.it',
          ),
          onLogin: (_, __, ___) {},
          setSaveNoPass: (_) {},
          onReload: () {},
          onChangePass: (_, __, ___, ____) {},
          onRequestPassReset: (_) {},
          onSelectAccount: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vinzentinum'), findsOneWidget);
  });

  testWidgets('a typed address wins over the school picked before',
      (tester) async {
    // A school that moved: the list still sent the login to its old address
    // (301), whatever was typed into the address field.
    String? loginUrl;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPageContent(
          vm: buildVm(
            servers: const {
              'SSP Sterzing 3':
                  'https://schulsprengel-sterzing3.digitalesregister.it',
              'Vinzentinum': 'https://vinzentinum.digitalesregister.it',
            },
            url: 'https://schulsprengel-sterzing3.digitalesregister.it',
          ),
          onLogin: (_, __, url) => loginUrl = url,
          setSaveNoPass: (_) {},
          onReload: () {},
          onChangePass: (_, __, ___, ____) {},
          onRequestPassReset: (_) {},
          onSelectAccount: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('SSP Sterzing 3'), findsOneWidget);

    final address = find.widgetWithText(TextField, 'Adresse');
    await tester.enterText(
      address,
      'https://ms-sterzing.digitalesregister.it/v2/login',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Benutzername'),
      'anna',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'geheim',
    );
    await tester.pump();

    expect(find.text('Andere Schule'), findsOneWidget);
    final login = find.widgetWithText(ElevatedButton, 'Login');
    await tester.ensureVisible(login);
    await tester.tap(login);
    expect(loginUrl, 'https://ms-sterzing.digitalesregister.it/v2/login');

    // Typing a listed school's address picks that school again.
    await tester.enterText(address, 'vinzentinum.digitalesregister.it');
    await tester.pump();
    expect(find.text('Vinzentinum'), findsOneWidget);
    await tester.tap(login);
    expect(loginUrl, 'https://vinzentinum.digitalesregister.it');
  });

  for (final holding in Holding.values) {
    testWidgets('the form stays clear of the system bars, ${holding.name}',
        (tester) async {
      holdPhone(tester, holding);
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPageContent(
            vm: buildVm(
              servers: const {},
              otherAccounts: [
                for (var i = 1; i <= 6; i++)
                  OtherAccount(username: 'konto$i', url: 'https://a.example'),
              ],
            ),
            onLogin: (_, __, ___) {},
            setSaveNoPass: (_) {},
            onReload: () {},
            onChangePass: (_, __, ___, ____) {},
            onRequestPassReset: (_) {},
            onSelectAccount: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await scrollToEnd(tester);
      expectClearOfSystemBars(
        tester,
        find.ancestor(of: find.text('konto6'), matching: find.byType(ListTile)),
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(ElevatedButton, 'Login'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expectClearOfSystemBars(
        tester,
        find.widgetWithText(ElevatedButton, 'Login'),
      );
    });
  }

  testWidgets('several accounts no longer ask which one to use',
      (tester) async {
    // The app starts in the account that was used last; switching happens
    // from the account card, not from a prompt at every start.
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPageContent(
          vm: buildVm(
            servers: const {},
            otherAccounts: const [
              OtherAccount(username: 'eltern1', url: 'https://a.example'),
              OtherAccount(username: 'eltern2', url: 'https://b.example'),
            ],
          ),
          onLogin: (_, __, ___) {},
          setSaveNoPass: (_) {},
          onReload: () {},
          onChangePass: (_, __, ___, ____) {},
          onRequestPassReset: (_) {},
          onSelectAccount: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Konto wählen'), findsNothing);

    // The list on the form itself stays: it is the way back in after a
    // logout or a failed auto-login. It sits below the fold.
    await tester.scrollUntilVisible(
      find.text('eltern2'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Andere Accounts'), findsOneWidget);
    expect(find.text('eltern2'), findsOneWidget);
  });

  testWidgets('login stays out of reach until name and password are there',
      (tester) async {
    // An attempt with an empty field used to wipe the saved password and with
    // it the whole account.
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPageContent(
          vm: buildVm(
            servers: const {},
            url: 'https://vinzentinum.digitalesregister.it',
          ),
          onLogin: (_, __, ___) {},
          setSaveNoPass: (_) {},
          onReload: () {},
          onChangePass: (_, __, ___, ____) {},
          onRequestPassReset: (_) {},
          onSelectAccount: (_) {},
        ),
      ),
    );

    final login = find.widgetWithText(ElevatedButton, 'Login');
    expect(tester.widget<ElevatedButton>(login).enabled, isFalse);

    await tester.enterText(
      find.widgetWithText(TextField, 'Benutzername'),
      'anna',
    );
    await tester.pump();
    // Still no password.
    expect(tester.widget<ElevatedButton>(login).enabled, isFalse);

    await tester.enterText(
      find.widgetWithText(TextField, 'Passwort'),
      'geheim',
    );
    await tester.pump();
    expect(tester.widget<ElevatedButton>(login).enabled, isTrue);
  });
}
