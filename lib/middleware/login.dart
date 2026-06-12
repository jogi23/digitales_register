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

part of 'middleware.dart';

void _resetAllProviders() {
  providerContainer.read(dashboardProvider.notifier).reset();
  providerContainer.read(notificationsProvider.notifier).reset();
  providerContainer.read(absencesProvider.notifier).reset();
  providerContainer.read(profileProvider.notifier).reset();
  providerContainer.read(calendarProvider.notifier).reset();
  providerContainer.read(messagesProvider.notifier).reset();
  providerContainer.read(gradesProvider.notifier).reset();
  providerContainer.read(certificateProvider.notifier).reset();
  providerContainer.read(networkProtocolProvider.notifier).reset();
  providerContainer.read(configProvider.notifier).state = null;
  providerContainer.read(dashboardErrorProvider.notifier).state = null;
}

Future<void> _doLogout({required bool hard, bool forced = false}) async {
  if (!providerContainer.read(settingsProvider).noPasswordSaving && hard) {
    await secureStorage.write(
      key: "login",
      value: json.encode(
        <String, Object?>{
          "url": wrapper.url,
          if (await secureStorage.containsKey(key: "login"))
            "otherAccounts": json.decode(
                (await secureStorage.read(key: "login"))!)["otherAccounts"],
        },
      ),
    );
  }
  if (providerContainer.read(settingsProvider).deleteDataOnLogout && hard) {
    deletedData = true;
    await _doSaveState(immediately: true);
  }
  if (!forced) {
    assert(hard);
    wrapper.logout(hard: hard);
  }
  providerContainer.read(loginProvider.notifier).logout(hard: hard);
  providerContainer.read(isDemoProvider.notifier).state = false;
  if (hard) {
    wrapper = Wrapper();
    _resetAllProviders();
    await _doLoad();
  }
}

Future<void> _doLogin(
  String user,
  String pass,
  String url, {
  bool fromStorage = false,
}) async {
  if (user == "" || pass == "") {
    providerContainer.read(loginProvider.notifier).setLoginFailed(
      cause: "Bitte gib etwas ein",
      username: user,
    );
    await _doDeletePass();
    providerContainer.read(appRouterProvider).showLogin();
    return;
  }

  final fixedUrl = fixupUrl(url);
  providerContainer.read(loginProvider.notifier).setLoggingIn();
  wrapper.url = fixedUrl;
  providerContainer.read(loginProvider.notifier).setUrl(fixedUrl);

  bool offlineLogin = false;
  if (fromStorage) {
    await _doLoggedIn(
      username: user,
      fromStorage: true,
      offlineOnly: true,
    );
    offlineLogin = true;
  }

  final dynamic result = await wrapper.login(
    user,
    pass,
    null,
    fixedUrl,
    logout: () => _doLogout(
      hard: providerContainer.read(settingsProvider).noPasswordSaving,
      forced: true,
    ),
    configLoaded: () {
      providerContainer.read(configProvider.notifier).state = wrapper.config;
      providerContainer.read(gradesProvider.notifier).setConfig(wrapper.config);
    },
    relogin: () {
      providerContainer.read(gradesProvider.notifier).resetForRelogin();
    },
    addProtocolItem: (item) {
      providerContainer.read(networkProtocolProvider.notifier).add(item);
    },
  );

  if (await wrapper.loggedIn) {
    if (!wrapper.config.isStudentOrParent) {
      wrapper.logout(hard: true);
      providerContainer.read(loginProvider.notifier).setLoginFailed(
        cause: "Dieser Benutzertyp wird nicht unterstützt.",
      );
      await _doDeletePass();
      providerContainer.read(appRouterProvider).showLogin();
      _showUserTypeNotSupported(fixedUrl);
      return;
    }
    await _doLoggedIn(
      username: wrapper.user!,
      fromStorage: fromStorage,
      secondaryOnlineLogin: offlineLogin,
    );
  } else if (result is Map && result["error"] == "password_expired") {
    await _doDeletePass();
    providerContainer.read(appRouterProvider).showLogin();
    providerContainer
        .read(loginProvider.notifier)
        .setChangePassword(mustChange: true);
  } else {
    final noInternet = wrapper.noInternet;
    if (noInternet) {
      providerContainer.read(noInternetProvider.notifier).setNoInternet(true);
    }
    if (fromStorage) {
      if (!noInternet) {
        showSnackBar(wrapper.error ?? "Verbindung fehlgeschlagen");
      }
      return;
    }
    providerContainer.read(loginProvider.notifier).setLoginFailed(
      cause: wrapper.error ?? "Unknown error",
      username: user,
    );
    await _doDeletePass();
    providerContainer.read(appRouterProvider).showLogin();
  }
}

