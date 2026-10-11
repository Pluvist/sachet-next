import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sachet/services/automatic_course_refresh.dart';
import 'package:sachet/services/zhengfang_jwxt/class_schedule/class_schedule_semesters/parse_class_schedule_semesters.dart';

void main() {
  test('Concurrent openings share one fetch and one cache commit', () async {
    final runner = CourseRefreshRunner<String>();
    final network = Completer<String>();
    int calls = 0, commits = 0;
    String cache = 'old';
    Future<String> fetch() {
      calls++;
      return network.future;
    }

    Future<void> commit(String data) async {
      commits++;
      cache = data;
    }

    final first =
        runner.run(fetch: fetch, stillCurrent: () => true, commit: commit);
    final second =
        runner.run(fetch: fetch, stillCurrent: () => true, commit: commit);
    expect(identical(first, second), isTrue);
    expect(cache, 'old');
    network.complete('new');
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect([calls, commits], [1, 1]);
    expect(cache, 'new');
  });

  test('Failed refresh leaves previous cache and permits a later retry',
      () async {
    final runner = CourseRefreshRunner<String>();
    String cache = 'old';
    Future<void> commit(String data) async {
      cache = data;
    }

    for (final failure in [
      StateError('offline'),
      const FormatException('login HTML')
    ]) {
      expect(
          await runner.run(
              fetch: () => throw failure,
              stillCurrent: () => true,
              commit: commit),
          isFalse);
      expect(cache, 'old');
    }
    expect(
        await runner.run(
            fetch: () async => 'new', stillCurrent: () => true, commit: commit),
        isTrue);
    expect(cache, 'new');
  });

  test('Logout/manual switch/dispose discard an obsolete response', () async {
    for (int i = 0; i < 3; i++) {
      final runner = CourseRefreshRunner<String>();
      final network = Completer<String>();
      bool valid = true;
      int commits = 0;
      final result = runner.run(
          fetch: () => network.future,
          stillCurrent: () => valid,
          commit: (_) async {
            commits++;
          });
      valid = false;
      network.complete('new');
      expect(await result, isFalse);
      expect(commits, 0);
    }
  });

  test('Timed out result cannot later replace cache', () async {
    final runner = CourseRefreshRunner<String>();
    final network = Completer<String>();
    int commits = 0;
    expect(
        await runner.run(
            fetch: () => network.future,
            stillCurrent: () => true,
            commit: (_) async {
              commits++;
            },
            timeout: const Duration(milliseconds: 1)),
        isFalse);
    network.complete('late');
    await Future<void>.delayed(Duration.zero);
    expect(commits, 0);
  });

  test('Real parser accepts empty term and rejects malformed response',
      () async {
    expect(
        await parseAutomaticCourses({'kbList': [], 'xsxx': {}}), hasLength(35));
    await expectLater(
        parseAutomaticCourses({'kbList': []}), throwsFormatException);
    final courses = await parseAutomaticCourses({
      'xsxx': {},
      'kbList': [
        {
          'xqj': '1',
          'zcd': '1-16周(双)',
          'kcmc': '线性代数',
          'xm': '老师',
          'cdmc': '逸夫楼201',
          'jc': '1-2节'
        }
      ]
    });
    expect(courses[0].single.title, '线性代数');
    expect(courses[0].single.weeks, [2, 4, 6, 8, 10, 12, 14, 16]);
  });

  test('Cache staged write leaves previous snapshot intact and readable',
      () async {
    final dir = await Directory.systemTemp.createTemp('sachet-cache-test-');
    try {
      final old = File('${dir.path}/old.json');
      final fresh = File('${dir.path}/new.json');
      await old.writeAsString('["old"]');
      await writeAtomicCourseCache(fresh, '["new"]');
      expect(jsonDecode(await old.readAsString()), ['old']);
      expect(jsonDecode(await fresh.readAsString()), ['new']);
      expect(await File('${fresh.path}.tmp').exists(), isFalse);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('Semester selected attribute accepts standard empty HTML value', () {
    final term = parseClassScheduleSemestersFromHtmlZF('''
      <select id="xnm"><option value="2026" selected>2026-2027</option></select>
      <select id="xqm"><option value="3" selected>1</option></select>
    ''');
    expect(term.$1, '2026');
    expect(term.$3, '3');
  });
}
