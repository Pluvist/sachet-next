import 'package:sachet/utils/miuix_shapes.dart';
// HyperCeiler source-view capture/foreground expansion adaptation, AGPL-3.0.
// Copyright (C) 2023-2026 HyperCeiler Contributions; adaptation Pluvist.
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures the visible boundary of the entire pressed control.
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
/// expands from the original control edge; text is never squeezed into the icon.
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
    VoidCallback? onExpanded,
    this.homeHandoff = false,
    super.settings,
  })  : _sourceImage = sourceImage,
        _restoreSource = restoreSource,
        _onExpanded = onExpanded,
        super(
            opaque: true,
            transitionDuration: Duration(
                milliseconds: reduceMotion
                    ? 0
                    : homeHandoff
                        ? 600
                        : 400),
            reverseTransitionDuration:
                Duration(milliseconds: reduceMotion ? 0 : 280),
            pageBuilder: (context, animation, secondary) => builder(context),
            transitionsBuilder: (context, animation, secondary, child) {
              final size = MediaQuery.sizeOf(context);
              final progress = animation.value;
              final t = const Cubic(.2, .8, .2, 1).transform(progress);
              final color = Theme.of(context).scaffoldBackgroundColor;
              return IgnorePointer(
                ignoring: animation.status != AnimationStatus.completed,
                child: ClipPath(
                  key: const ValueKey('sourceExpansionMask'),
                  clipper: ControlExpansionClipper(
                    source: source,
                    sourceRadius: sourceRadius ?? MiuixRadii.control,
                    progress: t,
                  ),
                  child: Stack(fit: StackFit.expand, children: [
                    Opacity(
                        opacity: sourceImage == null
                            ? 1
                            : (progress / .12).clamp(0.0, 1.0),
                        child: ColoredBox(
                            color: Color.lerp(sourceColor ?? color, color,
                                ((progress - .25) / .75).clamp(0.0, 1.0))!)),
                    Opacity(
                        opacity: Curves.easeOut.transform(
                            ((progress - .10) / .75).clamp(0.0, 1.0)),
                        child: RepaintBoundary(child: child)),
                    if (sourceImage != null && progress < .22)
                      Positioned.fromRect(
                          rect: Rect.fromCenter(
                              center: ControlExpansionClipper.bounds(
                                      source, size, t)
                                  .center,
                              width: source.width,
                              height: source.height),
                          child: Opacity(
                              opacity: (1 - progress / .22).clamp(0.0, 1.0),
                              child: RawImage(
                                  image: sourceImage, fit: BoxFit.fill))),
                  ]),
                ),
              );
            });
  final ui.Image? _sourceImage;
  final VoidCallback? _restoreSource;
  final VoidCallback? _onExpanded;
  final bool homeHandoff;
  @override
  RoutePopDisposition get popDisposition =>
      homeHandoff && controller?.status != AnimationStatus.completed
          ? RoutePopDisposition.doNotPop
          : super.popDisposition;
  @override
  TickerFuture didPush() {
    final entering = super.didPush();
    if (_onExpanded == null) return entering;
    entering.whenCompleteOrCancel(() {
      if (controller?.status != AnimationStatus.completed || !isCurrent) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isCurrent) _onExpanded();
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    return entering;
  }

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

/// A bounded rounded rectangle avoids the old oversized circular mask. Every
/// edge begins exactly at the control and reaches its corresponding screen edge.
class ControlExpansionClipper extends CustomClipper<Path> {
  const ControlExpansionClipper(
      {required this.source,
      required this.sourceRadius,
      required this.progress});
  final Rect source;
  final double sourceRadius, progress;
  static Rect bounds(Rect source, Size size, double progress) =>
      Rect.lerp(source, Offset.zero & size, progress)!;
  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(
        bounds(source, size, progress),
        Radius.circular(
            sourceRadius.clamp(0, source.shortestSide / 2) * (1 - progress))));
  @override
  bool shouldReclip(ControlExpansionClipper oldClipper) =>
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
SourceExpandRoute<T>? _captureRoute<T>(BuildContext context, Widget page,
    GlobalKey? sourceKey, double? radius, Color? color,
    {bool homeHandoff = false,
    VoidCallback? onExpanded,
    RouteSettings? settings}) {
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
          final pixels =
              math.max(1.0, boundary.size.width * boundary.size.height);
          final ratio = math.min(
              MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0),
              math.sqrt(200000 / pixels));
          image = boundary.captureLastPaint(ratio);
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
        onExpanded: onExpanded,
        homeHandoff: homeHandoff,
        settings: settings,
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
  final route =
      _captureRoute<T>(context, page, sourceKey, sourceRadius, sourceColor);
  if (route == null || !context.mounted) return null;
  return Navigator.of(context).push<T>(route);
}

/// One route transition takes ownership of the home entrance clock. The old
/// onboarding stack is removed only after the new page has finished entering.
void expandHomeAndRemoveHistory(BuildContext context, Widget page,
    {required GlobalKey sourceKey,
    required VoidCallback onExpanded,
    required RouteSettings settings,
    Color? sourceColor}) {
  final route = _captureRoute<void>(context, page, sourceKey, 35, sourceColor,
      homeHandoff: true, onExpanded: onExpanded, settings: settings);
  if (route == null || !context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
}

/// External links hand off after the reveal actually completes. Back/cancel
/// never opens the link, and exceptions cannot leave a blank overlay behind.
Future<void> expandAction(BuildContext context, VoidCallback action,
    {GlobalKey? sourceKey, double? sourceRadius, Color? sourceColor}) async {
  final route = _captureRoute<void>(
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
        final start = (index * .022).clamp(0.0, .28);
        final t = Curves.easeOutCubic.transform(
            ((animation.value - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 28 * (1 - t)),
                child: Transform.scale(scale: .985 + .015 * t, child: child)));
      });
}
