# Theos und Idas Mathe-Spiele (zwischengeparkt)

23 Lernspiele für Kinder: 11 fürs kleine Einmaleins (Ida), 12 für Plus und Minus bis 20 (Theo).
Reines HTML/CSS/JavaScript, ohne Server und ohne Abhängigkeiten. Hat mit der Flutter-App in diesem
Repository nichts zu tun und liegt hier nur zur Aufbewahrung.

| Ordner | Inhalt |
| --- | --- |
| `website/` | Fertig gebaute Website – `index.html` öffnen oder den Ordner bei einem Static-Hoster hochladen (z. B. Netlify Drop). Siehe `website/LIESMICH.txt`. |
| `build/` | Quellen: Kometen-Engine (`engine.html` + Themen `tiefsee`, `burg`, `pixel`, `sterne`), Spiele-Baukasten (`kit/kit.html` + `kit/games/`), Übersichtsseiten (`hub-*.html`, `hub.css`, `hub-widgets.js`) und `build.py`. |
| `spiele/` | Einzelspiele mit eigenem Code (Mathe Fuchs, Monster-Mampf, Turbo-Schnecke, Pizza Mamma Mia, Neon Math Defender); dient beim Bauen auch als Zwischenablage für die Engine-Spiele. |
| `tests/` | Automatische Browser-Tests (Playwright). Pfade darin vor dem Ausführen anpassen. |

## Neu bauen

```bash
cd mathe-spiele/build
python3 build.py      # erzeugt mathe-spiele/1x1-spiele/
```

Der Ordner `1x1-spiele/` ist das Build-Ergebnis (in `.gitignore`); `website/` ist der zuletzt gebaute Stand.
