# App-Sperre mit Geräte-Authentifizierung (#114)

Stand: 2026-10-07 · Milestone v1.6.0 · Branch `feat/app-lock-114`

## Ziel

Wer das Handy in der Hand hat, sieht Noten, Mitteilungen und Absenzen erst nach
Entsperren — etwa auf einem Gerät, das Geschwister mitbenutzen. Schutz gegen
gerootete Geräte oder forensischen Zugriff ist kein Ziel.

Die Sperre ist in den Einstellungen einschaltbar (Standard: aus). Ist sie an:

- Beim Kaltstart zeigt die App ab dem ersten Frame nichts außer dem
  Sperrbildschirm, bis entsperrt ist.
- Nach der Rückkehr aus dem Hintergrund sperrt sie, wenn der gewählte Puffer
  abgelaufen ist.
- Der Task-Switcher zeigt keine Inhalte (Android 13+ zuverlässig, darunter nach
  bestem Bemühen).
- Systembenachrichtigungen bleiben unverändert.

## Entscheidungen

| Frage | Entscheidung |
|---|---|
| Welche PIN | Nur die Geräte-Sperre: Biometrie mit Rückfall auf PIN/Muster/Passwort des Geräts über `local_auth`. Keine eigene App-PIN. |
| Wann sperren | Wählbarer Puffer: Sofort / 1 / 5 / 15 min, Standard 1 min. Kaltstart sperrt immer. |
| Task-Switcher | Vorschau verbergen, Screenshots erlaubt: `setRecentsScreenshotEnabled(false)` ab API 33, darunter Abdeckung bei `inactive`. Kein `FLAG_SECURE`. |
| Umsetzung | Overlay im `MaterialApp.builder`, nicht als Route und nicht nativ. |

## Bausteine

### Einstellungen — `lib/app_state.dart`

`SettingsState` bekommt:

- `appLockEnabled` (`bool`, Standard `false`)
- `appLockGraceMinutes` (`int`, Standard `1`), erlaubt
  `allowedAppLockGraceMinutes = [0, 1, 5, 15]`; ungültige Werte (JSON, Setter)
  fallen auf `1` zurück, wie bei `notificationPollMinutes`.

Beide werden global in `settings_global` gespeichert (`toGlobalJson` /
`withGlobalJson`), Setter im `SettingsNotifier`.

### `DeviceAuth` — `lib/services/device_auth.dart`

Abstrakte Klasse, Standard-Umsetzung über `LocalAuthentication`:

```dart
enum DeviceAuthResult { success, cancelled, notAvailable, lockedOut, error }

abstract interface class DeviceAuth {
  /// Ob das Gerät eine Sperre (Biometrie oder PIN/Muster/Passwort) hat.
  Future<bool> canAuthenticate();
  Future<DeviceAuthResult> authenticate(String reason);
}
```

- `canAuthenticate` = `isDeviceSupported()`.
- `authenticate` mit `biometricOnly: false`, `persistAcrossBackgrounding: true`
  (bzw. die Entsprechung der eingesetzten `local_auth`-Version).
- Plattform-Ausnahmen werden auf das Enum abgebildet; nichts wirft nach außen.
- Bereitgestellt über `deviceAuthProvider`, in Tests überschrieben.

### `AppLockController` — `lib/providers/app_lock_provider.dart`

Riverpod-`Notifier<AppLockState>` mit `AppLockState(locked, authenticating,
message)`; `message` ist ein Hinweis-Schlüssel für das Overlay (z. B.
`lockedOut`, `error`, `disabled`), sonst `null`.

- **Start:** `locked = appLockInitiallyEnabled` — ein Provider, den `main()` vor
  `runApp` per Override mit dem Wert aus `settings_global` füllt.
- **`onPaused()`:** merkt `_pausedAt = clock()`; bei Puffer 0 sofort
  `locked = true`. Ignoriert, solange `authenticating`.
- **`onResumed()`:** sperrt, wenn Sperre an und `clock() - _pausedAt >=
  Puffer`; dann automatisch `unlock()`. Ignoriert, solange `authenticating`.
- **`unlock()`:** setzt `authenticating`, ruft `DeviceAuth.authenticate`:
  - `success` → `locked = false`
  - `cancelled` → bleibt gesperrt, kein erneuter Auto-Prompt
  - `lockedOut` → bleibt gesperrt, `message = lockedOut`
  - `notAvailable` → `locked = false`, `appLockEnabled = false`,
    `message = disabled` (Geräte-Sperre wurde entfernt; sonst Aussperren)
  - `error` → bleibt gesperrt, `message = error`
- Die Uhr (`DateTime Function() clock`) ist injizierbar.
- Settings-Änderung „aus“ entsperrt sofort.

### `AppLockOverlay` — `lib/ui/app_lock_overlay.dart`

- Liegt im `Stack` des `MaterialApp.builder` (`lib/main.dart`) über
  `SplashOverlay`.
