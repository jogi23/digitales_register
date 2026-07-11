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

import 'package:dr/ui/changelog_page.dart';
import 'package:dr/util.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void showAppAboutDialog(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationIcon: SizedBox(
      width: 100,
      child: Image.asset("assets/index.png"),
    ),
    applicationLegalese:
        "Copyright Johannes Feichter 2026\n                 Michael Debertol und Simon Wachtler 2019-2022",
    applicationName: "DigiReg ST",
    applicationVersion: appVersion,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () {
            final navigator = Navigator.of(context, rootNavigator: true);
            navigator.pop();
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const ChangelogPage(),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("What's new"),
              SizedBox(width: 8),
              Icon(Icons.new_releases_outlined),
            ],
          ),
        ),
      ),
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: "Ein Client für das "),
          TextSpan(
            text: "Digitale Register",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://www.digitalesregister.it/"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: "."),
        ]),
      ),
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: "Entwickelt von "),
          TextSpan(
            text: "Johannes Feichter",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://wertwerk.io"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: ", "),
          TextSpan(
            text: "Michael Debertol",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://blog.debertol.com"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
          const TextSpan(text: " and "),
          TextSpan(
            text: "Simon Wachtler",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                launchUrl(
                  Uri.parse("https://www.evvvolution.com/team/simon-wachtler"),
                  mode: LaunchMode.externalApplication,
                );
              },
          ),
        ]),
      ),
      const SizedBox(
        height: 8,
      ),
      const Text(
        "This is free software, and you are welcome to redistribute it under certain conditions.\n"
        "This program comes with ABSOLUTELY NO WARRANTY.",
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          child: Text(
            "See the GNU General Public License for more details.",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          onTap: () {
            launchUrl(
              Uri.parse("https://www.gnu.org/licenses/gpl-3.0.html"),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          child: Text(
            "Datenschutzerklärung",
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          onTap: () {
            launchUrl(
              Uri.parse("https://wertwerk.io/datenschutz/digiregst"),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ),
    ],
  );
}
