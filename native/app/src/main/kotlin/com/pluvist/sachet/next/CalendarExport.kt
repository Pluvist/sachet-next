package com.pluvist.sachet.next
import java.time.*
import java.time.format.DateTimeFormatter

object CalendarExport {
    private fun escape(value:String)=value.replace("\\","\\\\").replace("\r","").replace("\n","\\n").replace(",","\\,").replace(";","\\;")
    fun exams(rows:List<org.json.JSONObject>,zone:ZoneId=ZoneId.systemDefault()):String=buildString {
        append("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Pluvist//Xachet//ZH\r\nCALSCALE:GREGORIAN\r\n")
        val formatter=DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC)
        val pattern=Regex("(\\d{4}-\\d{2}-\\d{2})\\s*[（(]\\s*(\\d{1,2}:\\d{2})\\s*-\\s*(\\d{1,2}:\\d{2})\\s*[）)]")
        rows.forEach{row->
            val raw=row.optString("kssj");val match=pattern.find(raw)?:error("解析考试时间失败：$raw")
            val date=LocalDate.parse(match.groupValues[1]);val timeFormat=DateTimeFormatter.ofPattern("H:mm")
            val start=date.atTime(LocalTime.parse(match.groupValues[2],timeFormat)).atZone(zone).toInstant()
            val end=date.atTime(LocalTime.parse(match.groupValues[3],timeFormat)).atZone(zone).toInstant()
            require(end>start){"考试结束时间应晚于开始时间"}
            append("BEGIN:VEVENT\r\nUID:${java.util.UUID.randomUUID()}@sachet.next\r\nDTSTAMP:${formatter.format(Instant.now())}\r\n")
            append("DTSTART:${formatter.format(start)}\r\nDTEND:${formatter.format(end)}\r\nSUMMARY:${escape(row.optString("kcmc"))}考试\r\n")
            append("LOCATION:${escape(row.optString("cdmc"))}\r\nDESCRIPTION:${escape(row.optString("jsxx"))}\r\n")
            append("BEGIN:VALARM\r\nTRIGGER:-PT60M\r\nACTION:DISPLAY\r\nDESCRIPTION:考试提醒\r\nEND:VALARM\r\nEND:VEVENT\r\n")
        }
        append("END:VCALENDAR\r\n")
    }
    fun ics(courses:List<Course>,semester:LocalDate,zone:ZoneId=ZoneId.systemDefault()):String=buildString {
        append("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//Pluvist//Xachet//ZH\r\nCALSCALE:GREGORIAN\r\n")
        val formatter=DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC)
        courses.forEach{course->course.weeks.sorted().forEach{week->
            val date=semester.plusWeeks((week-1).toLong()).plusDays((course.weekday-1).toLong())
            val(start,end)=course.interval()
            append("BEGIN:VEVENT\r\nUID:${course.id.hashCode()}-$week@sachet.next\r\nDTSTAMP:${formatter.format(Instant.now())}\r\n")
            append("DTSTART:${formatter.format(date.atTime(start).atZone(zone).toInstant())}\r\nDTEND:${formatter.format(date.atTime(end).atZone(zone).toInstant())}\r\n")
            append("SUMMARY:${escape(course.title)}\r\nLOCATION:${escape(course.place)}\r\nDESCRIPTION:${escape(course.teacher)}\r\nEND:VEVENT\r\n")
        }}
        append("END:VCALENDAR\r\n")
    }
}