Future<void> _doLoggedIn({
  required String username,
  bool fromStorage = false,
  bool offlineOnly = false,
  bool keepShowingLoadingIndicator = false,
  bool secondaryOnlineLogin = false,
}) async {
  final currentSettings = providerContainer.read(settingsProvider);
  if (fromStorage) {
    wrapper.safeMode = false;
  }
  if (!currentSettings.noPasswordSaving && !fromStorage) {
    await _doSavePass();
  }
  deletedData = false;
  final key = getStorageKey(username, wrapper.loginAddress);
  if (!providerContainer.read(loginProvider).loggedIn && !secondaryOnlineLogin) {
    log("loading state");
    final state = await _readFromStorage(key);
    if (state != null) {
      try {
        final decoded = json.decode(state);
        if (decoded is Map && decoded['v'] == 2) {
          final restoredSettings =
              SettingsState.fromJson(decoded['settings'] as Map<dynamic, dynamic>)
                  .copyWith(noPasswordSaving: currentSettings.noPasswordSaving);
          providerContainer.read(settingsProvider.notifier).load(restoredSettings);
          if (decoded.containsKey('state')) {
            final appState = serializers.deserialize(decoded['state'] as Object);
            if (appState is AppState) {
              _restoreProvidersFromAppState(appState);
            }
          }
        } else if (decoded is List && decoded.isNotEmpty) {
          if (decoded[0] == 'SettingsState') {
            final restoredSettings = _parseSettingsFromLegacyList(decoded)
                .copyWith(noPasswordSaving: currentSettings.noPasswordSaving);
            providerContainer.read(settingsProvider.notifier).load(restoredSettings);
          } else if (decoded[0] == 'AppState') {
            final legacySettings = _extractSettingsFromLegacyAppState(decoded);
            if (legacySettings != null) {
              providerContainer.read(settingsProvider.notifier).load(
                    legacySettings.copyWith(
                        noPasswordSaving: currentSettings.noPasswordSaving),
                  );
            }
            final appState = serializers.deserialize(decoded as Object);
            if (appState is AppState) {
              _restoreProvidersFromAppState(appState);
            }
          }
        }
        await _doSaveNoPass(
          providerContainer.read(settingsProvider).noPasswordSaving,
        );
      } catch (e) {
        showSnackBar("Fehler beim Laden der gespeicherten Daten");
        log("Failed to load data", error: e);
      }
    }
    _popAll();
  }

  providerContainer.read(loginProvider.notifier).setLoggedIn(
    username: username,
    keepLoading: keepShowingLoadingIndicator,
  );
  final loggedInState = providerContainer.read(loginProvider);
  providerContainer.read(isDemoProvider.notifier).state =
      isDemoUser(url: loggedInState.url, username: loggedInState.username);
  providerContainer.read(loginProvider.notifier).executeAfterLoginCallbacks();
  if (!offlineOnly) {
    await providerContainer.read(dashboardProvider.notifier).load(true);
    await providerContainer.read(notificationsProvider.notifier).load();
    providerContainer
        .read(settingsProvider.notifier)
        .updateSubjectThemes(providerContainer.read(allSubjectsProvider));
  }

  unawaited(_doSaveState(immediately: true));
}

Future<void> _doChangePass(
  String user,
  String oldPass,
  String newPass,
  String url,
) async {
  final dynamic result = await wrapper.changePass(url, user, oldPass, newPass);
  await _doSavePass();
  if (result == null) return;
  if (result["error"] != null) {
    providerContainer.read(loginProvider.notifier).setLoginFailed(
      cause: wrapper.error ?? "Unknown error",
      username: user,
    );
    await _doDeletePass();
    providerContainer.read(appRouterProvider).showLogin();
  } else {
    await _doLogin(user, newPass, url);
    navigatorKey?.currentState?.pop();
    showSnackBar("Passwort erfolgreich geändert");
  }
}

@visibleForTesting
dio.Dio? passDio;

