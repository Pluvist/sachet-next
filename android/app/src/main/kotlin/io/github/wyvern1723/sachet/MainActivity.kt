package io.github.wyvern1723.sachet

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import java.util.concurrent.Executors

class MainActivity: FlutterActivity() {
    companion object {
        private val widgetExecutor = Executors.newSingleThreadExecutor()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sachet_next/course_widget")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sync" -> {
                        val context = applicationContext
                        val data = call.arguments as String
                        widgetExecutor.execute {
                            try {
                                val saved = context.getSharedPreferences("course_widget", MODE_PRIVATE).edit()
                                    .putString("data", data).commit()
                                if (!saved) throw IllegalStateException("Cannot persist course widget")
                                CourseWidgetProvider.refresh(context)
                                runOnUiThread { result.success(null) }
                            } catch (_: Exception) {
                                runOnUiThread { result.error("widget_sync", "Cannot update widget", null) }
                            }
                        }
                    }
                    "pin" -> {
                        val manager = AppWidgetManager.getInstance(this)
                        result.success(android.os.Build.VERSION.SDK_INT >= 26 &&
                            manager.isRequestPinAppWidgetSupported &&
                            manager.requestPinAppWidget(ComponentName(this,
                                CourseWidgetProvider::class.java), null, null))
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
