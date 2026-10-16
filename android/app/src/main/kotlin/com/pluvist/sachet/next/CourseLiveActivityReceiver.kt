package com.pluvist.sachet.next

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import java.util.concurrent.Executors

class CourseLiveActivityReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pending = goAsync()
        executor.execute {
            try {
                if (intent.action == CourseLiveActivity.DISMISS)
                    CourseLiveActivity.dismissToday(context, intent.getStringExtra("day"))
                else CourseLiveActivity.refresh(context)
            } finally { pending.finish() }
        }
    }
    companion object { private val executor = Executors.newSingleThreadExecutor() }
}
