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
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart' as dio;
import 'package:dr/app_state.dart';
import 'package:dr/main.dart' hide scaffoldMessengerKey, showSnackBar;
import 'package:dr/providers/absences_provider.dart';
import 'package:dr/providers/all_subjects_provider.dart';
import 'package:dr/providers/calendar_provider.dart';
import 'package:dr/providers/certificate_provider.dart';
import 'package:dr/providers/config_provider.dart';
import 'package:dr/providers/dashboard_error_provider.dart';
import 'package:dr/providers/dashboard_provider.dart';
import 'package:dr/providers/grades_provider.dart';
import 'package:dr/providers/login_provider.dart';
import 'package:dr/providers/messages_provider.dart';
import 'package:dr/providers/network_protocol_provider.dart';
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/providers/notifications_provider.dart';
import 'package:dr/providers/profile_provider.dart';
import 'package:dr/providers/provider_container.dart';
import 'package:dr/providers/settings_provider.dart';
import 'package:dr/serializers.dart';
import 'package:dr/services/app_router.dart';
import 'package:dr/ui/dialog.dart';
import 'package:dr/ui/snack_bar.dart';
import 'package:dr/util.dart';
import 'package:dr/wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:dr/pages.dart';

part 'login.dart';
part 'pass.dart';
part 'routing.dart';

late FlutterSecureStorage secureStorage;

/// Set to [true] in tests to prevent [_checkShowUnmaintainedAlert] from
/// displaying the dialog (which would block [pumpAndSettle] indefinitely).
@visibleForTesting
bool skipUnmaintainedAlert = false;

Wrapper wrapper = Wrapper();

/// Wires [LoginNotifier] to the plain middleware functions. Called once from
/// main.dart during startup.
void wireLoginDispatchers(LoginNotifier notifier) {
  notifier.initReduxDispatchers(
    load: () => unawaited(_withErrorHandling(_doLoad)),
    addAccount: () => unawaited(_doAddAccount()),
    selectAccount: (index) => unawaited(_doSelectAccount(index)),
    logout: ({required bool hard, bool forced = false}) =>
        unawaited(_doLogout(hard: hard, forced: forced)),
    login: (user, pass, url) => unawaited(_doLogin(user, pass, url)),
    changePass: (user, oldPass, newPass, url) =>
        unawaited(_doChangePass(user, oldPass, newPass, url)),
    saveNoPass: (value) => unawaited(_doSaveNoPass(value)),
    loginCurrentFromStorage: () =>
        unawaited(_withErrorHandling(_doLoginCurrentFromStorage)),
    resetPass: (newPass) => unawaited(_doResetPass(newPass)),
    requestPassReset: (user, email) =>
        unawaited(_doRequestPassReset(user, email)),
    showRequestPassReset: (url) => unawaited(() async {
      providerContainer.read(loginProvider.notifier).setUrl(url);
      await navigatorKey?.currentState?.pushNamed("/request_pass_reset");
      providerContainer.read(loginProvider.notifier).updatePassResetState(const PassResetState());
    }()),
  );
}

