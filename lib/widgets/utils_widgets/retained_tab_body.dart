import 'package:flutter/material.dart';

/// Mount tabs on first use, preserving their controllers and loaded data.
/// Hidden tabs cannot paint, handle input, or run Flutter tickers.
class RetainedTabBody extends StatefulWidget {
  const RetainedTabBody(
      {super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;
  @override
  State<RetainedTabBody> createState() => _RetainedTabBodyState();
}

class _RetainedTabBodyState extends State<RetainedTabBody> {
  final Set<int> _visited = {};
  @override
  Widget build(BuildContext context) {
    _visited.add(widget.index);
    return Stack(fit: StackFit.expand, children: [
      for (int i = 0; i < widget.children.length; i++)
        Offstage(
          offstage: i != widget.index,
          child: ExcludeFocus(
            excluding: i != widget.index,
            child: TickerMode(
              enabled: i == widget.index,
              child: RepaintBoundary(
                child: _visited.contains(i)
                    ? widget.children[i]
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
    ]);
  }
}
