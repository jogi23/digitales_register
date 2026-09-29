# CIE-Anmeldung im Browser nachvollziehen

Ziel: Die Anmeldung im Digitalen Register bei Konten, die nach dem Passwort
eine Bestätigung per CIE verlangen, Schritt für Schritt mitschneiden. Daraus
soll hervorgehen, wie die App diese Anmeldung übernehmen kann.

## Ausgangslage

**Ablauf im Register (beobachtet):** Die CIE ist hier kein Ersatz für das
Passwort, sondern der **zweite Faktor**. Zuerst gibt man Benutzername und
Passwort ein. Erst wenn diese stimmen **und** das Konto 2FA verlangt, erscheint
die CIE-Anmeldung. Konten ohne 2FA sehen die CIE nie.

**Was die App heute kann** (`lib/auth_service.dart`, `lib/api_client.dart`):

1. `POST <schule>/v2/api/auth/login` mit `username`, `password` und bei Bedarf
   `two_factor` (ein Code).
2. Die Antwort ist JSON. Bei `"loggedIn": true` lädt die App `GET <schule>/v2/`
   und liest daraus die Konfiguration (`_loadConfig`).
3. Bei `"error": "two_factor_needed"` fragt sie nach einem Code und schickt
   den Login erneut mit `two_factor` (`two_factor_wrong` bei falschem Code).
4. Die Sitzung hängt allein an den Cookies im `CookieJar` von Dio.

Für die CIE als zweiten Faktor gibt es keinen Code, den die App eintragen
könnte. Die zentralen Fragen lauten also:

- **Was antwortet `api/auth/login` bei einem Konto mit CIE-2FA?** Welcher
  Fehlercode, welche Felder, eine URL für die CIE?
- **Wann entsteht die Sitzung?** Schon nach dem Passwort (und die CIE schaltet
  sie nur frei) oder erst nach der CIE?
- **Wie kommt man nach der CIE zurück**, und welches Cookie trägt danach die
  Sitzung?

## Beteiligte und Geräte

| | Teil 1: Vergleichsbasis | Teil 2: CIE-Anmeldung |
|---|---|---|
| Konto | eigenes Konto, **ohne** 2FA | Konto der Testperson, **mit** 2FA per CIE |
| Wer tippt | du | Testperson (Passwort, CieID-App); du bedienst die DevTools |
| Geräte | PC | PC für den Mitschnitt, Handy der Testperson mit CieID-App zum Bestätigen |

Mitgeschnitten wird immer am **PC**. Das Handy dient in Teil 2 nur zum
Bestätigen in der CieID-App. Der Durchgang im Handy-Browser kommt erst in
Teil 3.

---

## Vorbereitung (einmalig)

1. **Eigenes Chrome-Profil** ohne weitere Erweiterungen (Profilbild oben rechts
   → „Hinzufügen“). Adblocker und Co. können Weiterleitungen und Cookies stören.
2. Darin die Erweiterung **SAML-tracer** installieren
   (Chrome-Web-Store-ID `mpdajninpobndbfcldcmbpnnbhibjmch`, Projekt
   `simplesamlphp/SAML-tracer`).
3. **Ordner für Mitschnitte außerhalb des Repos**, z. B.
   `Dokumente\CIE-Mitschnitt`. HAR-Dateien und Screenshots enthalten
   Session-Cookies, Namen und Codice Fiscale. Sie gehören nie ins Repo, in
   Issues oder in Chats (`*.har` steht in `.gitignore`, Screenshots nicht).
4. `curl` für die Gegenprobe (unter Windows 10/11 als `curl.exe` dabei).
5. **Mit der Testperson vorab klären:**
   - Die CieID-App ist aktiviert, sie kennt ihre CieID-Zugangsdaten, die Karte
     samt PIN liegt bereit.
   - Sie ist einverstanden, dass ihr Login mitgeschnitten wird. Du gibst
     nichts davon weiter, und am Ende meldet sie sich ab.
   - Sie tippt ihr Passwort selbst ein. Im Mitschnitt steht es dann trotzdem
     im Klartext (Payload von `api/auth/login`), also die HAR-Datei entsprechend
     behandeln oder nach der Auswertung löschen.

### Einstellungen vor jedem Mitschnitt

1. Die Login-Seite der Schule öffnen (`https://<schule>.digitalesregister.it/v2/login`),
   **noch nichts eingeben**.
