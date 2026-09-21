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

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dr/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Side of the picture this page hands back, in pixels.
///
/// An avatar is never shown larger than a few dozen points; anything beyond
/// this only fills the device up.
const _outputSize = 512;

/// How far the picture may be zoomed in.
const _maxScale = 6.0;

/// The square of the source picture that the crop window shows.
///
/// [imageSize] is the picture in its own pixels, [window] the side of the
/// square window it is cut to, [baseScale] how far the picture had to be
/// scaled up (or down) to cover that window, and [scale] together with
/// [offset] the zoom and the pan on top of it — what `InteractiveViewer`
/// keeps in its transform.
///
/// A viewport point `v` shows the child point `(v - offset) / scale`, and the
/// child is the picture at [baseScale]; so the window starts at
/// `-offset / (baseScale * scale)` source pixels and is that much narrower
/// than the window itself.
@visibleForTesting
Rect visibleSourceRect({
  required Size imageSize,
  required double window,
  required double baseScale,
  required double scale,
  required Offset offset,
}) {
  final factor = baseScale * scale;
  // Covering means the window is never wider than the picture, but a picture
  // of zero size and a scale of zero both have to stay out of the division.
  final side = factor <= 0
      ? min(imageSize.width, imageSize.height)
      : min(window / factor, min(imageSize.width, imageSize.height));
  double clamp(double value, double limit) => min(max(value, 0), max(limit, 0));
  return Rect.fromLTWH(
    clamp(factor <= 0 ? 0 : -offset.dx / factor, imageSize.width - side),
    clamp(factor <= 0 ? 0 : -offset.dy / factor, imageSize.height - side),
    side,
    side,
  );
}

/// The size the picture takes when it covers a square window of [window].
@visibleForTesting
Size coveredSize(Size imageSize, double window) {
  final scale = coverScale(imageSize, window);
  return Size(imageSize.width * scale, imageSize.height * scale);
}

/// How far the picture has to be scaled to cover a square window of [window].
@visibleForTesting
double coverScale(Size imageSize, double window) {
  if (imageSize.width <= 0 || imageSize.height <= 0) return 1;
  return max(window / imageSize.width, window / imageSize.height);
}

/// Lets the reader pick the part of a picture that becomes the account photo.
///
/// The picture covers a square window, which can be dragged and zoomed; what
/// the window holds when „Übernehmen“ is tapped comes back as the PNG bytes
/// of a square image. Picking the section in the app rather than handing the
/// whole picture over keeps it independent of what the gallery of the day
/// offers (#263).
class PhotoCropPage extends StatefulWidget {
  /// The picture to cut a square out of.
  final File source;

  const PhotoCropPage({super.key, required this.source});

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  final _controller = TransformationController();

  ui.Image? _image;
  bool _failed = false;
  bool _saving = false;

  /// Side of the crop window and how far the picture covers it — both come
  /// from the layout, and the cut needs them again.
  double? _window;
  double _baseScale = 1;

  /// The window the picture was last centred in, so it is centred once per
  /// size rather than on every build.
  double? _centredFor;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final image = await decodeImageFromList(await widget.source.readAsBytes());
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Starts on the middle of the picture rather than on its top left corner.
  ///
  /// After the frame: setting the transform during a build would notify the
  /// viewer while it is building itself.
  void _centre(double window, Size covered) {
    if (_centredFor == window) return;
    _centredFor = window;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.value = Matrix4.translationValues(
        -(covered.width - window) / 2,
        -(covered.height - window) / 2,
        0,
      );
    });
  }

  Future<void> _save() async {
    final image = _image;
    final window = _window;
    if (image == null || window == null || _saving) return;
    setState(() => _saving = true);
    final matrix = _controller.value;
    final translation = matrix.getTranslation();
    final bytes = await _render(
      image,
      visibleSourceRect(
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        window: window,
        baseScale: _baseScale,
        scale: matrix.getMaxScaleOnAxis(),
        offset: Offset(translation.x, translation.y),
      ),
    );
    if (!mounted) return;
    if (bytes == null) {
      setState(() {
        _saving = false;
        _failed = true;
      });
      return;
    }
    Navigator.of(context).pop(bytes);
  }

  /// Draws [source] of the picture into a square image and encodes it.
  Future<Uint8List?> _render(ui.Image image, Rect source) async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      source,
      Rect.fromLTWH(0, 0, _outputSize.toDouble(), _outputSize.toDouble()),
      Paint()..filterQuality = FilterQuality.high,
    );
    final picture = recorder.endRecording();
    ui.Image? cropped;
    try {
      cropped = await picture.toImage(_outputSize, _outputSize);
      final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    } finally {
      picture.dispose();
      cropped?.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tr(context).photoCropTitle),
        actions: <Widget>[
          TextButton(
            onPressed: image == null || _saving ? null : _save,
            child: Text(tr(context).photoCropApply),
          ),
        ],
      ),
      body: _failed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  tr(context).photoCropFailed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          : image == null
              ? const Center(child: CircularProgressIndicator())
              : _editor(context, image),
    );
  }

  Widget _editor(BuildContext context, ui.Image image) {
    final size = Size(image.width.toDouble(), image.height.toDouble());
    return Column(
      children: <Widget>[
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final window = min(constraints.maxWidth, constraints.maxHeight);
                final covered = coveredSize(size, window);
                _window = window;
                _baseScale = coverScale(size, window);
                _centre(window, covered);
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ClipRect(
                      child: SizedBox.square(
                        dimension: window,
                        child: InteractiveViewer(
                          transformationController: _controller,
                          // The picture is laid out at the size that covers
                          // the window, so it can be pushed along its longer
                          // side instead of being cut off there for good.
                          constrained: false,
                          minScale: 1,
                          maxScale: _maxScale,
                          child: SizedBox(
                            width: covered.width,
                            height: covered.height,
                            child: Image.file(
                              widget.source,
                              width: covered.width,
                              height: covered.height,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Says what the picture will look like as an avatar; the
                    // saved image itself stays square.
                    IgnorePointer(
                      child: SizedBox.square(
                        dimension: window,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white70, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            tr(context).photoCropHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        if (_saving) const LinearProgressIndicator(),
      ],
    );
  }
}
