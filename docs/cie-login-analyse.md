# CIE-Anmeldung im Browser nachvollziehen

Ziel: Den kompletten Ablauf „Anmelden mit CIE“ im Digitalen Register Schritt
für Schritt mitschneiden und so dokumentieren, dass sich daraus ableiten lässt,
wie die App die Anmeldung übernehmen kann.

Ausgangslage in der App: Heute meldet sich die App nur per Passwort an. Sie
schickt `POST <schule>/v2/api/auth/login` mit `username`, `password` und bei
Bedarf `two_factor` (`lib/auth_service.dart`, `lib/api_client.dart`). Danach
lädt sie `GET <schule>/v2/` und liest daraus die Konfiguration
(`_loadConfig`). Die Sitzung hängt allein an den Cookies im `CookieJar` von
Dio. SPID/CIE gibt es nur als Hinweis in den Einstellungen, dass diese Konten
keine Hintergrund-Benachrichtigungen bekommen.

Die zentrale Frage lautet also: **Über welche Stationen läuft die CIE-Anmeldung,
und welches Cookie (oder welcher Token) steht am Ende auf der Domain der Schule?**

---

## 0. Vorbereitung

1. **Testkonto klären:** eine echte CIE mit Zugang zum Digitalen Register
   (Schüler- oder Elternkonto), dazu die CieID-App auf dem Handy mit
   eingerichteter Stufe 2 (Benutzername/Passwort plus Bestätigung in der App).
   Wer über Stufe 3 gehen will, braucht Karte + PIN und NFC-Handy oder einen
   Kartenleser.
2. **Sauberes Browserprofil:** ein eigenes Chrome- oder Firefox-Profil (oder ein
   privates Fenster) ohne Erweiterungen, die Anfragen verändern
   (Adblocker, Privacy-Badger usw.). Sonst fehlen Cookies oder Weiterleitungen.
3. **Werkzeuge installieren:**
   - Browser-DevTools (F12), Tab **Netzwerk**
   - Erweiterung **SAML-tracer** (Firefox/Chrome): dekodiert `SAMLRequest` und
     `SAMLResponse` automatisch
   - optional für schwierige Fälle: `chrome://net-export` (zeichnet auch
     Anfragen auf, die DevTools bei Seitenwechseln verliert)
4. **Ablageort für Mitschnitte** außerhalb des Repos. HAR-Dateien enthalten
   Session-Cookies, Codice Fiscale, Name und Geburtsdatum. Sie gehören **nie**
   ins Repo, in Issues oder in Chats (`*.har` steht deshalb in `.gitignore`).

## 1. Ausgangspunkt festhalten

1. Schul-URL öffnen, z. B. `https://<schule>.digitalesregister.it/v2/login`.
2. Screenshot der Login-Seite, Wortlaut des CIE/SPID-Buttons notieren.
3. Rechtsklick auf den Button → „Untersuchen“: Ist es ein Link (`href`), ein
   Formular (`action`, `method`, versteckte Felder) oder ein JavaScript-Handler?
   Ziel-URL notieren.
4. Im Tab **Anwendung → Cookies** nachsehen, welche Cookies **vor** der
   Anmeldung schon auf der Schul-Domain liegen (Name, Domain, Pfad,
   `HttpOnly`, `Secure`, `SameSite`, Ablauf).

## 2. Mitschnitt starten

1. DevTools → **Netzwerk** öffnen.
2. Häkchen bei **„Log beibehalten“ / „Preserve log“** (sonst ist nach jeder
   Weiterleitung alles weg) und bei **„Cache deaktivieren“**.
3. Filter auf **Alle**, Spalten `Status`, `Methode`, `Domain`, `Typ`,
   `Initiator` einblenden.
4. SAML-tracer parallel starten.
5. Alten Mitschnitt leeren, dann erst den CIE-Button drücken.

## 3. Anmeldung durchklicken und jede Station notieren

Beim Durchklicken nichts beschleunigen. Nach jeder sichtbaren Seite kurz
innehalten und im Netzwerk-Tab die neuen Einträge anschauen.

Erwartete Stationen (die tatsächlichen können abweichen, genau das gilt es
herauszufinden):