2. F12 → Tab **Netzwerk**: „Log beibehalten“ und „Cache deaktivieren“ anhaken,
   Filter auf **Alle**, Mitschnitt leeren.
3. Tab **Anwendung → Cookies** für die Schul-Domain: Stand **vorher**
   festhalten (Screenshot genügt).
4. **SAML-tracer** über das Erweiterungs-Symbol öffnen. Er zeichnet nur auf,
   solange sein Fenster offen ist.

---

## Teil 1: Vergleichsbasis mit dem eigenen Konto (ohne 2FA)

Kann sofort und allein erledigt werden.

1. Einstellungen wie oben.
2. Mit eigenem Benutzernamen und Passwort anmelden.
3. Im Netzwerk-Tab den Eintrag **`login`** (`POST …/v2/api/auth/login`)
   anklicken und festhalten:
   - **Payload:** welche Felder werden geschickt? (Nur die Feldnamen notieren.)
   - **Antwort:** das JSON, also `loggedIn` und weitere Felder.
   - **Header der Antwort:** alle `Set-Cookie`-Zeilen (Name, Pfad, Flags,
     Ablauf; Wert nur gekürzt).
4. Die Anfragen danach notieren: vermutlich `GET /v2/` und erste API-Aufrufe.
   Schickt eine API-Anfrage nur `Cookie` mit oder zusätzlich `Authorization`
   oder eigene Header?
5. **Cookies nachher** mit dem Stand vorher vergleichen: Welches Cookie ist neu
   oder hat einen neuen Wert? Das ist der Sitzungsträger beim normalen Login.
6. Ist SAML-tracer leer geblieben? Das ist zu erwarten, sonst notieren, was
   auftaucht.
7. HAR speichern (Rechtsklick im Netzwerk-Tab → „Alle als HAR speichern“).
8. Abmelden und dabei mitschneiden, welche Anfrage das auslöst.

**Ergebnis Teil 1:** Antwort-JSON des Logins, Name(n) des Sitzungs-Cookies,
die ersten Anfragen nach dem Login.

### Befund Teil 1 (29.09.2026, Grundschulen Schlanders, Konto ohne 2FA)

- Die Login-Seite zeigt nur Benutzername/Passwort, keinen SPID/CIE-Button.
  Vor dem Login liegen **keine Cookies** auf der Schul-Domain.
- `POST /v2/api/auth/login`, Payload `{"username", "password"}` (JSON), Antwort
  `{"error":null,"loggedIn":true}`.
- Dieselbe Antwort setzt die Sitzung. Beide Cookies gelten für die ganze
  Schul-Domain (`.gs-schlanders…`, Pfad `/`) und sind Sitzungs-Cookies ohne
  Ablaufdatum:
  - `PHPSESSID`: `Secure`, `HttpOnly`
  - `registerSession`: `Secure`, `HttpOnly`, `SameSite=Lax`. Es wird in der
    Antwort zweimal gesetzt: zuerst mit `Max-Age=0` (ein altes löschen),
    dann neu.
- Danach: `GET /v2/` (HTML, daraus liest die App die Konfiguration),
  `POST api/student/dashboard/dashboard`, `POST api/notification/unread`.
  API-Anfragen schicken nur die Cookies mit, keinen `Authorization`-Header.
- Etwa alle 2 min `POST api/auth/extendSession` mit `{"lastAction": <Unix-Zeit>}`,
  Antwort `{"forceLogout":false,"newExpiration":…,"serverTime":…,"noSession":false}`.
  `newExpiration` liegt 20 min nach `lastAction`: Die Sitzung läuft nach
  **20 min ohne Aktion** ab. Die App kennt diesen Aufruf bereits
  (`lib/session_manager.dart`).
- SAML-tracer hat nichts SAML-Spezifisches aufgezeichnet (erwartet).
- Aufgefallen: AdGuard lief systemweit mit (`injections.adguard.org`) und
  steht sogar in der Content-Security-Policy des Registers. Für Teil 2
  AdGuard für die beteiligten Domains pausieren.

### Befund Vorab-Test SPID/CIE (29.09.2026, MS Welsberg, Elternkonto)

**Korrektur der Ausgangslage:** Zumindest an dieser Schule ist SPID/CIE kein
zweiter Faktor nach dem Passwort. Die Login-Seite hat einen **eigenen
Abschnitt „Anmelden über SPID/CIE“** (für Eltern) mit nur einem Feld
„Benutzername“, ohne Passwort. Schulen ohne SPID/CIE (z. B. Grundschulen
Schlanders) zeigen den Abschnitt nicht.

