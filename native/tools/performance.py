"""Repeatable portrait UI deadline checks on the 1216x2640 OnePlus test device.

Run from any directory with Python 3 and adb. Requires an unlocked USB device.
--suite focus uses the existing preview data; --suite controls requires the isolated
benchmark APK, whose load_fixture entry supplies synthetic query rows and courses.
No recording, screenshots or UI inspection runs inside the measured windows.
"""
import argparse
import datetime
import json
import os
from pathlib import Path
import re
import statistics
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--adb', default=str(Path(os.environ.get('LOCALAPPDATA', '')) / 'Android/Sdk/platform-tools/adb.exe'))
parser.add_argument('--serial')
parser.add_argument('--package', default='com.pluvist.sachet.next.benchmark')
parser.add_argument('--suite', choices=['focus', 'controls'], default='focus')
parser.add_argument('--tag', default=datetime.datetime.now().strftime('portrait-%Y%m%d-%H%M%S'))
args = parser.parse_args()
if not re.fullmatch(r'[\w.-]+', args.tag) or '..' in args.tag:
    parser.error('Use a simple result tag without path separators.')
if args.suite == 'controls' and not args.package.endswith('.benchmark'):
    parser.error('The populated-controls suite requires the isolated benchmark package.')
devices = subprocess.check_output([args.adb, 'devices'], text=True)
available = re.findall(r'^([^\s]+)\s+device$', devices, re.M)
if args.serial is None:
    if len(available) != 1:
        parser.error('Connect one device or specify --serial.')
    args.serial = available[0]
command = [args.adb, '-s', args.serial]
output = Path(__file__).resolve().parents[1] / 'artifacts'
output.mkdir(exist_ok=True)
results = {}


def adb(*items):
    return subprocess.check_output(command + list(map(str, items)), text=True, encoding='utf-8', errors='replace')


def guard():
    assert any(args.package in line and 'mCurrentFocus=' in line
               for line in adb('shell', 'dumpsys', 'window').splitlines()), 'App lost focus; stopped.'


def inspect():
    guard()
    adb('shell', 'uiautomator', 'dump', '/sdcard/sachet-performance-ui.xml')
    return ET.fromstring(adb('shell', 'cat', '/sdcard/sachet-performance-ui.xml'))


def tap(x, y):
    adb('shell', 'input', 'tap', x, y)


up = (600, 1850, 600, 750, 350)
down = (600, 750, 600, 1850, 350)


def swipe(motion):
    adb('shell', 'input', 'swipe', *motion)


def motions(items):
    for motion in items:
        swipe(motion)
        time.sleep(.15)


def find(title):
    for _ in range(9):
        root = inspect()
        parents = {child: parent for parent in root.iter() for child in parent}
        for node in root.iter('node'):
            if node.get('text') != title and node.get('content-desc') != title:
                continue
            while node.get('clickable') != 'true' and node in parents:
                node = parents[node]
            bounds = list(map(int, re.findall(r'\d+', node.get('bounds', ''))))
            if len(bounds) == 4 and node.get('clickable') == 'true' and 300 < (bounds[1]+bounds[3])/2 < 2100:
                return (bounds[0]+bounds[2])//2, (bounds[1]+bounds[3])//2
        guard()
        swipe(up)
        time.sleep(.3)
    raise AssertionError('Unreachable target: ' + title)


def root_page(key):
    tap(245 if key == 'home' else 1035, 2420)
    time.sleep(.8)
    for _ in range(4 if key == 'home' else 2):
        swipe(down)
        time.sleep(.2)


def opens(point, repeats):
    for hold in (.08, .15, .3):
        for _ in range(repeats):
            tap(*point)
            time.sleep(hold)
            adb('shell', 'input', 'keyevent', 4)
            time.sleep(.08)