| # | Station | Worauf achten |
|---|---------|---------------|
| A | Digitales Register leitet weiter | Status `302`/`303` oder auto-submit-Formular? Ziel-Domain? |
| B | Eventuell ein Vermittler (z. B. Landes-Login/Broker, IdP-Auswahl SPID/CIE) | Eigene Domain? Eigene Cookies? Auswahlseite? |
| C | CIE-Identity-Provider des Innenministeriums (`*.servizicie.interno.gov.it` o. ä.) | Protokoll: SAML (`SAMLRequest`, `RelayState`) oder OpenID Connect (`/authorize?client_id=…&redirect_uri=…&state=…&nonce=…`)? |
| D | Eingabe Benutzername/Passwort (Stufe 2) bzw. Kartenleser/QR-Code (Stufe 3) | Welche Stufe verlangt der Dienst (`AuthnContextClassRef` bzw. `acr_values`: `SpidL1/L2/L3`)? |
| E | Bestätigung in der CieID-App / QR-Code | Pollt die Seite im Hintergrund (XHR alle paar Sekunden)? Welche URL? |
| F | Einwilligungsseite („Daten übermitteln an …“) | Welche Attribute werden übergeben (Name, Codice Fiscale, …)? |
| G | Rücksprung zum Vermittler bzw. zum Register | `POST` mit `SAMLResponse` oder `GET` mit `?code=…&state=…`? An welche URL (Assertion Consumer Service / `redirect_uri`)? |
| H | Digitales Register setzt die Sitzung | Welche Antwort enthält `Set-Cookie` für die Schul-Domain? Wohin wird danach geleitet (`/v2/`, Dashboard)? |

Für **jede** Station im Protokoll festhalten:

- vollständige URL (Query-Parameter später schwärzen)
- Methode und Statuscode
- `Location`-Header bei Weiterleitungen
- `Set-Cookie`-Header (Name, Domain, Pfad, Flags, Ablauf; Wert nur gekürzt)
- Formularfelder bei `POST` (Payload-Tab)
- ob die Seite nur per JavaScript weiterspringt (auto-submit-Formular,
  `window.location`)

## 4. Protokoll bestimmen

Mit SAML-tracer bzw. dem Payload-Tab:

- **SAML:** `SAMLRequest` dekodieren lassen. Notieren: `Issuer` (wer fragt
  an), `AssertionConsumerServiceURL`, `AuthnContextClassRef`, `ForceAuthn`.
  Bei der `SAMLResponse`: `Destination`, `Audience`, `NotOnOrAfter` und die
  Liste der Attribute (die Werte nicht abschreiben).
- **OpenID Connect:** `client_id`, `redirect_uri`, `scope`, `response_type`,
  `acr_values`, ob PKCE genutzt wird (`code_challenge`). Beim Rücksprung:
  Wird der `code` im Browser gegen einen Token getauscht (dann taucht ein
  `POST …/token` im Netzwerk-Tab auf) oder serverseitig vom Register (dann
  nicht sichtbar)?

Wichtig für die App: Wer am Ende den Token bekommt, **der Browser oder der
Server des Registers**. Im zweiten Fall bleibt für die App nur das
Session-Cookie der Schul-Domain.

## 5. Ergebnis auf der Schul-Domain untersuchen

1. Nach erfolgreicher Anmeldung **Anwendung → Cookies** der Schul-Domain mit
   dem Stand aus Schritt 1.4 vergleichen: Welches Cookie ist neu oder hat
   sich geändert? Das ist mit hoher Wahrscheinlichkeit die Sitzung.
2. **Local Storage / Session Storage** ansehen: Liegt dort ein Token?
3. Im Netzwerk-Tab eine spätere API-Anfrage anklicken (z. B.
   `api/notification/unread` oder `api/student/all_subjects`) und prüfen,
   was sie mitschickt: nur `Cookie` oder zusätzlich `Authorization`/eigene
   Header?
4. Die Antwort auf `GET /v2/` ansehen: Ist sie gleich aufgebaut wie beim
   Passwort-Login? Das entscheidet, ob `ConfigParser.parse` unverändert
   funktioniert.

## 6. Gegenprobe: Sitzung außerhalb des Browsers verwenden

So lässt sich prüfen, ob „Cookie übernehmen“ für die App reicht.

