import pathlib
here = pathlib.Path(__file__).parent
out = here.parent / 'spiele'
engine = (here / 'engine.html').read_text()
themes = [
  dict(key='tiefsee', file='Ida - Tiefsee-Alarm.html', PAGE_TITLE='Tiefsee-Alarm', THEME_COLOR='#021626',
       FONTS='https://fonts.googleapis.com/css2?family=Baloo+2:wght@600;700;800&display=swap', EMBLEM='🪼',
       TITLE_HTML='TIEFSEE-<br><em>ALARM</em>',
       SUBTITLE='Quallen sinken auf das Korallenriff! Löse die Aufgabe auf der <b>markierten</b> Qualle<br>und tippe auf das richtige Ergebnis – dein U-Boot pustet sie mit einer Blase weg.',
       START='ABTAUCHEN!', NEXT='WEITER TAUCHEN', RESTART='NOCHMAL TAUCHEN', OVER='DAS RIFF IST VOLL!', CANCEL='TAUCHGANG ABBRECHEN'),
  dict(key='burg', file='Ida - Zauberburg.html', PAGE_TITLE='Zauberburg', THEME_COLOR='#07051a',
       FONTS='https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700;900&family=Cinzel:wght@700&family=Nunito:wght@800;900&display=swap', EMBLEM='🏰',
       TITLE_HTML='ZAUBER<em>BURG</em>',
       SUBTITLE='Der Drache spuckt Feuerbälle auf die Burg! Löse die Aufgabe auf dem <b>markierten</b> Feuerball<br>und wähle das Ergebnis – dein Eiszauber löscht ihn.',
       START='ZAUBER WIRKEN', NEXT='NÄCHSTER ANGRIFF', RESTART='NOCHMAL VERTEIDIGEN', OVER='DIE BURG BRENNT!', CANCEL='VERTEIDIGUNG ABBRECHEN'),
  dict(key='pixel', file='Ida - Pixel-Invasion.html', PAGE_TITLE='Pixel-Invasion', THEME_COLOR='#000000',
       FONTS='https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap', EMBLEM='👾',
       TITLE_HTML='PIXEL-<br><em>INVASION</em>',
       SUBTITLE='Die Aliens landen! Löse die Aufgabe beim <b>markierten</b> Alien<br>und wähle das Ergebnis – deine Kanone fährt hin und schießt.',
       START='PRESS START', NEXT='NÄCHSTES LEVEL', RESTART='NOCHMAL', OVER='GAME OVER', CANCEL='SPIEL ABBRECHEN'),
  dict(key='sterne', file='Ida - Sternenfänger.html', PAGE_TITLE='Sternenfänger', THEME_COLOR='#1a1546',
       FONTS='https://fonts.googleapis.com/css2?family=Fredoka:wght@500;600;700&display=swap', EMBLEM='🌟',
       TITLE_HTML='STERNEN-<br><em>FÄNGER</em>',
       SUBTITLE='Sternschnuppen fallen vom Himmel! Rechne die Aufgabe beim <b>leuchtenden</b> Stern<br>und tippe auf das Ergebnis – dann fängst du ihn mit deinem Zauberglas ein. ✨',
       START='STERNE SAMMELN', NEXT='NÄCHSTE NACHT', RESTART='NOCHMAL SAMMELN', OVER='GUTE NACHT, STERNE!', CANCEL='SAMMELN BEENDEN'),
]
for t in themes:
    html = engine.replace('/*THEME_CSS*/', (here / f"{t['key']}.css").read_text()).replace('/*THEME_JS*/', (here / f"{t['key']}.js").read_text())
    for k, v in t.items():
        html = html.replace('{{' + k + '}}', v)
    assert '{{' not in html, [l for l in html.splitlines() if '{{' in l]
    (out / t['file']).write_text(html)
    print('wrote', t['file'], len(html))