Future<void> _doRequestPassReset(String user, String email) async {
  // the api url DOES NOT contain /v2/ in the path. This is intentional.
  try {
    final dynamic result = (await (passDio ?? dio.Dio()).post<dynamic>(
      "${providerContainer.read(loginProvider).url}/api/auth/resetPassword",
      data: {
        "email": email,
        "username": user,
      },
    ))
        .data;
    if (getMap(result)?["error"] != null) {
      final msg = "[${result["error"]}]: ${result["message"]}";
      providerContainer.read(loginProvider.notifier).updatePassResetState(
            providerContainer
                .read(loginProvider)
                .resetPassState
                .copyWith(failure: true, message: msg),
          );
    } else {
      final msg = (result["message"] as String?)!;
      providerContainer.read(loginProvider.notifier).updatePassResetState(
            providerContainer
                .read(loginProvider)
                .resetPassState
                .copyWith(failure: false, message: msg),
          );
    }
  } catch (e) {
    final loginUrl = providerContainer.read(loginProvider).url;
    if (await cannotConnectTo(loginUrl!)) {
      final msg = "Keine Verbindung mit \"$loginUrl\" möglich";
      providerContainer.read(loginProvider.notifier).updatePassResetState(
            providerContainer
                .read(loginProvider)
                .resetPassState
                .copyWith(failure: true, message: msg),
          );
    } else {
      rethrow;
    }
  }
}

Future<void> _doResetPass(String newPass) async {
  // the api url DOES NOT contain /v2/ in the path. This is intentional.
  final resetState = providerContainer.read(loginProvider);
  final dynamic result = (await (passDio ?? dio.Dio()).post<dynamic>(
    "${resetState.url}/api/auth/setNewPassword",
    data: {
      "username": "",
      "token": resetState.resetPassState.token,
      "email": resetState.resetPassState.email,
      "oldPassword": "",
      "newPassword": newPass,
    },
  ))
      .data;
  if (result["error"] != null) {
    final msg = "[${result["error"]}]: ${result["message"]}";
    providerContainer.read(loginProvider.notifier).updatePassResetState(
          providerContainer
              .read(loginProvider)
              .resetPassState
              .copyWith(failure: true, message: msg),
        );
  } else {
    final msg = result["message"] as String;
    providerContainer.read(loginProvider.notifier).updatePassResetState(
          providerContainer
              .read(loginProvider)
              .resetPassState
              .copyWith(failure: false, message: msg),
        );
  }
}

Future<void> _doAddAccount() async {
  // There might be no loginStorage if "stay logged in" is not enabled.
  final loginStorage = await secureStorage.read(key: "login");
  if (loginStorage != null) {
    // Move the current default user credentials into `otherAccounts`
    final dynamic login = json.decode(loginStorage);
    final otherAccounts = login["otherAccounts"] as List? ?? <Object?>[];
    if (login["user"] != null &&
        login["pass"] != null &&
        login["url"] != null) {
      otherAccounts.insert(0, <String, Object?>{
        "user": login["user"],
        "pass": login["pass"],
        "url": login["url"],
      });
    }
    await secureStorage.write(
      key: "login",
      value: json.encode(
        <String, Object?>{
          "url": login["url"],
          "otherAccounts": otherAccounts,
        },
      ),
    );
  }
  providerContainer.read(loginProvider.notifier).logout(hard: true);
  _resetAllProviders();
  await _doLoad();
}

Future<void> _doSelectAccount(int index) async {
  final dynamic login =
      json.decode((await secureStorage.read(key: "login"))!);
  login["otherAccounts"] ??= <Object?>[];
  final otherAccounts = login["otherAccounts"] as List<Object?>;
  var selectedIndex = index;
  if (login["user"] != null && login["pass"] != null && login["url"] != null) {
    otherAccounts.insert(0, <String, Object?>{
      "user": login["user"],
      "pass": login["pass"],
      "url": login["url"],
    });
    selectedIndex += 1;
  }
  final dynamic selected = otherAccounts.removeAt(selectedIndex);
  login["user"] = selected["user"];
  login["pass"] = selected["pass"];
  login["url"] = selected["url"];
  await secureStorage.write(key: "login", value: json.encode(login));
  await saveStateImmediately();
  providerContainer.read(loginProvider.notifier).logout(hard: true);
  _resetAllProviders();
  await _doLoad();
}

void _restoreProvidersFromAppState(AppState appState) {
  providerContainer.read(gradesProvider.notifier).restore(appState.gradesState);
  providerContainer
      .read(absencesProvider.notifier)
      .restore(appState.absencesState);
  providerContainer
      .read(calendarProvider.notifier)
      .restore(appState.calendarState);
  providerContainer
      .read(messagesProvider.notifier)
      .restore(appState.messagesState);
  providerContainer
      .read(profileProvider.notifier)
      .restore(appState.profileState);
  providerContainer.read(notificationsProvider.notifier).restore(
        NotificationsState(
          notifications:
              appState.notificationState.notifications?.toList() ?? [],
          lastFetched: appState.notificationState.lastFetched,
        ),
      );
}

