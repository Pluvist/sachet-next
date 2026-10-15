import 'package:flutter/material.dart';

/// Flutter adaptation of HyperCeiler's source-button scale-up transition.
class SourceExpandRoute<T> extends PageRouteBuilder<T> {
  SourceExpandRoute(
      {required WidgetBuilder builder,
      required Rect source,
      required bool reduceMotion,
      super.settings})
      : super(
            opaque: true,
            transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 550),
            reverseTransitionDuration:
                Duration(milliseconds: reduceMotion ? 0 : 350),
            pageBuilder: (context, animation, secondary) => builder(context),
            transitionsBuilder: (context, animation, secondary, child) {
              final size = MediaQuery.sizeOf(context);
              final t = Curves.easeOutCubic.transform(animation.value);
              final rect = Rect.lerp(source, Offset.zero & size, t)!;
              return Stack(children: [
                Positioned.fromRect(
                    rect: rect,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(35 * (1 - t)),
                        child: FittedBox(
                            fit: BoxFit.fill,
                            child: SizedBox(
                                width: size.width,
                                height: size.height,
                                child: child))))
              ]);
            });
}

Rect expansionSource(BuildContext context) {
  final render = context.findRenderObject();
  if (render is RenderBox && render.hasSize) {
    return render.localToGlobal(Offset.zero) & render.size;
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
      center: size.center(Offset.zero), width: 70, height: 70);
}

Future<T?> expandPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(SourceExpandRoute<T>(
        source: expansionSource(context),
        builder: (_) => page,
        reduceMotion: MediaQuery.disableAnimationsOf(context)));

/// For external actions, expand an app-colored surface before handing off.
Future<void> expandAction(BuildContext context, VoidCallback action) async {
  final navigator = Navigator.of(context);
  final reduce = MediaQuery.disableAnimationsOf(context);
  final route = SourceExpandRoute<void>(
      source: expansionSource(context),
      reduceMotion: reduce,
      builder: (_) =>
          ColoredBox(color: Theme.of(context).scaffoldBackgroundColor));
  navigator.push(route);
  await Future<void>.delayed(Duration(milliseconds: reduce ? 0 : 550));
  if (!context.mounted || !route.isCurrent) return;
  action();
  navigator.removeRoute(route);
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