1. Den Wert des Sitzungs-Cookies aus DevTools kopieren.
2. Im Terminal:
   ```sh
   curl -s -H 'Cookie: <name>=<wert>' \
     'https://<schule>.digitalesregister.it/v2/api/notification/unread'
   ```
   Kommt JSON statt eines Login-Fehlers, reicht das Cookie allein.
3. Zusätzlich testen, ob der Server das Cookie an `User-Agent`, IP oder
   weitere Cookies bindet (anderer User-Agent, anderes Netz, nur dieses eine
   Cookie).
4. Lebensdauer messen: Uhrzeit der Anmeldung notieren und die Anfrage nach
   30 min, 2 h, 12 h und 24 h ohne Zwischenaktivität wiederholen. Danach auch
   mit Aktivität (verlängert sich die Sitzung gleitend?).
5. Abmelden im Browser und prüfen, ob das Cookie serverseitig sofort
   ungültig ist.

Nach den Tests im Browser abmelden, damit das kopierte Cookie nicht gültig
bleibt.

## 7. Sonderfälle durchspielen

- **Handy-Browser statt Desktop:** Läuft Stufe 2 dort per App-Wechsel (Deep
  Link `cieid://…` bzw. Universal Link) statt QR-Code? Relevant, weil die App
  genau diesen Weg in einem WebView/Custom Tab gehen muss. Mitschnitt am
  Android-Handy über `chrome://inspect` (USB-Debugging) am Desktop-Chrome.
- **Abbruch** im CieID-Dialog und **falsches Passwort**: Wohin wird
  zurückgeleitet, mit welcher Fehlermeldung/welchem Parameter?
- **Zweite Anmeldung** kurz danach: Überspringt der IdP die Eingabe
  (Single-Sign-On-Cookie beim IdP)? Wie lange?
- **Mehrere Konten** (z. B. Elternteil mit zwei Kindern, oder dieselbe CIE an
  zwei Schulen): Gibt es nach der CIE eine Kontoauswahl im Register?
- **SPID** zum Vergleich einmal durchklicken: Wenn der Rücksprung ins Register
  identisch ist, lässt sich beides mit demselben Code abdecken.

## 8. Ergebnis zusammenfassen

Am Ende sollte ein kurzes Dokument (ohne personenbezogene Daten) diese Fragen
beantworten:

1. Start-URL für die CIE-Anmeldung (fest oder pro Schule verschieden?)
2. Liste der Stationen mit Domain, Protokoll und Weiterleitungsart
3. **Erfolgs-URL**: an welcher URL erkennt man, dass die Anmeldung fertig ist?
4. **Sitzungsträger**: Cookie-Name(n), Domain, Pfad, Flags, Lebensdauer
5. Reicht das Cookie allein für die API (Ergebnis aus Schritt 6)?
6. Liefert `GET /v2/` danach dieselbe Konfiguration wie beim Passwort-Login?
7. Verhalten bei Ablauf: Leitet die API auf die Login-Seite um oder liefert sie
   einen Fehler, und in welchem Format?
8. Funktioniert der Ablauf im mobilen Browser inklusive Wechsel zur CieID-App?

## 9. Was daraus für die App folgt (Vorschau)

Je nach Ergebnis zeichnen sich zwei Wege ab:

- **Cookie reicht (wahrscheinlich):** Anmeldung in einem WebView bzw. Custom
  Tab öffnen, die Erfolgs-URL aus 8.3 abfangen, die Cookies aus 8.4 auslesen
  und in den `CookieJar` von `ApiClient` übertragen, danach `_loadConfig()`
  wie gewohnt. Eine stille Neuanmeldung ohne Nutzer ist nicht möglich
  (Bestätigung in der CieID-App nötig). Das passt zum bestehenden Hinweis,
  dass SPID/CIE-Konten keine Hintergrund-Benachrichtigungen bekommen.
- **Token statt Cookie:** Token aus Storage/Antwort übernehmen und als Header
  in Dio setzen; Details hängen an Schritt 4 und 5.

Offene Punkte für die Umsetzung, die schon beim Mitschnitt mitgedacht werden
sollten: Speichern der Sitzung pro Konto im bestehenden Mehrkonten-System,
Erkennen einer abgelaufenen Sitzung, und ob `SessionManager` statt eines
Passwort-Relogins den Nutzer erneut zur CIE-Anmeldung schicken muss.
