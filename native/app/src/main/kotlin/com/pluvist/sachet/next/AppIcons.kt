package com.pluvist.sachet.next

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp

internal fun appIcon(key:String):ImageVector=when(key) {
    "cultivation"->Icons.Default.School
    "textbooks"->Icons.Default.Book
    "exams"->Icons.Default.Schedule
    "grades"->Icons.Default.HistoryEdu
    "gpa"->Icons.Default.Leaderboard
    "transcript"->Icons.Default.Description
    "library"->Icons.Default.LocalLibrary
    "physics"->Icons.Default.Science
    "network"->Icons.Default.Wifi
    "classrooms"->Icons.Default.MeetingRoom
    "calendar"->Icons.Default.DateRange
    "news"->Icons.Default.Newspaper
    "mail"->Icons.Default.Email
    "devices"->Icons.Default.Devices
    "portal"->Icons.Default.AccountBalance
    "website"->Icons.Default.Public
    "login"->Icons.Default.Person
    "permissions"->Icons.Default.Notifications
    "settings"->Icons.Default.Settings
    "appearance"->Icons.Default.Palette
    "files"->Icons.Default.ImportExport
    "fileManager"->Icons.Default.Folder
    "widget"->Icons.Default.Widgets
    "logout"->Icons.Default.Logout
    "source"->Icons.Default.Code
    else->Icons.Default.Info
}

/** Bright solid badge colors, following the pre-rewrite MiuixIconBadge treatment. */
internal fun appIconColor(key:String):Color=Color(when(key) {
    "cultivation", "network", "settings", "devices", "website" -> 0xFF3482FF
    "textbooks", "portal", "login", "widget" -> 0xFF7962FF
    "exams", "classrooms", "permissions", "fileManager" -> 0xFFFFA922
    "grades", "course_done" -> 0xFF28C65B
    "gpa" -> 0xFFA45AFF
    "transcript" -> 0xFF328BE8
    "library" -> 0xFF00B6C7
    "physics" -> 0xFFF34F85
    "calendar", "logout" -> 0xFFFF515E
    "news", "files", "course_running" -> 0xFFFF9822
    "mail" -> 0xFF3D78FF
    "appearance" -> 0xFFE74CAF
    "source" -> 0xFF00BFA5
    else -> 0xFF3482FF
})

@Composable internal fun AppIconBadge(key:String,compact:Boolean=false) {
    val tint=appIconColor(key)
    val scale=io.github.neoruaa.glasmio.core.LocalGlasmioLayoutFontScale.current.coerceIn(1f,1.35f)
    val slotSize=(if(compact)30f else 34f)*scale
    val size=slotSize*.9f
    // Match the former Flutter badge: solid color, .28 radius, .62 white glyph.
    Box(Modifier.size(slotSize.dp),contentAlignment=Alignment.Center) {
    Box(Modifier.size(size.dp).background(tint,RoundedCornerShape((size*.28f).dp)),contentAlignment=Alignment.Center) {
        Icon(appIcon(key),null,Modifier.size((size*.62f).dp),tint=Color.White)
    }
    }
}
