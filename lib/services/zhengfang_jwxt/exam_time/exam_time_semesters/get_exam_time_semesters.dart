import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/exam_time/exam_time_service.dart';

/// 从正方教务系统获取考试时间查询页面当前学年，可选学年和当前学期
///
/// Return (
/// String 当前学年(如 "2025"),
/// Map<学年标签: 对应的值>,
/// String 当前学期的 Value (如 "3"=>第一学期，"12"=>第二学期)
/// )
///
/// e.g.
///
/// ```
/// (
/// "2025",
/// {
///   "全部": "",
///   "2030-2031": "2030",
///   "2029-2030": "2029",
///   "2028-2029": "2028",
///   "2027-2028": "2027",
///   "2026-2027": "2026",
///   "2025-2026": "2025",
///   "2024-2025": "2024",
///   "2023-2024": "2023",
///   "2022-2023": "2022",
///   "2021-2022": "2021",
///   "2020-2021": "2020",
///   "2019-2020": "2019",
///   "2018-2019": "2018",
///   "2017-2018": "2017",
///   "2016-2017": "2016",
///   "2015-2016": "2015",
///   "2014-2015": "2014",
///   "2013-2014": "2013",
///   "2012-2013": "2012",
///   "2011-2012": "2011",
///   "2010-2011": "2010",
///   "2009-2010": "2009",
///   "2008-2009": "2008",
///   "2007-2008": "2007",
///   "2006-2007": "2006",
///   "2005-2006": "2005",
///   "2004-2005": "2004",
///   "2003-2004": "2003",
///   "2002-2003": "2002",
///   "2001-2002": "2001"
/// },
/// "3"
/// )
/// ```
Future<
    ({
      String? currentSemesterYear,
      Map<String, String> semestersYears,
      String? currentSemesterIndex
    })> getExamTimeSemestersZF({
  required String cookie,
  required ZhengFangUserProvider? zhengFangUserProvider,
}) async {
  return const ExamTimeService().getExamTimeSemesters(
    cookie: cookie,
    zhengFangUserProvider: zhengFangUserProvider,
  );
}