Ablauf bis zur Auswahlseite:

1. `POST /v2/api/auth/login_spidcie`, Payload `{"username": "<benutzer>"}`.
   Antwort (JSON):
   ```json
   {"url": "https://eid.istruzione.it/eid-gateway-oidc/oauth2/authorize?response_type=code&client_id=8cb11910-0b28-42ec-a8cb-69d11fed5914&scope=openid+gateway&redirect_uri=https%3A%2F%2F<schule>.digitalesregister.it%2Fv2%2Foidc_auth.php&state=<schule>%3B<benutzer>&aggregate_ref_type=MECHANOGRAPHIC_CODE&aggregate_ref_value=<schulcode>"}
   ```
   Die Antwort setzt nur `PHPSESSID` (`Secure`, `HttpOnly`, Pfad `/`),
   noch kein `registerSession`.
2. Der Browser folgt der URL. Protokoll: **OpenID Connect**,
   Authorization-Code-Flow, **ohne PKCE und ohne `nonce`**.
   - Vermittler: **MIM eID-Gateway** (`eid.istruzione.it`) des
     Bildungsministeriums.
   - `client_id` ist offenbar die Kennung des Digitalen Registers (gleich für
     alle Schulen?).
   - `state` = `<schul-subdomain>;<benutzername>` im Klartext.
   - `aggregate_ref_value` = Schulcode (codice meccanografico) des Sprengels.
   - **`redirect_uri` = `https://<schule>.digitalesregister.it/v2/oidc_auth.php`**:
     Dort endet die Anmeldung (Erfolgs-URL).
3. `…/eid-gateway-oidc/oauth2/authorize` → `…/eid-gateway/?client_id=…` →
   Auswahlseite „Entra con SPID / Entra con CIE“.
   Cookies auf `eid.istruzione.it` bis hier nur Dynatrace-Monitoring
   (`dtCookie`, `dtPC`, `dtSa`, `rxVisitor`, `rxvt`), keine Sitzung.

Noch offen: Station „CIE-Anbieter“ und vor allem der Rücksprung auf
`oidc_auth.php` (welche Cookies dort gesetzt werden, wohin es danach geht).

**Vorläufige Folgerung für die App:** `login_spidcie` selbst aufrufen
(`PHPSESSID` landet im `CookieJar`), die `url` aus der Antwort in einem
WebView/Custom Tab öffnen, die Navigation auf `/v2/oidc_auth.php` abfangen
und diese URL mit Dio und dem vorhandenen `PHPSESSID` selbst aufrufen. Dann
entstehen die Sitzungs-Cookies direkt in der App, ohne Cookie-Übertragung
aus dem WebView. Muss mit dem Rücksprung bestätigt werden.

Für Teil 2 heißt das: Beim Konto mit CIE-2FA vor allem darauf achten, ob die
Login-Antwort **trotzdem** `PHPSESSID` und `registerSession` setzt und was
statt `"loggedIn":true` zurückkommt.

---

## Teil 2: CIE-Anmeldung mit der Testperson

Der Mitschnitt läuft in **einem** Stück, von der Login-Seite bis zum
Dashboard. Das Log erst am Ende leeren.

### 2.1 Passwort-Schritt

1. Einstellungen wie oben, Cookie-Stand **vorher** festhalten.
2. Die Testperson gibt Benutzername und Passwort ein und schickt ab.
3. **Sofort pausieren**, bevor irgendetwas weitergeklickt wird:
   - Eintrag **`login`** → Tab **Antwort**: Das ist die wichtigste Stelle des
     ganzen Tests. Welcher `error`-Code, welche `message`, gibt es eine URL,
     einen Token oder eine ID für den CIE-Schritt?
   - `Set-Cookie` in dieser Antwort: Wird hier schon ein Sitzungs-Cookie
     gesetzt? Derselbe Name wie in Teil 1?
   - Cookies **nach dem Passwort** festhalten (zweiter Screenshot).
4. Was zeigt die Seite jetzt: eine Auswahl der Methoden (Code oder CIE), direkt
   einen CIE-Button oder eine automatische Weiterleitung? Screenshot.
5. Wenn es einen Button gibt: Rechtsklick → „Untersuchen“ und notieren, ob
   er ein Link (`href`), ein Formular (`action`, versteckte Felder) oder
   JavaScript ist. Löst er eine API-Anfrage aus (z. B. eine, die die CIE-URL
   holt), diese Anfrage samt Antwort festhalten.

