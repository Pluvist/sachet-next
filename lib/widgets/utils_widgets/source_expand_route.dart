// HyperCeiler source-view capture/foreground expansion adaptation, AGPL-3.0.
// Copyright (C) 2023-2026 HyperCeiler Contributions; adaptation Pluvist.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures only the visible icon, rather than its padded tap target or card.
class ExpansionAnchor extends StatefulWidget {
  const ExpansionAnchor({super.key, required this.child});
  final Widget child;
  @override
  State<ExpansionAnchor> createState() => _ExpansionAnchorState();
}

class _ExpansionAnchorState extends State<ExpansionAnchor> {
  final boundaryKey = GlobalKey();
  bool hidden = false;
  void hide() {
    if (mounted) setState(() => hidden = true);
  }

  void restore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => hidden = false);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => Opacity(
      opacity: hidden ? 0 : 1,
      child: _IconSnapshotBoundary(key: boundaryKey, child: widget.child));
}

/// Keep access to the last committed layer inside its render object, so an ink
/// repaint requested by the tap does not force a second frame before opening.
class _IconSnapshotBoundary extends SingleChildRenderObjectWidget {
  const _IconSnapshotBoundary({super.key, required super.child});
  @override
  _IconSnapshotRenderBox createRenderObject(BuildContext context) =>
      _IconSnapshotRenderBox();
}

class _IconSnapshotRenderBox extends RenderRepaintBoundary {
  ui.Image? captureLastPaint(double pixelRatio) {
    final painted = layer;
    if (painted is! OffsetLayer || !hasSize) return null;
    return painted.toImageSync(Offset.zero & size, pixelRatio: pixelRatio);
  }
}

/// The target keeps its full-screen layout throughout. Only its reveal mask
/// expands from the original icon edge; text is never squeezed into the icon.
/// HyperCeiler delegates this to fan.transition.ActivityOptionsHelper (102).
/// Flutter cannot execute that system Activity animation; this implements the
/// source bitmap, foreground expansion and destination reveal within one route.
class SourceExpandRoute<T> extends PageRouteBuilder<T> {
  SourceExpandRoute({
    required WidgetBuilder builder,
    required Rect source,
    required bool reduceMotion,
    double? sourceRadius,
    Color? sourceColor,
    ui.Image? sourceImage,
    VoidCallback? restoreSource,
    super.settings,
  })  : _sourceImage = sourceImage,
        _restoreSource = restoreSource,
        super(
            opaque: true,
            transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 500),
            reverseTransitionDuration:
                Duration(milliseconds: reduceMotion ? 0 : 350),
            pageBuilder: (context, animation, secondary) => builder(context),
            transitionsBuilder: (context, animation, secondary, child) {
              final size = MediaQuery.sizeOf(context);
              final t = Curves.easeOutCubic.transform(animation.value);
              final color = Theme.of(context).scaffoldBackgroundColor;
              return IgnorePointer(
                ignoring: animation.status != AnimationStatus.completed,
                child: ClipPath(
                  key: const ValueKey('sourceExpansionMask'),
                  clipper: IconExpansionClipper(
                    source: source,
                    sourceRadius: sourceRadius ?? source.shortestSide / 2,
                    progress: t,
                  ),
                  child: Stack(fit: StackFit.expand, children: [
                    Opacity(
                        opacity:
                            sourceImage == null ? 1 : (t / .15).clamp(0.0, 1.0),
                        child: ColoredBox(
                            color: Color.lerp(sourceColor ?? color, color,
                                (t / .55).clamp(0.0, 1.0))!)),
                    Opacity(
                        opacity: ((t - .12) / .66).clamp(0.0, 1.0),
                        child: RepaintBoundary(child: child)),
                    if (sourceImage != null && t < .5)
                      Positioned.fromRect(
                          rect: IconExpansionClipper.bounds(source, size, t),
                          child: Opacity(
                              opacity: (1 - t / .5).clamp(0.0, 1.0),
                              child: RawImage(
                                  image: sourceImage, fit: BoxFit.fill))),
                  ]),
                ),
              );
            });
  final ui.Image? _sourceImage;
  final VoidCallback? _restoreSource;
  // ModalRoute.animation temporarily reports completed during the offstage
  // measurement pass. External handoff must watch the real controller instead.
  Animation<double> get expansionAnimation => controller!;
  @override
  void dispose() {
    _sourceImage?.dispose();
    _restoreSource?.call();
    super.dispose();
  }
}

