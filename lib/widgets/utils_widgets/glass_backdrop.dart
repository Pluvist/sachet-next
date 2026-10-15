import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/idle_frame_work.dart';
import 'package:flutter/rendering.dart';

class GlassBackdrop {
  static final key = GlobalKey();
  static final image = ValueNotifier<ui.Image?>(null);
  static bool _busy = false;
  static bool _queued = false;
  static final _idleCapture = IdleFrameWork();
  static int _captureRevision = 0;

  /// Coalesce updates and let input/selection animations finish before readback.
  static void captureWhenIdle() {
    _captureRevision++;
    if (_queued) return;
    _queued = true;
    _idleCapture.schedule(() async {
      final revision = _captureRevision;
      try {
        await capture();
      } finally {
        _queued = false;
        if (_captureRevision != revision) captureWhenIdle();
      }
    });
  }

  static Offset origin = Offset.zero;
  // Page-only snapshots exclude navigation and menus, preventing feedback.
  static Future<void> capture() async {
    if (_busy) return;
    final boundary = key.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary ||
        !boundary.attached ||
        boundary.debugNeedsPaint) return;
    _busy = true;
    try {
      origin = boundary.localToGlobal(Offset.zero);
      final next = await boundary.toImage(pixelRatio: 1);
      final old = image.value;
      image.value = next;
      WidgetsBinding.instance.addPostFrameCallback((_) => old?.dispose());
    } catch (_) {
      /* Renderers without snapshot support retain background blur. */
    } finally {
      _busy = false;
    }
  }
}