### 2.2 CIE-Schritt

Jetzt weiterklicken und die Stationen der Reihe nach festhalten:

| # | Station | Worauf achten |
|---|---------|---------------|
| A | Register leitet zur CIE weiter | `302`/`303` oder auto-submit-Formular? Ziel-Domain? |
| B | Eventuell ein Vermittler (Landes-Login o. ä.) | Eigene Domain, eigene Cookies, Auswahlseite? |
| C | CIE-Anbieter des Innenministeriums (`*.servizicie.interno.gov.it` o. ä.) | SAML (`SAMLRequest`, `RelayState`) oder OpenID Connect (`/authorize?client_id=…&redirect_uri=…&state=…`)? |
| D | CieID-Anmeldung | Welche Stufe (`AuthnContextClassRef` bzw. `acr_values`: L1/L2/L3)? QR-Code am PC oder Push aufs Handy? |
| E | Bestätigung in der CieID-App | Fragt die Seite im Hintergrund regelmäßig nach (XHR alle paar Sekunden)? Welche URL? |
| F | Einwilligung („Daten übermitteln an …“) | Welche Attribute (nur die Namen, z. B. Codice Fiscale)? |
| G | Rücksprung | `POST` mit `SAMLResponse` oder `GET` mit `?code=…&state=…`? An welche URL? Zum Vermittler oder direkt ins Register? |
| H | Register schließt die Anmeldung ab | Welche Antwort setzt oder ändert das Sitzungs-Cookie? Wohin geht es danach (`/v2/`, Dashboard)? Fällt dabei eine API-Anfrage wie `api/auth/…` auf? |

Für **jede** Station notieren: URL (Parameter später schwärzen), Methode,
Status, `Location`, `Set-Cookie`, bei `POST` die Feldnamen, und ob die Seite
per JavaScript weiterspringt.

Mit SAML-tracer bzw. dem Payload-Tab außerdem:

- **SAML:** aus dem `SAMLRequest` `Issuer`, `AssertionConsumerServiceURL`,
  `AuthnContextClassRef`; aus der `SAMLResponse` `Destination`, `Audience`,
  `NotOnOrAfter` und die Namen der Attribute (keine Werte).
- **OpenID Connect:** `client_id`, `redirect_uri`, `scope`, `acr_values`,
  PKCE (`code_challenge`) ja/nein. Taucht im Browser ein `POST …/token` auf,
  oder tauscht der Server des Registers den Code selbst?

### 2.3 Nach der Anmeldung

1. Cookies **nachher** festhalten (dritter Screenshot) und mit „vorher“ und
   „nach dem Passwort“ vergleichen:
   - Gleiches Cookie wie nach dem Passwort, nur jetzt gültig? → Die CIE
     schaltet eine bestehende Sitzung frei.
   - Neues Cookie oder neuer Wert? → Die Sitzung entsteht erst nach der CIE.
2. Local Storage und Session Storage der Schul-Domain ansehen: liegt dort ein
   Token?
3. Eine API-Anfrage anklicken (z. B. `api/notification/unread`) und prüfen,
   was sie mitschickt.
4. Die Antwort auf `GET /v2/` mit Teil 1 vergleichen: gleich aufgebaut? Davon
   hängt ab, ob `ConfigParser.parse` unverändert funktioniert.
5. HAR speichern, in SAML-tracer „Export“ speichern.

### 2.4 Gegenprobe mit dem Cookie

Noch **vor** dem Abmelden:

1. Den Wert des Sitzungs-Cookies aus DevTools kopieren.
2. Im Terminal:
   ```sh
   curl -s -H 'Cookie: <name>=<wert>' \
     'https://<schule>.digitalesregister.it/v2/api/notification/unread'
   ```
   JSON statt Login-Fehler → das Cookie allein reicht.
3. Mit anderem User-Agent wiederholen (`-A 'Test'`), um eine Bindung an den
   Browser auszuschließen.
4. Falls die Testperson einverstanden ist: Lebensdauer testen (nach 30 min,
   2 h, 12 h ohne Aktivität erneut abfragen). Sonst diesen Punkt weglassen.
5. Zum Schluss meldet sich die Testperson im Browser ab. Danach die
   `curl`-Anfrage noch einmal: Ist das Cookie jetzt ungültig?