/// Circle/rounded icon edges grow around their original center until they pass
/// the furthest screen corner. The reveal never moves to the screen center.
class IconExpansionClipper extends CustomClipper<Path> {
  const IconExpansionClipper(
      {required this.source,
      required this.sourceRadius,
      required this.progress});
  final Rect source;
  final double sourceRadius, progress;
  static double coveringRadius(Rect source, Size size) =>
      [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ].map((corner) => (corner - source.center).distance).reduce(math.max) +
      1;
  static Rect bounds(Rect source, Size size, double progress) {
    final r = coveringRadius(source, size);
    return Rect.lerp(
        source, Rect.fromCircle(center: source.center, radius: r), progress)!;
  }

  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final r = ui.lerpDouble(sourceRadius.clamp(0, source.shortestSide / 2),
        coveringRadius(source, size), progress)!;
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          bounds(source, size, progress), Radius.circular(r)));
  }

  @override
  bool shouldReclip(IconExpansionClipper oldClipper) =>
      source != oldClipper.source ||
      sourceRadius != oldClipper.sourceRadius ||
      progress != oldClipper.progress;
}

Rect expansionSource(BuildContext context) {
  final render = context.findRenderObject();
  final overlay = Navigator.of(context).overlay?.context.findRenderObject();
  if (render is RenderBox && render.hasSize) {
    return MatrixUtils.transformRect(
        render.getTransformTo(overlay), Offset.zero & render.size);
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
      center: size.center(Offset.zero), width: 70, height: 70);
}

final _opening = <NavigatorState>{};
Future<SourceExpandRoute<T>?> _captureRoute<T>(BuildContext context,
    Widget page, GlobalKey? sourceKey, double? radius, Color? color) async {
  final navigator = Navigator.of(context);
  if (!_opening.add(navigator)) return null;
  try {
    final origin = sourceKey?.currentContext ?? context;
    final source = expansionSource(origin);
    final reduce = MediaQuery.disableAnimationsOf(context);
    ui.Image? image;
    final anchor = sourceKey?.currentState;
    final anchorState = anchor is _ExpansionAnchorState ? anchor : null;
    if (!reduce && sourceKey != null) {
      final boundary =
          anchorState?.boundaryKey.currentContext?.findRenderObject() ??
              origin.findRenderObject();
      // InkWell can dirty its boundary on pointer-up. Capture the last painted
      // layer (the original icon), without waiting for a splash/repaint frame.
      if (boundary is _IconSnapshotRenderBox) {
        try {
          image = boundary.captureLastPaint(
              MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0));
        } catch (_) {
          // A missing snapshot must never prevent navigation.
        }
      }
    }
    if (!context.mounted || !navigator.mounted) {
      image?.dispose();
      return null;
    }
    anchorState?.hide();
    return SourceExpandRoute<T>(
        restoreSource: anchorState?.restore,
        builder: (_) => page,
        source: source,
        sourceRadius: radius,
        sourceColor: color,
        sourceImage: image,
        reduceMotion: reduce);
  } finally {
    _opening.remove(navigator);
  }
}

Future<T?> expandPage<T>(BuildContext context, Widget page,
    {GlobalKey? sourceKey, double? sourceRadius, Color? sourceColor}) async {
  final route = await _captureRoute<T>(
      context, page, sourceKey, sourceRadius, sourceColor);
  if (route == null || !context.mounted) return null;
  return Navigator.of(context).push<T>(route);
}

/// External links hand off after the reveal actually completes. Back/cancel
/// never opens the link, and exceptions cannot leave a blank overlay behind.
Future<void> expandAction(BuildContext context, VoidCallback action,
    {GlobalKey? sourceKey, double? sourceRadius, Color? sourceColor}) async {
  final route = await _captureRoute<void>(
      context,
      ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
      sourceKey,
      sourceRadius,
      sourceColor);
  if (route == null || !context.mounted) return;
  final navigator = Navigator.of(context);
  final finished = Completer<bool>();
  void status(AnimationStatus status) {
    if (finished.isCompleted) return;
    if (status == AnimationStatus.completed) finished.complete(true);
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) finished.complete(false);
  }

  navigator.push(route).then((_) {
    if (!finished.isCompleted) finished.complete(false);
  });
  final animation = route.expansionAnimation;
  animation.addStatusListener(status);
  status(animation.status);
  final completed = await finished.future;
  animation.removeStatusListener(status);
  if (!completed || !context.mounted || !route.isCurrent) return;
  try {
    action();
  } finally {
    navigator.removeRoute(route);
  }
}

class HomeEntrance extends StatelessWidget {
  const HomeEntrance(
      {super.key,
      required this.animation,
      required this.index,
      required this.child});
  final Animation<double> animation;
  final int index;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final start = (index * .035).clamp(0.0, .5);
        final t = Curves.easeOutCubic.transform(
            ((animation.value - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 90 * (1 - t)),
                child: Transform.scale(scale: .92 + .08 * t, child: child)));
      });
}
