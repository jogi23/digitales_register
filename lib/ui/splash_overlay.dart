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

import 'dart:io';

import 'package:flutter/material.dart';

class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _fadeOutController;
  late final AnimationController _textController;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  bool _visible = true;

  static const _textDelay = Duration(milliseconds: 600);
  static const _textFadeDuration = Duration(milliseconds: 2000);
  static const _displayDuration = Duration(milliseconds: 3200);
  static const _fadeOutDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();

    _fadeOutController =
        AnimationController(vsync: this, duration: _fadeOutDuration);

    _textController =
        AnimationController(vsync: this, duration: _textFadeDuration);
    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    Future.delayed(_textDelay, () {
      if (mounted) _textController.forward();
    });

    Future.delayed(_displayDuration, () {
      if (!mounted) return;
      _fadeOutController.forward().whenComplete(() {
        if (mounted) setState(() => _visible = false);
      });
    });
  }

  @override
  void dispose() {
    _fadeOutController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible ||
        Platform.isWindows ||
        Platform.isLinux ||
        Platform.isMacOS) {
      return const SizedBox.shrink();
    }
    return FadeTransition(
      opacity: ReverseAnimation(
        CurvedAnimation(parent: _fadeOutController, curve: Curves.easeOut),
      ),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          children: [
            // Logo zentriert; 1.13× Zoom clippt den äußeren Teal-Rand weg.
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: ClipOval(
                  child: Transform.scale(
                    scale: 1.13,
                    child: const Image(
                      image: AssetImage('assets/icon_foreground.png'),
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            // Text blendet sich langsam unterhalb des Logos ein.
            Align(
              alignment: const Alignment(0, 0.5),
              child: SlideTransition(
                position: _textSlide,
                child: FadeTransition(
                  opacity: _textOpacity,
                  child: const Text(
                    'DigiReg ST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFE8C87A),
                      fontSize: 31,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