- Gesperrt: deckender Hintergrund (Theme-Farbe), Logo, „App gesperrt“, Hinweis
  aus `message`, Button „Entsperren“ (≥ 48 dp, Semantics-Label). Fängt alle
  Berührungen ab. Der Inhalt darunter bleibt gebaut (Zustand bleibt), steht
  aber in `ExcludeSemantics`, damit TalkBack ihn nicht vorliest; eine
  Live-Region kündigt „App gesperrt“ an.
- Fragt beim ersten Erscheinen automatisch nach (einmal je Sperrvorgang).
- `PopScope(canPop: false)`; „Zurück“ ruft `moveTaskToBack()` über den
  MethodChannel und schickt die App in den Hintergrund, statt Seiten darunter
  zu schließen.
- Unter Android 13 und bei `inactive`: reine Abdeckung ohne Button, solange die
  Sperre an ist (Vorschau-Schutz nach bestem Bemühen).

### Android — `MainActivity.kt` + MethodChannel `dr/app_lock`

Aktive Activity: `android/app/src/main/kotlin/it/digitalesregisterapp/MainActivity.kt`
(`FlutterFragmentActivity`, wie `local_auth` sie braucht).

- `setRecentsHidden(bool)`: ab API 33 `setRecentsScreenshotEnabled(!hidden)`.
- `moveTaskToBack()`.
- Dart-Seite: `lib/services/app_lock_platform.dart`, folgt `appLockEnabled`
  (Listener beim Start und bei Änderung).

### Einstellungen — `lib/ui/settings_page_widget.dart`

Abschnitt „Anmeldung“, nur Android/iOS:

- Schalter „App sperren“ mit Untertitel (Fingerabdruck, Gesicht oder
  Geräte-PIN).
  - Einschalten: `canAuthenticate()`; falls nein → Dialog „Am Gerät ist keine
    Sperre eingerichtet“, Schalter bleibt aus. Falls ja → `authenticate`; nur
    bei `success` an.
  - Ausschalten: ebenfalls nur nach `success`.
- „Sperren nach“: Sofort / 1 / 5 / 15 min, nur sichtbar, wenn die Sperre an ist.

## Ablauf

- **Kaltstart:** `main()` liest `appLockEnabled` aus `settings_global` vor
  `runApp` → Override → Overlay ab dem ersten Frame. `startApp` (Anmeldung,
  Laden) läuft dahinter unverändert.
- **Lifecycle:** am bestehenden `LifecycleObserver` (`lib/main.dart`) neben
  `handlePaused`/`handleRestarted`: `paused` → `onPaused`, `resumed` →
  `onResumed`, `inactive` → Abdeckung unter Android 13.
- **Eigener Dialog:** Biometrie-Dialog, Datei-Picker und Teilen bringen die App
  in `inactive`/`paused`; während `authenticating` ignoriert, sonst deckt sie
  der Puffer ab (bei „Sofort“ sperren sie bewusst).
- **Benachrichtigung antippen:** `openLaunchNotification` und Deep-Links
  navigieren unter dem Overlay; nach dem Entsperren steht das Ziel da.
- **Abmelden / Kontowechsel:** ohne Einfluss; die Sperre gilt der App.
- **Hintergrundabruf:** unverändert.
- **iOS:** gleiche Logik, `NSFaceIDUsageDescription` in `ios/Runner/Info.plist`;
  Vorschau-Schutz nur über die Abdeckung.
- **Desktop/Linux/Web:** Schalter verborgen, Controller nie gesperrt.

## Tests

Unit (`test/providers/app_lock_provider_test.dart`, `FakeDeviceAuth`, feste Uhr):

- Kaltstart gesperrt/nicht gesperrt je nach Override.
- `paused` → `resumed` innerhalb/außerhalb des Puffers für 0, 1, 5, 15 min.
- Lifecycle während `authenticating` ignoriert.
- `unlock()` je Ergebnis wie oben, inkl. Abschalten bei `notAvailable`.
- Settings „aus“ entsperrt.

Unit (`test/settings_provider_test.dart` o. ä.): JSON-Hin-/Rückweg der neuen
Felder; ungültiger Puffer → 1.

Widget:

- `AppLockOverlay` deckt ab, Inhalt nicht im Semantics-Baum, Button ruft
  `unlock`, Zurück schließt keine Seite.
- Einstellungen: ohne Geräte-Sperre Dialog und Schalter aus; mit `success` an;
  Ausschalten nur nach `success`.

Manuell auf dem Pixel (`tools/install-debug.sh`): Kaltstart, Puffer-Varianten,
Task-Switcher-Vorschau, Benachrichtigung antippen bei gesperrter App,
Abbrechen, Geräte-PIN-Rückfall, Geräte-Sperre entfernen.

## Texte und Changelog

- Neue Schlüssel in `lib/l10n/app_de.arb`, `app_en.arb`, `app_it.arb`.
- Changelog 1.6.0 „Neue Funktionen“, dreisprachig, in `assets/changelog.json`,
  dann `dart tools/generate_changelog.dart`.

## Außerhalb des Umfangs

- Eigene App-PIN, Sperre je Konto, `FLAG_SECURE`, Sperre des Hintergrundabrufs.
- Entfernen der ungenutzten
  `android/.../digitales_register/MainActivity.kt` (eigenes Aufräumen).
