import 'package:dr/container/login_page.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/ui/login_page_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  LoginPageViewModel buildVm({
    required Map<String, String> servers,
    String? url,
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
      otherAccounts: const <OtherAccount>[],
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
          onLoginCurrentAccount: () {},
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
          onLoginCurrentAccount: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Vinzentinum'), findsOneWidget);
  });
}
