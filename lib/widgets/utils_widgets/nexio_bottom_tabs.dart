// Dart port of NexioSchedule LiquidBottomTabs.kt / DampedDragAnimation.kt.
// Source: HaoZai000/NexioSchedule, ab6c7a7. SPDX-License-Identifier: AGPL-3.0-only
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:sachet/widgets/utils_widgets/liquid_glass_surface.dart';

class NexioBottomTabs extends StatefulWidget {
  const NexioBottomTabs(
      {super.key,
      required this.selected,
      this.height = 56,
      required this.children,
      required this.onSelected});
  final int selected;
  final double height;
  final List<Widget> children;
  final ValueChanged<int> onSelected;
  @override
  State<NexioBottomTabs> createState() => _NexioBottomTabsState();
}

class _NexioBottomTabsState extends State<NexioBottomTabs>
    with TickerProviderStateMixin {
  late final AnimationController position = AnimationController.unbounded(
      vsync: this, value: widget.selected.toDouble());
  late final AnimationController press =
      AnimationController.unbounded(vsync: this);
  late final AnimationController scale =
      AnimationController.unbounded(vsync: this, value: 1);
  late final AnimationController scaleY =
      AnimationController.unbounded(vsync: this, value: 1);
  double target = 0, down = 0, last = 0;
  bool dragging = false;
  int? pointer;
  final SpringDescription valueSpring =
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1000, ratio: 1);
  @override
  void initState() {
    super.initState();
    target = widget.selected.toDouble();
  }

  void spring(AnimationController controller, double value,
      SpringDescription description) {
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.value = value;
      return;
    }
    controller.animateWith(SpringSimulation(
        description, controller.value, value, controller.velocity));
  }

  void move(double value) {
    target = value.clamp(0, widget.children.length - 1).toDouble();
    spring(position, target, valueSpring);
  }

  void pressed(bool value) {
    spring(scaleY, value ? 78 / 56 : 1,
        SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: .7));
    spring(press, value ? 1 : 0, valueSpring);
    spring(scale, value ? 78 / 56 : 1,
        SpringDescription.withDampingRatio(mass: 1, stiffness: 250, ratio: .6));
  }

  @override
  void didUpdateWidget(NexioBottomTabs old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected && pointer == null) {
      move(widget.selected.toDouble());
    }
  }

  @override
  void dispose() {
    position.dispose();
    press.dispose();
    scale.dispose();
    scaleY.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, constraints) {
      final tabWidth = (constraints.maxWidth - 8) / widget.children.length;
      final rtl = Directionality.of(context) == TextDirection.rtl;
      double coordinate(double x) => rtl ? constraints.maxWidth - x : x;
      final fixedBackground = Positioned.fill(
          child: RepaintBoundary(
              key: const ValueKey('nexioFixedBackdrop'),
              child: LiquidGlassSurface(
                  blur: 8,
                  lensHeight: 24,
                  lensAmount: 24,
                  tint: dark
                      ? const Color(0xff242424).withOpacity(.6)
                      : const Color(0xfffafafa).withOpacity(.6),
                  child: const SizedBox())));
      final fixedLabels = Positioned.fill(
          child: RepaintBoundary(
              key: const ValueKey('nexioFixedLabels'),
              child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(children: [
                    for (var i = 0; i < widget.children.length; i++)
                      Expanded(
                          child: Semantics(
                              selected: i == widget.selected,
                              label: widget.children[i] is Tooltip
                                  ? (widget.children[i] as Tooltip).message
                                  : null,
                              button: true,
                              onTap: () {
                                move(i.toDouble());
                                widget.onSelected(i);
                              },
                              child: IgnorePointer(
                                  child: Center(child: widget.children[i])))),
                  ]))));
      return Listener(
        onPointerDown: (event) {
          if (pointer != null) return;
          pointer = event.pointer;
          down = last = coordinate(event.localPosition.dx);
          dragging = (down - (4 + (position.value + .5) * tabWidth)).abs() <=
              tabWidth * .55;
          if (dragging) {
            target = position.value;
            position.stop();
          }
          pressed(true);
          if (!dragging) move(((down - 4) / tabWidth).floor().toDouble());
        },
        onPointerMove: (event) {
          if (pointer != event.pointer) return;
          final x = coordinate(event.localPosition.dx);
          if (!dragging && (x - down).abs() > 18) {
            dragging = true;
            target = position.value;
            position.stop();
            last = x;
          }
          if (dragging) {
            target = (target + (x - last) / tabWidth)
                .clamp(0, widget.children.length - 1)
                .toDouble();
            position.value = target;
          }
          last = x;
        },
        onPointerUp: (event) {
          if (pointer != event.pointer) return;
          pointer = null;
          final selected = target.round().clamp(0, widget.children.length - 1);
          move(selected.toDouble());
          pressed(false);
          widget.onSelected(selected);
        },
        onPointerCancel: (event) {
          if (pointer != event.pointer) return;
          pointer = null;
          move(widget.selected.toDouble());
          pressed(false);
        },
        child: AnimatedBuilder(
            animation: Listenable.merge([position, press, scale, scaleY]),
            child: fixedBackground,
            builder: (context, fixedBackdrop) {
              final p = press.value.clamp(0.0, 1.0);
              final offset =
                  (position.value.clamp(0, widget.children.length - 1) *
                          tabWidth)
                      .toDouble();
              final x = rtl
                  ? constraints.maxWidth - 4 - tabWidth - offset
                  : 4 + offset;
              return SizedBox(
                  height: widget.height,
                  child: Stack(clipBehavior: Clip.none, children: [
                    fixedBackdrop!,
                    Positioned(
                        left: x,
                        top: 4,
                        width: tabWidth,
                        height: widget.height - 8,
                        child: Transform(
                            key: const ValueKey('liquidNavSelection'),
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(
                                math.max(.8, scale.value) /
                                    (1 -
                                        (position.velocity / 10 * .75)
                                            .clamp(-.2, .2)),
                                math.max(.8, scaleY.value) *
                                    (1 -
                                        (position.velocity / 10 * .25)
                                            .clamp(-.2, .2)),
                                1),
                            child: LiquidGlassSurface(
                                blur: 0,
                                lensHeight: 10 * p,
                                lensAmount: 14 * p,
                                dispersion: p,
                                tint: (dark ? Colors.white : Colors.black)
                                    .withOpacity((dark ? .1 : .06) * (1 - p)),
                                child: const SizedBox()))),
                    fixedLabels,
                  ]));
            }),
      );
    });
  }
}
