import 'package:sachet/utils/ios_motion.dart';
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
  int _generation = 0;
  SourceExpandRoute<dynamic>? _route;
  int hide() {
    if (mounted) setState(() => hidden = true);
    return ++_generation;
  }

  void restore(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _generation) setState(() => hidden = false);
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
class SourceExpandRoute<T> extends PageRouteBuilder<T>
    implements DepthExpansionRoute {
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
  })  : _source = source,
        _sourceRadius = sourceRadius,
        _sourceColor = sourceColor,
        _sourceImage = sourceImage,
        _restoreSource = restoreSource,
        _onExpanded = onExpanded,
        super(
            opaque: true,
            transitionDuration: reduceMotion
                ? Duration.zero
                : homeHandoff
                    ? IOSMotion.homeDuration
                    : IOSMotion.duration,
            reverseTransitionDuration:
                reduceMotion ? Duration.zero : IOSMotion.closingDuration,
            pageBuilder: (context, animation, secondary) => builder(context));
  final Rect _source;
  final double? _sourceRadius;
  final Color? _sourceColor;
  @override
  AnimationController createAnimationController() => IOSRouteController(
      vsync: navigator!,
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      debugLabel: debugLabel);
  @override
  Widget buildModalBarrier() => AnimatedBuilder(
      animation: animation!,
      child: super.buildModalBarrier(),
      builder: (_, child) => IgnorePointer(
          ignoring:
              !homeHandoff && animation!.status != AnimationStatus.completed,
          child: child));
  DepthExpansionRoute? _expansionAbove;
  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    _expansionAbove = nextRoute is DepthExpansionRoute
        ? nextRoute as DepthExpansionRoute
        : null;
    if (_expansionAbove != null && nextRoute is TransitionRoute<dynamic>) {
      final above = _expansionAbove;
      nextRoute.completed.then((_) {
        if (navigator != null && identical(_expansionAbove, above)) {
          _expansionAbove = null;
          changedInternalState();
        }
      });
    }
    super.didChangeNext(nextRoute);
    changedInternalState();
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final size = MediaQuery.sizeOf(context);
    final progress = animation.value;
    final t = depthProgressAnimation.value;
    final color = Theme.of(context).scaffoldBackgroundColor;
    final foreground = IgnorePointer(
      ignoring: homeHandoff
          ? animation.status != AnimationStatus.completed
          : animation.status == AnimationStatus.reverse || progress < .22,
      child: ClipPath(
        key: const ValueKey('sourceExpansionMask'),
        clipper: ControlExpansionClipper(
          source: _source,
          sourceRadius: _sourceRadius ?? MiuixRadii.control,
          progress: t,
        ),
        child: Stack(fit: StackFit.expand, children: [
          Opacity(
              opacity:
                  _sourceImage == null ? 1 : (progress / .12).clamp(0.0, 1.0),
              child: ColoredBox(
                  color: Color.lerp(_sourceColor ?? color, color,
                      ((progress - .25) / .75).clamp(0.0, 1.0))!)),
          Opacity(
              opacity: Curves.easeOut
                  .transform(((progress - .10) / .75).clamp(0.0, 1.0)),
              child: RepaintBoundary(child: child)),
          if (_sourceImage != null && progress < .22)
            Positioned.fromRect(
                rect: Rect.fromCenter(
                    center:
                        ControlExpansionClipper.bounds(_source, size, t).center,
                    width: _source.width,
                    height: _source.height),
                child: Opacity(
                    opacity: (1 - progress / .22).clamp(0.0, 1.0),
                    child: RawImage(image: _sourceImage, fit: BoxFit.fill))),
        ]),
      ),
    );

    final above = _expansionAbove;
    return above == null
        ? foreground
        : PageDepthTransition(
            animation: above.depthProgressAnimation, child: foreground);
  }

  @override
  Animation<double> get depthProgressAnimation => expansionAnimation;
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
  @override
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
  double get radius => ui.lerpDouble(
      sourceRadius.clamp(0, source.shortestSide / 2),
      IOSMotion.windowRadius,
      Curves.easeOut.transform((progress / .6).clamp(0.0, 1.0)))!;
  @override
  Path getClip(Size size) {
    if (progress >= 1) return Path()..addRect(Offset.zero & size);
    final settle =
        Curves.easeIn.transform(((progress - .9) / .1).clamp(0.0, 1.0));
    return Path()
      ..addRRect(RRect.fromRectAndRadius(
          bounds(source, size, progress)
              .inflate(IOSMotion.windowRadius * settle),
          Radius.circular(radius)));
  }

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

SourceExpandRoute<T>? _captureRoute<T>(BuildContext context, Widget page,
    GlobalKey? sourceKey, double? radius, Color? color,
    {bool homeHandoff = false,
    VoidCallback? onExpanded,
    RouteSettings? settings}) {
  final navigator = Navigator.of(context);
  final origin = sourceKey?.currentContext ?? context;
  final source = expansionSource(origin);
  final reduce = MediaQuery.disableAnimationsOf(context);
  ui.Image? image;
  final anchor = sourceKey?.currentState;
  final anchorState = anchor is _ExpansionAnchorState ? anchor : null;
  final active = anchorState?._route;
  if (active?.navigator != null &&
      active!.expansionAnimation.status != AnimationStatus.reverse) return null;
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
            MediaQuery.devicePixelRatioOf(context).clamp(1.0, 1.5),
            math.sqrt(64000 / pixels));
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
  final generation = anchorState?.hide();
  late final SourceExpandRoute<T> route;
  route = SourceExpandRoute<T>(
      restoreSource: () {
        if (identical(anchorState?._route, route)) anchorState?._route = null;
        if (generation != null) anchorState?.restore(generation);
      },
      onExpanded: onExpanded,
      homeHandoff: homeHandoff,
      settings: settings,
      builder: (_) => page,
      source: source,
      sourceRadius: radius,
      sourceColor: color,
      sourceImage: image,
      reduceMotion: reduce);
  anchorState?._route = route;
  return route;
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
  if (!completed || !context.mounted) return;
  if (!route.isCurrent) {
    if (route.isActive) navigator.removeRoute(route);
    return;
  }
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
      this.hasCurvedClock = false,
      required this.child});
  final Animation<double> animation;
  final int index;
  final bool hasCurvedClock;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final start = (index * .022).clamp(0.0, .28);
        final progress =
            ((animation.value - start) / (1 - start)).clamp(0.0, 1.0);
        final t =
            hasCurvedClock ? progress : IOSMotion.opening.transform(progress);
        return Opacity(
            opacity: t,
            child: Transform.translate(
                offset: Offset(0, 28 * (1 - t)),
                child: Transform.scale(scale: .985 + .015 * t, child: child)));
      });
}
