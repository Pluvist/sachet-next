package com.pluvist.sachet.next

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Locale
import kotlin.math.max

/** Uses the same resolved timestamps as home and live activity. */
object CourseWidgetWideRenderer {
    fun render(context: Context, data: JSONObject, now: Long, width: Int, height: Int): RemoteViews {
        val source = data.optJSONArray("lessons")
        val lessons = (0 until (source?.length() ?: 0)).mapNotNull { index ->
            val value = source!!.optJSONObject(index) ?: return@mapNotNull null
            val start = value.optLong("start"); val end = value.optLong("end")
            if (start <= 0 || end <= start) return@mapNotNull null
            LiveLesson(value.optString("title"), value.optString("place"), start, end)
        }
        val state = CourseTimeline.resolve(now, lessons)
        val ready = data.optBoolean("ready")
        val current = state.current.takeIf { ready }; val next = state.next.takeIf { ready }
        val mode = data.optInt("themeMode", 0)
        val dark = mode == 2 || (mode == 0 && context.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES)
        val foreground = if (dark) 0xffeeeeee.toInt() else 0xff171717.toInt()
        val muted = if (dark) 0xffb0b6c8.toInt() else 0xff626977.toInt()
        val time = SimpleDateFormat("HH:mm", Locale.ROOT)
        val view = RemoteViews(context.packageName, R.layout.course_widget_wide)
        fun text(id: Int, value: String, color: Int = muted) {
            view.setTextViewText(id, value); view.setTextColor(id, color)
        }
        fun visible(id: Int, yes: Boolean) = view.setViewVisibility(id, if (yes) View.VISIBLE else View.GONE)
        fun minutes(end: Long) = max(1L, (end - now + 59999) / 60000)
        val status = when {
            !ready -> "今日课程"
            current != null -> "正在上课"
            next != null -> "待上课"
            state.phase == LiveCoursePhase.NONE -> "今日安排"
            else -> "课程已完成"
        }
        val title = when {
            !ready -> "请先导入课表"
            current != null -> current.title
            next != null -> "当前未在上课"
            state.phase == LiveCoursePhase.NONE -> "今日无课喵~"
            else -> "今日课程已完成"
        }
        text(R.id.widget_current_status, status)
        text(R.id.widget_title, title, foreground)
        text(R.id.widget_place, current?.place ?: "")
        text(R.id.widget_countdown, if (current == null) "" else "距下课 ${minutes(current.end)} 分钟")
        text(R.id.widget_footer, when {
            !ready -> "打开应用导入课表"
            next != null -> "距上课 ${minutes(next.start)} 分钟"
            else -> "今天的时间属于你"
        })
        val contentHeight = height - 12
        visible(R.id.widget_place, current != null && contentHeight >= 140)
        visible(R.id.widget_countdown, current != null)
        visible(R.id.widget_footer, current == null)
        text(R.id.widget_next_label, when {
            !ready -> "下一节课"
            next != null -> "下一节课"
            state.phase == LiveCoursePhase.NONE -> "今天没有课程"
            else -> "今天没有下一节课"
        })
        text(R.id.widget_next_title, next?.title ?: "", foreground)
        text(R.id.widget_next_time, next?.let { "${time.format(it.start)}–${time.format(it.end)}" } ?: "")
        text(R.id.widget_next_place, next?.place ?: if (!ready) "导入后显示课程安排" else "好好享受空闲时间")
        visible(R.id.widget_next_title, next != null && contentHeight >= 140)
        visible(R.id.widget_next_time, next != null)
        val date = SimpleDateFormat("今天 / EEEE", Locale.CHINA).format(now)
        val semester = try { SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).parse(data.optString("semester").take(10))?.time } catch (_: Exception) { null }
        val week = if (semester == null || state.midnight < semester) 0 else ((state.midnight - semester) / (7 * 86400000L) + 1).toInt()
        text(R.id.widget_date, date)
        text(R.id.widget_week, if (week > 0) "第${week}周" else "未开学")
        visible(R.id.widget_wide_header, contentHeight >= 150)
        view.setInt(R.id.widget_title, "setMaxLines", if (contentHeight < 150) 1 else 2)
        view.setInt(R.id.widget_footer, "setMaxLines", if (contentHeight < 130) 1 else 2)
        // The launcher allocation is fixed. Cap visual text growth, retaining
        // unabridged details in the screen-reader description below.
        val scale = max(1f, context.resources.configuration.fontScale / 1.25f)
        val titleSize = if (width < 300) 14f else 16f
        for (id in listOf(R.id.widget_title, R.id.widget_next_title))
            view.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, titleSize / scale)
        for (id in listOf(R.id.widget_place, R.id.widget_next_time, R.id.widget_next_place))
            view.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, 11f / scale)
        for (id in listOf(R.id.widget_current_status, R.id.widget_footer, R.id.widget_countdown,
                R.id.widget_next_label, R.id.widget_date, R.id.widget_week))
            view.setTextViewTextSize(id, TypedValue.COMPLEX_UNIT_SP, 10f / scale)
        CourseWidgetGlow.apply(context, view, dark, wide = true, width = width, height = height)
        view.setInt(R.id.widget_divider, "setColorFilter", if (dark) 0xff393939.toInt() else 0xffdddddd.toInt())
        view.setInt(R.id.widget_state_icon, "setColorFilter", muted)
        view.setImageViewResource(R.id.widget_state_icon, if (current == null && next == null) R.drawable.widget_check else R.drawable.widget_going)
        val open = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        view.setOnClickPendingIntent(R.id.widget_root, PendingIntent.getActivity(context, 774, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
        view.setOnClickPendingIntent(R.id.widget_state_icon, CourseWidgetProvider.refreshIntent(context))
        view.setContentDescription(R.id.widget_state_icon, "刷新课程状态")
        view.setContentDescription(R.id.widget_root, "$status，$title，${current?.place ?: ""}，" +
            (next?.let { "下一节${it.title}，${time.format(it.start)}至${time.format(it.end)}，${it.place}" } ?: "今天没有下一节课"))
        return view
    }
}