# ---- Spiele aus dem Baukasten ----
kit = (here / 'kit' / 'kit.html').read_text()
KIT_GAMES = [
  # (Datei-Kürzel, Titel, Zielname, Themenfarbe, Bereich)
  ('huehner', 'Hühner-Chaos', 'huehner-chaos.html', '#e8573c', '1x1'),
  ('rakete', 'Raketen-Werkstatt', 'raketen-werkstatt.html', '#1b1a4a', '1x1'),
  ('zauber', 'Zaubertrank-Küche', 'zaubertrank-kueche.html', '#2a1b4d', '1x1'),
  ('hunde', 'Hunde-Frisör', 'hunde-frisoer.html', '#ff4f9a', '1x1'),
  ('ninja', 'Ninja-Sprung', 'ninja-sprung.html', '#0f1430', '1x1'),
  ('dino', 'Dino-Eier', 'dino-eier.html', '#2e9b4c', '20'),
  ('zug', 'Zahlen-Zug', 'zahlen-zug.html', '#e53935', '20'),
  ('zirkus', 'Zirkus-Kanone', 'zirkus-kanone.html', '#e53935', '20'),
  ('geister', 'Geisterhaus-Türen', 'geisterhaus-tueren.html', '#2b1d44', '20'),
  ('frosch', 'Frosch-Fliegen-Fangen', 'frosch-fliegen.html', '#2e9b4c', '20'),
]
kit_out = {}
for key, title, fname, color, area in KIT_GAMES:
    h = kit.replace('/*GAME_CSS*/', (here / 'kit' / 'games' / f'{key}.css').read_text()).replace('/*GAME_JS*/', (here / 'kit' / 'games' / f'{key}.js').read_text())
    h = h.replace('{{TITLE}}', title).replace('{{THEME_COLOR}}', color).replace('{{HUB}}', 'einmaleins.html' if area == '1x1' else 'zahlenraum-20.html')
    assert '{{' not in h
    kit_out[fname] = h

# ---- Sammelordner mit Übersichtsseiten ----
import shutil
col = here.parent / '1x1-spiele'
if col.exists(): shutil.rmtree(col)
col.mkdir()
names = {
  'Ida - Neon Math Defender.html': 'neon-math-defender.html',
  'Ida - Tiefsee-Alarm.html': 'tiefsee-alarm.html',
  'Ida - Zauberburg.html': 'zauberburg.html',
  'Ida - Pixel-Invasion.html': 'pixel-invasion.html',
  'Ida - Sternenfänger.html': 'sternenfaenger.html',
  'Ida - Pizza Mamma Mia.html': 'pizza-mamma-mia.html',
  'Theo - Monster-Mampf.html': 'monster-mampf.html',
  'Theo - Turbo-Schnecke.html': 'turbo-schnecke.html',
}
for src, dst in names.items():
    shutil.copy(out / src, col / dst)
for fname, h in kit_out.items():
    (col / fname).write_text(h)

# Mathe Fuchs: jedes Mini-Spiel als eigene Datei
fuchs = (out / 'Theo - Mathe Fuchs.html').read_text()
for mode, fname, title in [('verliebte', 'ballon-jagd.html', 'Ballon-Jagd'), ('zerlegen', 'affen-fuettern.html', 'Affen füttern'),
                           ('addsub', 'frosch-huepfen.html', 'Frosch hüpfen'), ('pyramid', 'baustelle.html', 'Baustelle'), ('mix', 'zufalls-mix.html', 'Zufalls-Mix')]:
    h = fuchs.replace('<title>Mathe Fuchs</title>', f'<title>{title}</title>', 1)
    marker = "<script>\n(() => {\n  'use strict';\n  const ONLY"
    assert marker in h
    h = h.replace(marker, f"<script>window.MF_ONLY = '{mode}';</script>\n" + marker, 1)
    (col / fname).write_text(h)

# Übersichtsseiten
css = (here / 'hub.css').read_text()
widgets = (here / 'hub-widgets.js').read_text()
FONTS = '<link rel="preconnect" href="https://fonts.googleapis.com">\n<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>\n<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Lilita+One&family=Nunito:wght@600;800;900&display=swap">\n'
def page(title, content_file):
    return f'<title>{title}</title>\n{FONTS}<style>\n{css}</style>\n' + (here / content_file).read_text() + f'\n<script>\n{widgets}</script>\n'
def full(inner, body_class=''):
    return ('<!DOCTYPE html>\n<html lang="de">\n<head>\n<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">\n</head>\n'
            f'<body{(" class=" + chr(34) + body_class + chr(34)) if body_class else ""}>\n' + inner + '</body>\n</html>\n')
index = page('Theos und Idas Mathe-Spiele', 'hub-index.html')
(here / 'hub.html').write_text(index)       # Hauptseite für die Veröffentlichung (ohne Gerüst)
(col / 'index.html').write_text(full(index))
(col / 'einmaleins.html').write_text(full(page('Das kleine 1×1', 'hub-1x1.html')))
day = page('Zahlenraum bis 20', 'hub-20.html')
(col / 'zahlenraum-20.html').write_text(full(day, 'day'))
print('collection ->', col, sorted(x.name for x in col.iterdir()))
