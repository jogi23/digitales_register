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

import 'dart:async';
import 'dart:io';

import 'package:dr/container/change_email_container.dart';
import 'package:dr/container/home_page.dart';
import 'package:dr/container/login_page.dart';
import 'package:dr/container/notifications_page_container.dart';
import 'package:dr/container/pass_reset_container.dart';
import 'package:dr/container/profile_container.dart';
import 'package:dr/container/request_pass_reset_container.dart';
import 'package:dr/container/settings_page.dart';
import 'package:dr/desktop.dart';
import 'package:dr/middleware/middleware.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/provider_container.dart';
import 'package:dr/ui/grade_calculator.dart';
import 'package:dr/ui/grades_chart_page.dart';
import 'package:dr/ui/splash_overlay.dart';
import 'package:dr/util.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:responsive_scaffold/responsive_scaffold.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:uni_links/uni_links.dart';

export 'package:dr/ui/snack_bar.dart' show scaffoldMessengerKey, showSnackBar;

GlobalKey<NavigatorState>? navigatorKey;
GlobalKey<NavigatorState> nestedNavKey = GlobalKey();
GlobalKey<ResponsiveScaffoldState<Pages>>? scaffoldKey;

typedef SingleArgumentVoidCallback<T> = void Function(T arg);

const _sentryDsn =
    'https://73cb18b60e94a8e3849143d837584fa1@o4511353325486080.ingest.de.sentry.io/4511353328173136';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = _sentryDsn;
      options.tracesSampleRate = 0.0;
    },
    appRunner: _runApp,
  );
}

Future<void> _runApp() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  try {
    packageInfo = await PackageInfo.fromPlatform();
  } catch (_) {
    packageInfo = PackageInfo(
      appName: "Unknown",
      packageName: "Unknown",
      version: "Unknown",
      buildNumber: "Unknown",
    );
  }
  navigatorKey = GlobalKey();
  scaffoldKey = GlobalKey();
  scaffoldMessengerKey = GlobalKey();
  secureStorage = getFlutterSecureStorage();
  providerContainer = ProviderContainer();
  wireLoginDispatchers(providerContainer.read(loginProvider.notifier));
  runApp(SentryWidget(
    child: UncontrolledProviderScope(
      container: providerContainer,
      child: const RegisterApp(),
    ),
  ));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) async {
      binding.allowFirstFrame();
      Uri? uri;
      if (Platform.isAndroid) {
        uri = await getInitialUri();
        uriLinkStream.listen((event) {
          unawaited(startApp(event));
        });
      }
      unawaited(startApp(uri));
      WidgetsBinding.instance.addObserver(
        LifecycleObserver(
          () => unawaited(handleRestarted()),
          // this might not finish in time:
          saveStateImmediately,
        ),
      );
    },
  );
}

class RegisterApp extends StatelessWidget {
  const RegisterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => wrapper.interaction(),
      child: DynamicTheme(
        data: (brightness, overridePlatform, seedColor) {
          TargetPlatform? platform;
          if (overridePlatform && Platform.isAndroid) {
            platform = TargetPlatform.iOS;
          }
          return ThemeData(
            useMaterial3: true,
            colorSchemeSeed: seedColor,
            brightness: brightness,
            platform: platform,
          );
        },
        themedWidgetBuilder: (context, theme) => MaterialApp(
          localizationsDelegates: const [
            GlobalCupertinoLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale("de"),
          ],
          navigatorKey: navigatorKey,
          scaffoldMessengerKey: scaffoldMessengerKey,
          initialRoute: "/",
          onGenerateRoute: (RouteSettings settings) {
            final List<String> pathElements = settings.name!.split("/");
            if (pathElements[0] != "") return null;
            switch (pathElements[1]) {
              case "":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => HomePage(),
                );
              case "login":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => LoginPage(),
                );
              case "request_pass_reset":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => RequestPassResetContainer(),
                );
              case "pass_reset":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => PassResetContainer(),
                );
              case "change_email":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const ChangeEmailContainer(),
                );
              case "profile":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const ProfileContainer(),
                );
              case "notifications":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => NotificationPageContainer(),
                  fullscreenDialog: true,
                );
              case "gradesChart":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const GradesChartPage(),
                  fullscreenDialog: true,
                );
              case "gradeCalculator":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const GradeCalculator(),
                  fullscreenDialog: true,
                );
              case "settings":
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => SettingsPageContainer(),
                  fullscreenDialog: true,
                );
              default:
                throw Exception("Unknown Route ${pathElements[1]}");
            }
          },
          builder: (context, child) => Stack(
            children: [child!, const SplashOverlay()],
          ),
          theme: theme,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class LifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onForeground;
  final VoidCallback onBackground;

  LifecycleObserver(this.onForeground, this.onBackground);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onForeground();
    }
    if (state == AppLifecycleState.paused) {
      onBackground();
    }
  }
}

/// Utility to show a global Snack Bar
void showSnackBar(String message) {
  scaffoldMessengerKey!.currentState!.showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

/*
ThemeData _getDarkTheme(MaterialColor primarySwatch) {
  final colorScheme = ColorScheme(
    primary: primarySwatch,
    primaryVariant: primarySwatch[700],
    secondary: primarySwatch,
    secondaryVariant: primarySwatch[700],
    surface: Colors.grey[800],
    background: Colors.grey[700],
    error: Colors.red[700],
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onBackground: Colors.white,
    onError: Colors.black,
    brightness: Brightness.dark,
  );
  return ThemeData(
    brightness: Brightness.dark,
    primarySwatch: primarySwatch,
    primaryColor: primarySwatch,
    primaryColorLight: primarySwatch[100],
    primaryColorDark: primarySwatch[700],
    toggleableActiveColor: primarySwatch[600],
    accentColor: primarySwatch[500],
    secondaryHeaderColor: primarySwatch[200],
    backgroundColor: primarySwatch[200],
    indicatorColor: primarySwatch[500],
    buttonColor: primarySwatch[600],
    colorScheme: colorScheme,
  );
}
*/
