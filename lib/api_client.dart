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

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dr/util.dart';

/// Low-level HTTP client. No authentication logic — that lives in [AuthService].
class ApiClient {
  final cookieJar = DefaultCookieJar();
  final Dio dio = Dio();
  String? url;

  String get baseAddress => "$url/v2/";
  String get loginAddress => "${baseAddress}api/auth/login";

  ApiClient() {
    dio.interceptors.add(CookieManager(cookieJar));
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.userAgent =
          "DigiRegST $appVersion; https://github.com/jogi23/digitales_register";
      return null;
    };
  }

  void clearCookies() {
    cookieJar.deleteAll();
  }
}
