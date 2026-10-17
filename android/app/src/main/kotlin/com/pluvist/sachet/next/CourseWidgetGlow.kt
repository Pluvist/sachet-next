package com.pluvist.sachet.next

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.BlurMaskFilter
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.util.LruCache
import android.widget.RemoteViews

/** A fixed, softly blended blue/pink/cyan glow inspired by the welcome screen.
 * Rendered once per theme/aspect; never starts a ticker, service or extra alarm.
 */
internal object CourseWidgetGlow {
    private val images = object : LruCache<String, Bitmap>(4 * 1024 * 1024) {
        override fun sizeOf(key: String, value: Bitmap) = value.allocationByteCount
    }

    @Synchronized private fun image(dark: Boolean, wide: Boolean, widthDp: Int, heightDp: Int): Bitmap {
        val key = "$dark/$wide/$widthDp/$heightDp"
        images.get(key)?.let { return it }
        // Soft gradients need little resolution; keep each RemoteViews payload
        // comfortably below the Binder transaction budget, even on old Android.
        val width = 384
        val height = (width * heightDp / widthDp).coerceIn(96, 512)
        val sx = width.toFloat() / widthDp
        val sy = height.toFloat() / heightDp
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val outline = Path().apply { addRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()),
            28 * sx, 28 * sy, Path.Direction.CW) }
        canvas.clipPath(outline)
        canvas.drawColor(if (dark) 0xff191b22.toInt() else 0xfff8f9fe.toInt())
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        fun glow(x: Float, y: Float, radius: Float, color: Int, alpha: Int) {
            val cx = width * x; val cy = height * y; val r = width * radius
            val tint = Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
            paint.shader = RadialGradient(cx, cy, r, intArrayOf(tint, tint and 0x00ffffff),
                floatArrayOf(0f, 1f), Shader.TileMode.CLAMP)
            canvas.drawCircle(cx, cy, r, paint)
        }
        // Broad overlapping gradients retain a calm central area for text.
        glow(.1f, .9f, .70f, 0xff6674f5.toInt(), if (dark) 78 else 55)
        glow(.96f, .77f, .66f, 0xffef89c6.toInt(), if (dark) 65 else 48)
        glow(.64f, 1.16f, .60f, 0xff6ddbdc.toInt(), if (dark) 55 else 43)
        glow(.88f, -.18f, .65f, 0xff91a6fc.toInt(), if (dark) 25 else 26)
        // Directional rim like frosted glass: stronger at top-left and
        // bottom-right, quieter elsewhere. This is part of the static bitmap.
        val edge = Path().apply { addRoundRect(
            RectF(.7f * sx, .7f * sy, width - .7f * sx, height - .7f * sy),
            27.3f * sx, 27.3f * sy, Path.Direction.CW) }
        val colors = if (dark) intArrayOf(0xadcdddff.toInt(), 0x386c809e, 0x143e526c, 0x8fc5ddf7.toInt())
            else intArrayOf(0xe6ffffff.toInt(), 0x3d8b9abb, 0x1a7c8ca9, 0xb3ffffff.toInt())
        paint.shader = LinearGradient(0f, 0f, width.toFloat(), height.toFloat(),
            colors, floatArrayOf(0f, .36f, .65f, 1f), Shader.TileMode.CLAMP)
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 3.5f * sx
        paint.alpha = 80
        paint.maskFilter = BlurMaskFilter(2f * sx, BlurMaskFilter.Blur.NORMAL)
        canvas.drawPath(edge, paint)
        paint.maskFilter = null
        paint.alpha = 255
        paint.strokeWidth = .8f * sx
        canvas.drawPath(edge, paint)
        images.put(key, bitmap)
        return bitmap
    }

    fun apply(context: Context, view: RemoteViews, dark: Boolean, wide: Boolean, width: Int, height: Int) {
        view.setInt(R.id.widget_surface, "setBackgroundResource",
            if (dark) R.drawable.course_widget_dark else R.drawable.course_widget_light)
        view.setImageViewBitmap(R.id.widget_glow, image(dark, wide, maxOf(80, width), maxOf(60, height - 12)))
        val vertical = if (height - 12 < 120) 12 else 20
        if (wide) {
            val density = context.resources.displayMetrics.density
            fun dp(value: Int) = (value * density + .5f).toInt()
            view.setViewPadding(R.id.widget_content, dp(20), dp(vertical), dp(20), dp(vertical))
        }
    }
}
