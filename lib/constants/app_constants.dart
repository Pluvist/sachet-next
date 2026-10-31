import 'package:flutter/material.dart';

final DateTime constSemesterStartDate = DateTime(2026, 9, 7);

/// 应用预设主题色（MaterialColor）
const List defaultThemeColors = <MaterialColor>[
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
];

/// 应用主题色（品牌色）
const appBrandColor = Color(0xFF3482FF);

final List<Color> materialColorsShade400 = [
  Colors.amber.shade400,
  Colors.blue.shade400,
  Colors.blueAccent.shade400,
  // Colors.brown.shade400,
  // Colors.cyanAccent.shade400,
  Colors.deepOrange.shade400,
  Colors.deepPurple.shade400,
  Colors.deepPurpleAccent.shade400,
  // Colors.greenAccent.shade400,
  // Colors.grey.shade400,
  Colors.lightGreen.shade400,
  Colors.indigoAccent.shade400,
  // Colors.limeAccent.shade400,
  Colors.orangeAccent.shade400,
  // Colors.blueGrey.shade400,
  Colors.cyan.shade400,
  Colors.green.shade400,
  Colors.indigo.shade400,
  // Colors.lime.shade400,
  Colors.orange.shade400,
  // Colors.purple.shade400,
  Colors.teal.shade400,
  // Colors.pink.shade400,
];

const String disclaimer = """
1. 本软件由第三方独立开发，仅调用教务系统服务器的数据，**与官方机构无关**。
2. 教务登录请求直接发送至学校服务，已保存的登录信息使用设备安全存储，课程缓存与组件快照保存在本机。
3. 本软件**提供的信息仅供参考，不保证实时性或准确性**，请以官方平台的数据为准。
4. 桌面组件、提醒与课程实时活动会向系统传递必要的课程内容；您可以通过应用与系统设置管理这些功能。
5. Xachet 由 Pluvist 基于开源项目 [Sachet](https://github.com/wyvern1723/sachet) 二次修改，感谢上游作者 wyvern1723。本修改版本整体遵循 [AGPL-3.0 协议](https://github.com/Pluvist/Xachet/blob/main/LICENSE)，保留上游 MIT 许可证与版权声明，**对应用的运行情况不作任何形式的担保**。

PS: 本软件只整合了教务系统的部分常用功能，完整功能请使用教务系统。

Tip: 课程表优先显示本地缓存，并在打开应用及返回前台时尝试更新；联网失败时保留缓存，也可手动刷新。
""";

/// 夏令时每节课的开始时间
const List classSessionSummerRoutineStartTime = [
  '08:00',
  '08:55',
  '10:20',
  '11:15',
  '14:00',
  '14:55',
  '16:20',
  '17:15',
  '19:15',
  '20:10',
  '21:05'
];

/// 夏令时每节课的结束时间
const List classSessionSummerRoutineEndTime = [
  '08:45',
  '09:40',
  '11:05',
  '12:00',
  '14:45',
  '15:40',
  '17:05',
  '18:00',
  '20:00',
  '20:55',
  '21:50'
];

/// 冬令时每节课的开始时间
const List classSessionWinterRoutineStartTime = [
  '08:00',
  '08:55',
  '10:20',
  '11:15',
  '14:00',
  '14:55',
  '16:20',
  '17:15',
  '19:15',
  '20:10',
  '21:05'
];

/// 冬令时每节课的结束时间
const List classSessionWinterRoutineEndTime = [
  '08:45',
  '09:40',
  '11:05',
  '12:00',
  '14:45',
  '15:40',
  '17:05',
  '18:00',
  '20:00',
  '20:55',
  '21:50'
];
