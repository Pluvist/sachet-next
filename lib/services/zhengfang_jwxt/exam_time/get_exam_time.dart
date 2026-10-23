import 'package:sachet/services/zhengfang_jwxt/exam_time/models/exam_time_response_zf.dart';
import 'package:sachet/providers/zhengfang_user_provider.dart';
import 'package:sachet/services/zhengfang_jwxt/exam_time/exam_time_service.dart';

/// 从正方教务系统获取考试时间
Future<List<ExamTimeResponseZF>> getExamTimeZF({
  required String cookie,

  /// xnm 学年名，如 '2025'=> 指 2025-2026 学年, ""=> 全部
  required String semesterYear,

  /// xqm 学期名，"3"=> 第1学期，"12"=>第二学期，"16"=>第三学期, ""=> 全部
  required String semesterIndex,
  required ZhengFangUserProvider? zhengFangUserProvider,
}) async {
  return const ExamTimeService().getExamTime(
    cookie: cookie,
    semesterYear: semesterYear,
    semesterIndex: semesterIndex,
    zhengFangUserProvider: zhengFangUserProvider,
  );
}
