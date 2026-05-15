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

import 'package:dr/middleware/middleware.dart' show wrapper;
import 'package:dr/providers/no_internet_provider.dart';
import 'package:dr/utc_date_time.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CertificateState {
  final String? html;
  final UtcDateTime? lastFetched;

  const CertificateState({this.html, this.lastFetched});

  CertificateState copyWith({String? html, UtcDateTime? lastFetched}) =>
      CertificateState(
        html: html ?? this.html,
        lastFetched: lastFetched ?? this.lastFetched,
      );
}

class CertificateNotifier extends Notifier<CertificateState> {
  @override
  CertificateState build() => const CertificateState();

  void reset() => state = const CertificateState();

  Future<void> load() async {
    if (ref.read(noInternetProvider)) return;
    final dynamic response =
        await wrapper.send("student/certificate", method: "GET");
    if (response is String) {
      state = state.copyWith(
        html: response,
        lastFetched: UtcDateTime.now(),
      );
    }
  }
}

final certificateProvider =
    NotifierProvider<CertificateNotifier, CertificateState>(
  CertificateNotifier.new,
);
