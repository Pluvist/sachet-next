import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A damped opening curve with an optional incoming velocity. Endpoint
/// corrections preserve both position and velocity when a route is retargeted.
class IOSOpeningCurve extends Curve {
  const IOSOpeningCurve({this.initialVelocity = 0});
  final double initialVelocity;
  @override
  double transformInternal(double t) {
    final v = initialVelocity;
    final value = 1 - (1 + (10 - v) * t) * math.exp(-10 * t);
    final residual = (11 - v) * math.exp(-10);
    final endVelocity = (v + 10 * (10 - v)) * math.exp(-10);
    return value +
        residual * (3 * t * t - 2 * t * t * t) -
        endVelocity * (t * t * t - t * t);
  }
}

abstract final class IOSMotion {
  static const opening = IOSOpeningCurve();
  static const duration = Duration(milliseconds: 480);
  static const closingDuration = Duration(milliseconds: 360);
  static const homeDuration = Duration(milliseconds: 560);
  static const windowRadius = 32.0;
  static CurvedAnimation routeCurve(Animation<double> animation) =>
      CurvedAnimation(
          parent: animation, curve: opening, reverseCurve: opening.flipped);
}

/// Each route owns its motion. Reversing/reopening starts at the displayed
/// position and incoming velocity, without a global queue or serial timer.
class IOSRouteController extends AnimationController {
  IOSRouteController(
      {required super.vsync,
      required super.duration,
      required super.reverseDuration,
      super.debugLabel});
  TickerFuture _move(double target, bool closing, double? from) {
    if (from != null) value = from;
    final delta = target - value;
    final time = (closing ? reverseDuration : duration)!;
    final seconds = time.inMicroseconds / Duration.microsecondsPerSecond;
    final incoming = delta.abs() < .0001
        ? 0.0
        : (velocity * seconds / delta).clamp(-6.0, 6.0);
    final curve = IOSOpeningCurve(initialVelocity: incoming);
    return closing
        ? super.animateBack(target, duration: time, curve: curve)
        : super.animateTo(target, duration: time, curve: curve);
  }

  @override
  TickerFuture forward({double? from}) => _move(upperBound, false, from);
  @override
  TickerFuture reverse({double? from}) => _move(lowerBound, true, from);
}

/// Implemented only by control expansions (full pages or expanding menus).
abstract interface class DepthExpansionRoute {
  Animation<double> get expansionAnimation;
  Animation<double> get depthProgressAnimation;
}

/// Real route content stays cached; no full-screen screenshot/readback is needed.
class PageDepthTransition extends StatelessWidget {
  const PageDepthTransition(
      {super.key, required this.animation, required this.child});
  final Animation<double> animation;
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: animation,
      child: RepaintBoundary(child: child),
      builder: (context, child) {
        final t =
            MediaQuery.disableAnimationsOf(context) ? 0.0 : animation.value;
        return ColoredBox(
            color: Colors.black,
            child: Stack(fit: StackFit.expand, children: [
              Transform.translate(
                  key: const ValueKey('routeDepthOffset'),
                  offset: Offset(0, 12 * t),
                  child: Transform.scale(
                      key: const ValueKey('routeDepthScale'),
                      scale: 1 - .045 * t,
                      child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(IOSMotion.windowRadius * t),
                          child: child))),
              Positioned.fill(
                  child: IgnorePointer(
                      child: ColoredBox(
                          key: const ValueKey('routeDepthDim'),
                          color: Colors.black.withOpacity(.20 * t)))),
            ]));
      });
}
