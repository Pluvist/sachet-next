import 'package:flutter/widgets.dart';

/// Run once after an animation-free frame; coalesce repeated requests.
/// Frame callbacks avoid a zero-delay idle-task loop during touch animations.
class IdleFrameWork {
  bool _queued = false;
  VoidCallback? _work;
  void schedule(VoidCallback work) {
    _work = work;
    if (_queued) return;
    _queued = true;
    WidgetsBinding.instance.addPostFrameCallback(_tryRun);
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _tryRun(Duration _) {
    if (!_queued) return;
    if (WidgetsBinding.instance.transientCallbackCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback(_tryRun);
      return;
    }
    _queued = false;
    final work = _work;
    _work = null;
    work?.call();
  }

  void cancel() {
    _queued = false;
    _work = null;
  }
}
