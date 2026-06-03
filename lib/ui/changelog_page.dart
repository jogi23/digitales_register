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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;

Future<String> _fetchChangelog() async {
  final response = await http.get(
    Uri.parse(
        'https://api.github.com/repos/jogi23/digitales_register/releases'),
    headers: {'Accept': 'application/vnd.github+json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load releases: ${response.statusCode}');
  }
  final releases = jsonDecode(response.body) as List<dynamic>;
  return releases.map((r) {
    final version = (r['tag_name'] as String).replaceFirst('v', '');
    final body = (r['body'] as String? ?? '').trim();
    return '## $version\n\n$body';
  }).join('\n\n');
}

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("What's new")),
      body: FutureBuilder<String>(
        future: _fetchChangelog(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Keine Verbindung'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(data: snapshot.data!);
        },
      ),
    );
  }
}
