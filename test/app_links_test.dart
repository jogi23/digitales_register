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

import 'package:dr/app_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the Tally links tell the apps apart', () {
    expect(AppLinks.suggestFeature.queryParameters['app'], 'digiregst');
    expect(AppLinks.reportBug.queryParameters['app'], 'digiregst');
  });

  test('the feedback mail carries the version in its subject', () {
    final mail = AppLinks.feedbackMail('1.6.0');
    expect(mail.scheme, 'mailto');
    expect(mail.path, 'hallo@wertwerk.io');
    expect(mail.queryParameters['subject'], 'Feedback DigiReg ST 1.6.0');
  });

  test('every web link is https', () {
    for (final uri in [
      AppLinks.developer,
      AppLinks.faq,
      AppLinks.privacy,
      AppLinks.imprint,
      AppLinks.terms,
      AppLinks.otherApps,
      AppLinks.suggestFeature,
      AppLinks.reportBug,
      AppLinks.source,
      AppLinks.playStore,
    ]) {
      expect(uri.scheme, 'https', reason: '$uri');
    }
  });

  test('the legal pages live under wertwerk.io', () {
    expect(AppLinks.imprint.toString(), 'https://wertwerk.io/impressum');
    expect(AppLinks.terms.toString(),
        'https://wertwerk.io/nutzungsbedingungen/digiregst');
    expect(AppLinks.privacy.toString(),
        'https://wertwerk.io/datenschutz/digiregst');
  });
}
