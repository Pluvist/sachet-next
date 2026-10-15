import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sachet/models/course_schedule.dart';
import 'package:sachet/pages/class_child_pages/single_week_page.dart';
import 'package:sachet/providers/class_page_provider.dart';
import 'package:sachet/providers/course_card_settings_provider.dart';

class WeekView extends StatefulWidget {
  final List<List<CourseSchedule>>? courseScheduleItemsList;
  final Map? courseColorData;
  final List? classSessionSummerDataList;
  final List? classSessionWinterDataList;

  const WeekView({
    super.key,
    this.courseScheduleItemsList,
    this.courseColorData,
    this.classSessionSummerDataList,
    this.classSessionWinterDataList,
  });

  @override
  State<WeekView> createState() => _WeekViewState();
}

class _WeekViewState extends State<WeekView> {
  static const double _minCardHeight = 36.0;
  static const double _maxCardHeight = 100.0;

  double _cardHeight = 65.0;
  double _baseCardHeight = 65.0;
  int _pointerCount = 0;

  void _changePointers(int delta) {
    final wasScaling = _pointerCount >= 2;
    _pointerCount = (_pointerCount + delta).clamp(0, 10);
    // Single-finger taps and page swipes do not change any rendered geometry.
    if (wasScaling != (_pointerCount >= 2)) setState(() {});
  }

  @override
  void initState() {
    _cardHeight = context.read<CourseCardSettingsProvider>().cardHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !context.read<ClassPageProvider>().pageController.hasClients) return;
      context.read<ClassPageProvider>().pageController.jumpToPage(context
          .read<ClassPageProvider>()
          .pageForWeek(context.read<ClassPageProvider>().currentWeekCount));
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<ClassPageProvider>().configureWeekPaging(
        MediaQuery.orientationOf(context) == Orientation.landscape);
  }

  @override
  Widget build(BuildContext context) {
    final double persistedCardHeight =
        context.select<CourseCardSettingsProvider, double>(
            (provider) => provider.cardHeight);

    // 如果外部 Provider 变了，且当前没有手势操作，则同步本地状态
    // 使用 > 0.1 避免浮点数精度问题导致的无限重建
    if (_pointerCount == 0 && (persistedCardHeight - _cardHeight).abs() > 0.1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _cardHeight = persistedCardHeight);
        }
      });
    }

    final model = context.read<ClassPageProvider>();
    final stride = model.weekPageStride;
    return Listener(
      onPointerDown: (event) => _changePointers(1),
      onPointerUp: (event) => _changePointers(-1),
      onPointerCancel: (event) => _changePointers(-1),
      child: GestureDetector(
        onScaleStart: (details) {
          _baseCardHeight = _cardHeight;
        },
        onScaleUpdate: (details) {
          if (details.pointerCount < 2) return;
          setState(() {
            _cardHeight = (_baseCardHeight * details.scale)
                .clamp(_minCardHeight, _maxCardHeight);
          });
        },
        onScaleEnd: (details) {
          context.read<CourseCardSettingsProvider>().setCardHeight(_cardHeight);
        },
        child: PageView.builder(
            key: ValueKey('week-pager-$stride'),
            controller: context.read<ClassPageProvider>().pageController,
            onPageChanged: (value) {
              context.read<ClassPageProvider>().updateWeekPage(value);
            },
            physics: _pointerCount >= 2
                ? const NeverScrollableScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            allowImplicitScrolling: stride == 1,
            itemCount: 20 * stride,
            itemBuilder: (context, index) => RepaintBoundary(
                  child: SingleWeekPage(
                    key: ValueKey(index),
                    weekCount: index ~/ stride + 1,
                    firstWeekday: stride == 4
                        ? (index % 4 == 3 ? 6 : index % 4 * 2 + 1)
                        : 1,
                    dayCount: stride == 4 ? 2 : 7,
                    onPreviousDays: index == 0
                        ? null
                        : () => model.pageController.previousPage(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic),
                    onNextDays: index == 20 * stride - 1
                        ? null
                        : () => model.pageController.nextPage(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic),
                    courseScheduleItemsList: widget.courseScheduleItemsList,
                    courseColorData: widget.courseColorData,
                    classSessionSummerDataList:
                        widget.classSessionSummerDataList,
                    classSessionWinterDataList:
                        widget.classSessionWinterDataList,
                    cardHeight: _cardHeight,
                    pointerCount: _pointerCount >= 2 ? 2 : 0,
                  ),
                )),
      ),
    );
  }
}