// Converts old built_value BuiltMap alternating-list encoding to Map<K, V>.
Map<String, String> _legacyListToStringMap(List<dynamic> list) {
  final map = <String, String>{};
  for (int i = 0; i + 1 < list.length; i += 2) {
    map[list[i] as String] = list[i + 1] as String;
  }
  return map;
}

Map<String, SubjectTheme> _legacyListToSubjectThemeMap(List<dynamic> list) {
  final map = <String, SubjectTheme>{};
  for (int i = 0; i + 1 < list.length; i += 2) {
    final key = list[i] as String;
    final themeList = list[i + 1] as List<dynamic>;
    final fields = <String, dynamic>{};
    for (int j = 1; j + 1 < themeList.length; j += 2) {
      fields[themeList[j] as String] = themeList[j + 1];
    }
    map[key] = SubjectTheme(
      thick: fields['thick'] as int? ?? 0,
      color: fields['color'] as int? ?? 0,
    );
  }
  return map;
}

SettingsState _parseSettingsFromLegacyList(List<dynamic> list) {
  // list = ['SettingsState', 'field1', val1, 'field2', val2, ...]
  final fields = <String, dynamic>{};
  for (int i = 1; i + 1 < list.length; i += 2) {
    fields[list[i] as String] = list[i + 1];
  }
  final rawNicks = fields['subjectNicks'];
  final rawThemes = fields['subjectThemes'];
  final rawIgnore = fields['ignoreForGradesAverage'];
  return SettingsState(
    noPasswordSaving: fields['noPasswordSaving'] as bool? ?? false,
    noDataSaving: fields['noDataSaving'] as bool? ?? false,
    askWhenDelete: fields['askWhenDelete'] as bool? ?? true,
    deleteDataOnLogout: fields['deleteDataOnLogout'] as bool? ?? false,
    showCancelled: fields['showCancelled'] as bool? ?? false,
    typeSorted: fields['typeSorted'] as bool? ?? false,
    showGradesDiagram: fields['showGradesDiagram'] as bool? ?? true,
    showAllSubjectsAverage: fields['showAllSubjectsAverage'] as bool? ?? false,
    ignoreForGradesAverage: rawIgnore != null
        ? (rawIgnore as List<dynamic>).cast<String>()
        : [],
    dashboardMarkNewOrChangedEntries:
        fields['dashboardMarkNewOrChangedEntries'] as bool? ?? true,
    dashboardDeduplicateEntries:
        fields['dashboardDeduplicateEntries'] as bool? ?? true,
    dashboardColorBorders: fields['dashboardColorBorders'] as bool? ?? true,
    dashboardColorTestsInRed:
        fields['dashboardColorTestsInRed'] as bool? ?? true,
    showCalendarNicksBar: fields['showCalendarNicksBar'] as bool? ?? true,
    calendarColorBackground: fields['calendarColorBackground'] as bool? ?? false,
    drawerFullyExpanded: fields['drawerFullyExpanded'] as bool? ?? false,
    subjectNicks: rawNicks != null
        ? _legacyListToStringMap(rawNicks as List<dynamic>)
        : null,
    subjectThemes: rawThemes != null
        ? _legacyListToSubjectThemeMap(rawThemes as List<dynamic>)
        : {},
  );
}

SettingsState? _extractSettingsFromLegacyAppState(List<dynamic> list) {
  // list = ['AppState', 'field1', val1, 'settingsState', [...], ...]
  for (int i = 1; i + 1 < list.length; i += 2) {
    if (list[i] == 'settingsState') {
      final raw = list[i + 1];
      if (raw is List && raw.isNotEmpty && raw[0] == 'SettingsState') {
        return _parseSettingsFromLegacyList(raw);
      }
    }
  }
  return null;
}

void _showUserTypeNotSupported(String url) {
  navigatorKey?.currentState?.push(
    MaterialPageRoute<void>(
      builder: (context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Tut uns leid!",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Diese App ist ausschließlich für Schüler*innen und Eltern geeignet.",
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Zurück",
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => launchUrl(Uri.parse(url)),
                    child: const Text(
                      "Hier geht's zur Website",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
