import 'package:dr/container/login_page.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/login_page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