Future<void> _handleError(dynamic e, StackTrace? trace) async {
  log("Error caught by error middleware", error: e, stackTrace: trace);
  unawaited(Sentry.captureException(e, stackTrace: trace));
  var stackTrace = trace;
  try {
    stackTrace ??= e.stackTrace as StackTrace?;
  } catch (e) {
    // we can't get a stack trace
  }
  var error = e.toString();
  if (e is! ParseException) {
    // ParseExceptions will already provide a more precise stack trace
    error += "\n\n$stackTrace";
  }
  error +=
      "\n\nApp Version: $appVersion\nOS: ${Platform.operatingSystem}\nServer: ${providerContainer.read(loginProvider).url}";
  await navigatorKey?.currentState?.push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.red,
            title: const Text("Fehler!"),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              const Center(
                child: Text(
                  "Der Fehler wurde automatisch gemeldet.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  """
Ein Fehler ist aufgetreten.
${e is UnexpectedLogoutException ? """

Dieser Fehler kann auftreten, wenn zwei Geräte gleichzeitig auf dasselbe Konto zugreifen.
In diesem Fall kannst du versuchen, die App zu schließen und erneut zu öffnen.

Falls dies nicht zutrifft, bitte benachrichtige uns, damit wir diesen Fehler beheben können.""" : e is ParseException ? """

Beim Einlesen der Daten ist ein Fehler aufgetreten.
Bitte benachrichtige uns, damit wir diesen Fehler beheben können.
Bitte beachte, dass das Fehlerprotokoll möglicherweise private Daten enthält.""" : """

Eine Funktion wird eventuell noch nicht unterstützt.
Bitte benachrichtige uns, damit wir diesen Fehler beheben können:"""}

 --  Fehlerprotokoll: --

$error""",
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> _withErrorHandling(Future<void> Function() fn) async {
  try {
    await fn();
  } catch (e, stackTrace) {
    await _handleError(e, stackTrace);
  }
}

Future<void> startApp(Uri? uri) => _withErrorHandling(() => _doStart(uri));
Future<void> saveStateImmediately() => _doSaveState(immediately: true);
@visibleForTesting
Future<void> triggerDeferredSaveState() => _doSaveState();

Future<void> _doLoad({bool forceAutoLogin = false}) async {
  // By resetting the wrapper we clear all cookies.
  // However we don't want to reset the wrapper in tests
  if (wrapper is! Mock) {
    wrapper = Wrapper()
      ..onNoInternet = (bool v) =>
          providerContainer.read(noInternetProvider.notifier).setNoInternet(v);
  }
  providerContainer.read(settingsProvider.notifier).onSaveState =
      () => unawaited(_doSaveState(immediately: true));
  if (!providerContainer.read(noInternetProvider)) _popAll();
  dynamic login;
  try {
    login = json.decode(await secureStorage.read(key: "login") ?? "{}");
  } catch (e) {
    login = const <Never, Never>{};
    showSnackBar("Fehler beim Laden der gespeicherten Daten");
    log("Failed to load login credentials", error: e);
    try {
      await secureStorage.deleteAll();
    } catch (e) {
      showSnackBar("Bitte versuche, die App neu zu installieren.");
    }
  }

  await _checkShowUnmaintainedAlert();

  final user = getString(login["user"]);
  final pass = getString(login["pass"]);
  final url = getString(login["url"]);
  final List<OtherAccount> otherAccounts = [
    for (final dynamic entry
        in (login["otherAccounts"] as List?) ?? const [])
      if (getString(entry["user"]) != null && getString(entry["url"]) != null)
        OtherAccount(
          username: getString(entry["user"])!,
          url: getString(entry["url"])!,
        ),
  ];
  providerContainer.read(loginProvider.notifier).setOtherAccounts(otherAccounts);
  final currentLogin = providerContainer.read(loginProvider);
  if ((currentLogin.url != null && currentLogin.url != url) ||
      (currentLogin.username != null && currentLogin.username != user)) {
    // TODO: Figure out when exactly we'd hit this code path and how to handle it better.
    await _doDeletePass();
    providerContainer.read(appRouterProvider).showLogin();
  } else {
    if (user != null && pass != null && (otherAccounts.isEmpty || forceAutoLogin)) {
      // 1 account, or called after an explicit account-selection → auto-login.
      await _doLogin(user, pass, url ?? "", fromStorage: true);
    } else {
      // 0 accounts → show login form.
      // 2+ accounts at cold start → show login form; LoginPage auto-opens account-selection sheet.
      providerContainer.read(appRouterProvider).showLogin();
    }
  }
}

Future<void> _doSaveState({bool immediately = false}) async {
  final loginState = providerContainer.read(loginProvider);
  if (loginState.loggedIn && loginState.username != null) {
    final notifState = providerContainer.read(notificationsProvider);
    _stateToSave = AppState(
      (b) => b
        ..messagesState = providerContainer.read(messagesProvider).toBuilder()
        ..gradesState = providerContainer.read(gradesProvider).toBuilder()
        ..calendarState = providerContainer.read(calendarProvider).toBuilder()
        ..absencesState = providerContainer.read(absencesProvider).toBuilder()
        ..dashboardState = providerContainer.read(dashboardProvider).toBuilder()
        ..profileState = providerContainer.read(profileProvider).toBuilder()
        ..notificationState = NotificationState(
          (b) => b
            ..notifications =
                BuiltList.of(notifState.notifications).toBuilder()
            ..lastFetched = notifState.lastFetched,
        ).toBuilder(),
    );
    if (_saveUnderway && !immediately) return;
    _saveUnderway = true;

    Future<void> save() async {
      final state = _stateToSave;
      final settings = providerContainer.read(settingsProvider);
      final user = getStorageKey(
        providerContainer.read(loginProvider).username,
        wrapper.loginAddress,
      );
      _saveUnderway = false;
      String toSave;
      if (!settings.noDataSaving && !deletedData) {
        toSave = json.encode({
          'v': 2,
          'state': serializers.serialize(state),
          'settings': settings.toJson(),
        });
      } else {
        toSave = json.encode({'v': 2, 'settings': settings.toJson()});
      }
      if (_lastSave == toSave && _lastUsernameSaved == user) return;
      _lastSave = toSave;
      _lastUsernameSaved = user;
      await _writeToStorage(user, toSave);
    }

    if (immediately) {
      await save();
    } else {
      Future.delayed(const Duration(seconds: 5), save);
    }
  }
}

var _saveUnderway = false;

var _lastSave = "";
String? _lastUsernameSaved;
late AppState _stateToSave;
// This is to avoid saving data in an action right after deleting data,
// which would restore it.
@visibleForTesting
bool deletedData = false;

String getStorageKey(String? user, String server) {
  // This is safe because the default Map in dart is a LinkedHashMap, which mantains
  // a stable ordering of its items.
  return json.encode({"username": user, "server_url": server});
}

String escapeKey(String key) {
  if (Platform.isWindows) {
    // secure_storage does not support certain characters on Windows.
    return key.replaceAll(RegExp(r'[\\/:*?"<>|]'), "_");
  }
  return key;
}

Future<void> _writeToStorage(String key, String txt) async {
  await secureStorage.write(key: escapeKey(key), value: txt);
}

Future<String?> _readFromStorage(String key) async {
  try {
    return secureStorage.read(key: escapeKey(key));
  } catch (e) {
    try {
      await secureStorage.deleteAll();
    } catch (e) {
      showSnackBar("Fehler: Bitte versuche, die App neu zu installieren.");
    }
    return null;
  }
}

Future<void> handleRestarted() async {
  if (providerContainer.read(loginProvider).loggedIn &&
      DateTime.now().difference(wrapper.lastInteraction).inMinutes > 3) {
    wrapper.interaction();
    final poppedAnything = _popAll();
    if (!poppedAnything) {
      await providerContainer.read(dashboardProvider.notifier).refresh();
    }
  }
}

Future<void> _doStart(Uri? uri) async {
  providerContainer.read(loginProvider.notifier).clearAfterLoginCallbacks();
  if (uri != null) {
    providerContainer.read(loginProvider.notifier).setUrl(uri.origin);
    final parameters = uri.queryParameters;
    switch (parameters["semesterWechsel"]) {
      case "1":
        providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
          () => providerContainer
              .read(gradesProvider.notifier)
              .setSemester(Semester.first),
        );
      case "2":
        providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
          () => providerContainer
              .read(gradesProvider.notifier)
              .setSemester(Semester.second),
        );
    }
    switch (uri.path) {
      case "":
      case "/":
      case "/v2/":
        break;
      case "/v2/login":
        if (parameters["resetmail"] == "true") {
          final email = parameters["email"];
          final token = parameters["token"];
          unawaited(navigatorKey?.currentState?.pushNamed("/pass_reset"));
          providerContainer.read(loginProvider.notifier).updatePassResetState(
                PassResetState(email: email, token: token),
              );
          return;
        }
        if (parameters["username"] != null) {
          providerContainer
              .read(loginProvider.notifier)
              .setUsername(parameters["username"]!);
        }
        if (parameters["redirect"] != null) {
          await redirectAfterLogin(
              parameters["redirect"]!.replaceFirst("#", ""));
        }
      default:
        showSnackBar("Dieser Link konnte nicht geöffnet werden");
    }
    await redirectAfterLogin(uri.fragment);
  }
  await _doLoad();
}

Future<void> redirectAfterLogin(String location) async {
  switch (location) {
    case "":
    case "dashboard/student":
      break;
    case "student/absences":
      providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
        () => providerContainer.read(appRouterProvider).showAbsences(),
      );
    case "calendar/student":
      providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
        () => providerContainer.read(appRouterProvider).showCalendar(),
      );
    case "student/subjects":
      providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
        () => providerContainer.read(appRouterProvider).showGrades(),
      );
    case "student/certificate":
      providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
        () => providerContainer.read(appRouterProvider).showCertificate(),
      );
    case "message/list":
      providerContainer.read(loginProvider.notifier).addAfterLoginCallback(
        () => providerContainer.read(appRouterProvider).showMessages(),
      );
    default:
      showSnackBar("Dieser Link konnte nicht geöffnet werden");
  }
}

bool _popAll() {
  var poppedAnything = false;
  navigatorKey?.currentState?.popUntil((route) {
    if (!route.isFirst) {
      poppedAnything = true;
    }
    return route.isFirst;
  });
  nestedNavKey.currentState?.popUntil((route) {
    if (!route.isFirst) {
      poppedAnything = true;
    }
    return route.isFirst;
  });
  return poppedAnything;
}

Future<String> _getAttachmentDownloadDirectory() async {
  // TODO: this remains to be tested on all platforms
  try {
    return (await getExternalStorageDirectories(
            type: StorageDirectory.downloads))!
        .first
        .path;
  } catch (_) {
    log("failed to get download directory, falling back to application storage");
    return (await getApplicationDocumentsDirectory()).path;
  }
}

/// Downloads a file.
///
/// Returns true on success and false on a failure.
Future<bool> downloadFile(
  String url,
  String fileName,
  Map<String, dynamic> parameters,
) async {
  await wrapper.ensureLoggedIn();

  final saveFile = File(
    "${await _getAttachmentDownloadDirectory()}/$fileName",
  );
  var success = true;
  if (saveFile.existsSync()) {
    final shouldOverwrite = await askShouldOverwriteFile(fileName);
    if (shouldOverwrite == null) {
      return false;
    } else if (!shouldOverwrite) {
      return true;
    }
  }
  try {
    final result = await wrapper.dio.get<dynamic>(
      url,
      queryParameters: parameters,
      options: dio.Options(responseType: dio.ResponseType.stream),
    );
    final sink = saveFile.openWrite();
    await sink.addStream((result.data as dio.ResponseBody).stream);
    await sink.flush();
    await sink.close();
    success = result.statusCode == 200;
  } catch (e) {
    log("failed to download file $url: $e");
    success = false;
  }

  if (!success && saveFile.existsSync()) {
    // The download was not successful, we should not keep the empty file or whatever was downloaded.
    saveFile.deleteSync();
  }

  return success;
}

Future<bool> canOpenFile(String fileName) async {
  return File(
    "${await _getAttachmentDownloadDirectory()}/$fileName",
  ).existsSync();
}

Future<void> openFile(String fileName) async {
  log("opening file: $fileName");
  await OpenFile.open(
    "${await _getAttachmentDownloadDirectory()}/$fileName",
  );
}

Future<bool?> askShouldOverwriteFile(String fileName) async {
  return navigatorKey!.currentState!.push<bool>(
    DialogRoute(
      builder: (context) {
        return InfoDialog(
          title: const Text("Datei existiert bereits"),
          content: Text(
            "Die Datei \"$fileName\" ist bereits im Downloads-Ordner vorhanden.\n\n"
            "Wenn die Datei erneut heruntergeladen wird, wird die bestehende Datei ersetzt.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bestehende Datei verwenden"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Erneut herunterladen"),
            ),
          ],
        );
      },
      context: navigatorKey!.currentContext!,
    ),
  );
}

Future<void> _checkShowUnmaintainedAlert() async {
  if (skipUnmaintainedAlert) return;
  final appDirectory = await getApplicationSupportDirectory();
  final file = File("${appDirectory.path}/unmaintainedAlertShown");
  if (file.existsSync()) {
    return;
  }

  // A version of this app stored this file to the applications documents directory,
  // which is Documents/ for desktop. The directory was therefore fixed, but we should
  // still check for the file in the old location.
  final legacyFile = File(
      "${(await getApplicationDocumentsDirectory()).path}/unmaintainedAlertShown");
  if (legacyFile.existsSync()) {
    // create the file in the correct location
    file.createSync();
    return;
  }

  await file.create();
}