### 2.5 Sonderfälle, falls Zeit bleibt

- **Abbruch** im CieID-Dialog: Wohin geht es zurück? Mit welcher Meldung? Ist
  man danach halb angemeldet (Cookie aus 2.1 noch gültig)?
- **Zweiter Login** kurz danach: Verlangt das Register die CIE erneut, oder
  merkt es sich das Gerät („diesem Gerät vertrauen“)? Überspringt der
  CIE-Anbieter die Eingabe (Single Sign-on)?
- Gibt es neben der CIE noch eine andere 2FA-Methode (Code per App/E-Mail),
  die die App schon unterstützen würde?

---

## Teil 3: Durchgang im Handy-Browser (optional, später)

Wichtig, weil die App denselben Weg gehen muss: Im Handy-Browser öffnet sich
statt QR-Code meist direkt die CieID-App, danach springt es zurück in den
Browser.

1. Auf dem Android-Handy der Testperson die Entwickleroptionen und
   **USB-Debugging** einschalten und das Handy per USB an den PC anschließen.
2. Am PC in Chrome `chrome://inspect` öffnen und beim Tab des Handys auf
   „inspect“ klicken. Die DevTools des Handy-Browsers laufen dann am PC.
3. Teil 2 im Handy-Browser wiederholen. Besonders auf den Sprung zur
   CieID-App achten (Deep Link `cieid://…` oder App-Link) und darauf, ob der
   Rücksprung im selben Browser-Tab landet.

(iPhone: nur über einen Mac mit Safari → Entwickler-Menü.)

---

## Ergebnisse weitergeben

Weitergeben (z. B. an Claude oder ins Issue) nur die **geschwärzte**
Zusammenfassung, nie die HAR-Dateien selbst:

- Domains, Pfade, Methoden, Statuscodes der Stationen
- Namen der Cookies und Header, **keine Werte**
- Antwort-JSON von `api/auth/login` mit ersetzten persönlichen Angaben
- keine `SAMLResponse`, keine Tokens, keine Codes, kein Codice Fiscale

## Fragen, die am Ende beantwortet sein sollen

1. Was antwortet `api/auth/login` bei einem Konto mit CIE-2FA (Fehlercode,
   Felder, URL)?
2. Wie gelangt man von dort zur CIE: feste URL, URL aus der Antwort oder eine
   weitere API-Anfrage?
3. Stationen der CIE-Anmeldung mit Domain, Protokoll und Art der Weiterleitung.
4. **Erfolgs-URL:** Woran erkennt man, dass die Anmeldung fertig ist?
5. **Sitzungsträger:** Cookie-Name(n), Domain, Pfad, Flags. Derselbe wie in
   Teil 1? Entsteht er vor oder nach der CIE?
6. Reicht das Cookie allein für die API (Gegenprobe)?
7. Liefert `GET /v2/` dieselbe Konfiguration wie in Teil 1?
8. Wie lange hält die Sitzung, und was antwortet die API, wenn sie abgelaufen
   ist?
9. Funktioniert der Ablauf im Handy-Browser inklusive Wechsel zur CieID-App?

## Was daraus für die App folgt (Vorschau)

Wahrscheinlichster Weg, je nach Ergebnis:

1. Die App schickt wie bisher `api/auth/login` mit Benutzername und Passwort.
2. Bei der neuen Antwort aus Frage 1 öffnet sie einen WebView bzw. Custom Tab
   mit der CIE-URL aus Frage 2, **mit denselben Cookies** wie im `CookieJar`
   (falls die Sitzung schon nach dem Passwort entsteht).
3. Sie wartet auf die Erfolgs-URL aus Frage 4, übernimmt die Cookies aus dem
   WebView zurück in den `CookieJar` und lädt `_loadConfig()` wie gewohnt.

Offene Punkte für die Umsetzung:

- Eine stille Neuanmeldung ist nicht möglich, weil die Bestätigung in der
  CieID-App nötig ist. Das passt zum bestehenden Hinweis, dass SPID/CIE-Konten
  keine Hintergrund-Benachrichtigungen bekommen. `SessionManager` muss bei
  abgelaufener Sitzung den Nutzer zur CIE schicken statt still neu anzumelden.
- Sitzung pro Konto im bestehenden Mehrkonten-System speichern.
- Falls sich das Register ein vertrautes Gerät merkt (Sonderfall in 2.5), muss
  die App das entsprechende Cookie dauerhaft behalten.