def measure(label, action):
    guard()
    pid = adb('shell', 'pidof', args.package).strip()
    adb('shell', 'dumpsys', 'gfxinfo', args.package, 'reset')
    action()
    time.sleep(.6)
    stats = adb('shell', 'dumpsys', 'gfxinfo', args.package, 'framestats')
    (output / f'{args.tag}-{label}-gfxinfo.txt').write_text(stats, encoding='utf-8')

    def count(pattern):
        match = re.search(pattern, stats, re.M)
        return int(match[1]) if match else None

    total = count(r'^Total frames rendered:\s*(\d+)')
    missed = count(r'^Number Frame deadline missed:\s*(\d+)')
    assert total and missed is not None, 'No current Android deadline data.'
    header = next(line for line in stats.splitlines() if line.startswith('Flags,'))
    columns = header.strip(',').split(',')
    rows = [dict(zip(columns, map(int, line.strip(',').split(','))))
            for line in stats.splitlines() if re.match(r'^0,\d', line)]
    intervals = [row['FrameInterval'] for row in rows if row.get('FrameInterval', 0) > 0]
    results[label] = dict(frames=total, missed=missed, rate=round(100*missed/total, 3),
                          legacy_janky=count(r'^Janky frames \(legacy\):\s*(\d+)'),
                          p95_ms=count(r'^95th percentile:\s*(\d+)'),
                          p99_ms=count(r'^99th percentile:\s*(\d+)'),
                          median_interval_ns=statistics.median(intervals) if intervals else None,
                          same_process=pid == adb('shell', 'pidof', args.package).strip())
    (output / f'{args.tag}-results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')
    print(label, json.dumps(results[label]), flush=True)
    assert results[label]['same_process'], 'Process restarted.'
    guard()


size = adb('shell', 'wm', 'size')
assert re.findall(r'(\d+x\d+)', size)[-1] == '1216x2640', 'This coordinate protocol is for the 1216x2640 device.'
rotation = adb('shell', 'settings', 'get', 'system', 'user_rotation').strip()
auto = adb('shell', 'settings', 'get', 'system', 'accelerometer_rotation').strip()
try:
    adb('shell', 'wm', 'user-rotation', 'lock', 0)
    adb('shell', 'am', 'force-stop', args.package)
    launch = ['shell', 'am', 'start', '-W', '-n', args.package+'/com.pluvist.sachet.next.MainActivity']
    if args.package.endswith('.benchmark'):
        launch += ['--ez', 'load_fixture', 'true']
    adb(*launch)
    time.sleep(1.6)
    guard()
    if args.suite == 'focus':
        root_page('home')
        point = find('培养方案')
        measure('home_fast_controls', lambda: opens(point, 6))
        measure('home_scroll', lambda: motions([up, down]*10))
        for key, title in [('appearance', '课表外观'), ('settings', '设置'), ('files', '导入与导出课表')]:
            root_page('profile')
            point = find(title)
            measure(key+'_fast_controls', lambda: opens(point, 6))
        root_page('profile')
        measure('profile_scroll', lambda: motions([up, down]*10))

        def switch():
            for index in range(24):
                tap((245, 1035)[index % 2], 2420)
                time.sleep(.08)
        measure('home_profile_fast_tabs', switch)
    else:
        groups = [('home', [('cultivation', '培养方案'), ('textbooks', '教材预订'), ('exams', '考试时间'),
                            ('grades', '成绩查询'), ('gpa', '绩点排名'), ('transcript', '成绩单'), ('classrooms', '空闲教室')]),
                  ('profile', [('login', '登录教务账号'), ('appearance', '课表外观'), ('settings', '设置'),
                               ('permissions', '后台运行与通知权限'), ('files', '导入与导出课表'),
                               ('file_manager', '数据文件'), ('about', 'Xachet')])]
        for page, targets in groups:
            for key, title in targets:
                root_page(page)
                point = find(title)
                tap(*point)
                time.sleep(.75)
                adb('shell', 'input', 'keyevent', 4)
                time.sleep(.7)
                measure(page+'_'+key, lambda: opens(point, 4))
    assert all(result['rate'] <= 5 for result in results.values()), 'Some individual scenarios exceed 5%; see JSON.'
finally:
    adb('shell', 'wm', 'user-rotation', 'free' if auto == '1' else 'lock', *([] if auto == '1' else [rotation]))
