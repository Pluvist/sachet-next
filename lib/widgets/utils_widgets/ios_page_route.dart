import 'package:flutter/material.dart';
import 'package:sachet/utils/ios_motion.dart';

/// Preserve Flutter's Cupertino navigation and interactive back gesture, while
/// control expansions use depth instead of moving the previous page sideways.
class IOSPageRoute<T> extends MaterialPageRoute<T> {
  IOSPageRoute(
      {required super.builder,
      super.settings,
      super.maintainState,
      super.fullscreenDialog,
      super.allowSnapshotting});
  DepthExpansionRoute? _expansionAbove;
  bool get _reduced =>
      navigator != null &&
      (MediaQuery.maybeOf(navigator!.context)?.disableAnimations ?? false);
  @override
  Duration get transitionDuration =>
      _reduced ? Duration.zero : IOSMotion.duration;
  @override
  Duration get reverseTransitionDuration =>
      _reduced ? Duration.zero : IOSMotion.closingDuration;
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is DepthExpansionRoute || super.canTransitionTo(nextRoute);
  @override
  void didChangeNext(Route<dynamic>? nextRoute) {
    _expansionAbove = nextRoute is DepthExpansionRoute
        ? nextRoute as DepthExpansionRoute
        : null;
    if (_expansionAbove != null && nextRoute is TransitionRoute<dynamic>) {
      final above = _expansionAbove;
      // didPopNext fires before the reverse animation. Retain the depth until
      // the outgoing overlay has finished, then release its animation listener.
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
    final depth = _expansionAbove;
    final page = super.buildTransitions(
        context,
        animation,
        depth == null
            ? secondaryAnimation
            : const AlwaysStoppedAnimation<double>(0),
        child);
    return depth == null
        ? page
        : PageDepthTransition(
            animation: depth.depthProgressAnimation, child: page);
  }
}
