import 'package:flutter/material.dart';
import 'package:sachet/widgets/utils_widgets/idle_frame_work.dart';

/// Prepare the other tab while idle, retaining its controllers and loaded data.
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
  final _preparation = IdleFrameWork();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _preparation.schedule(() {
        if (!mounted || _visited.length == widget.children.length) return;
        setState(() =>
            _visited.addAll(List.generate(widget.children.length, (i) => i)));
      });
    });
  }

  @override
  void dispose() {
    _preparation.cancel();
    super.dispose();
  }

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
