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

/// Play Store id of the released app.
///
/// Written out rather than read from package_info: debug builds carry the
/// `.debug` suffix and would point at a listing that does not exist.
const playStorePackage = "io.wertwerk.digitalesregister";

/// Contact and web addresses of the app – the only place they are defined.
abstract final class AppLinks {
  static const contactEmail = 'hallo@wertwerk.io';
  static const developerName = 'Johannes Feichter';
  static final developer = Uri.parse('https://wertwerk.io');

  /// Everyone who wrote the app, with their page; the maintainer first.
  static final developers = <(String, Uri)>[
    (developerName, developer),
    ('Michael Debertol', Uri.parse('https://blog.debertol.com')),
    (
      'Simon Wachtler',
      Uri.parse('https://www.evvvolution.com/team/simon-wachtler'),
    ),
  ];

  static final faq =
      Uri.parse('https://wertwerk.io/projekte/digitale-register-app/#faq');
  static final privacy = Uri.parse('https://wertwerk.io/datenschutz/digiregst');
  static final imprint = Uri.parse('https://wertwerk.io/impressum');
  static final terms =
      Uri.parse('https://wertwerk.io/nutzungsbedingungen/digiregst');

  /// Studio name as on Google Play; its developer page lists all apps.
  static const studioName = 'WertWerk';
  static final otherApps = Uri.parse(
    'https://play.google.com/store/apps/developer?id=$studioName',
  );
  static final suggestFeature =
      Uri.parse('https://tally.so/r/Y5xKgv?app=digiregst');
  static final reportBug = Uri.parse('https://tally.so/r/yPdpP6?app=digiregst');
  static final dontKillMyApp = Uri.parse('https://dontkillmyapp.com');
  static final source =
      Uri.parse('https://github.com/jogi23/digitales_register');
  static final playStore = Uri.parse(
    'https://play.google.com/store/apps/details?id=$playStorePackage',
  );

  /// Pre-filled feedback mail; the version helps answering bug reports.
  static Uri feedbackMail(String version) => Uri(
        scheme: 'mailto',
        path: contactEmail,
        queryParameters: {'subject': 'Feedback DigiReg ST $version'},
      );
}
