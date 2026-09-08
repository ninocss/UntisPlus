package com.ninocss.untisplus

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/** Native companion for Android's widget picker. Flutter publishes only an
 * id/label catalog; no WebUntis credentials are read in this Activity. */
class WidgetConfigActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        widgetId = intent?.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
        }
        fun text(value: String, size: Float, color: Int, bold: Boolean = false) =
            TextView(this).apply {
                this.text = value
                textSize = size
                setTextColor(color)
                if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
            }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(28), dp(24), dp(24))
            setBackgroundColor(Color.rgb(255, 248, 242))
        }
        root.addView(text("Widget einrichten", 24f, Color.rgb(65, 45, 32), true))
        root.addView(text("Konto für dieses Widget", 14f, Color.rgb(100, 78, 62)).apply {
            setPadding(0, dp(6), 0, dp(18))
        })

        val prefs = HomeWidgetPlugin.getData(this)
        val raw = prefs.getString("widget_accounts", "[]") ?: "[]"
        val accounts = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        if (accounts.length() == 0) {
            root.addView(text("Öffne Untis+ und füge zuerst ein Konto hinzu.", 15f, Color.rgb(100, 78, 62)))
        } else {
            for (index in 0 until accounts.length()) {
                val item = accounts.optJSONObject(index) ?: continue
                val id = item.optString("id")
                if (id.isEmpty()) continue
                val label = item.optString("label", "Untis+")
                val school = item.optString("school")
                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(18), dp(14), dp(18), dp(14))
                    background = rounded(Color.WHITE, 28)
                    isClickable = true
                    isFocusable = true
                    setOnClickListener { saveBinding(id) }
                }
                row.addView(text(label, 17f, Color.rgb(65, 45, 32), true))
                if (school.isNotEmpty()) row.addView(text(school, 13f, Color.rgb(100, 78, 62)))
                root.addView(row, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { bottomMargin = dp(12) })
            }
        }
        root.gravity = Gravity.TOP
        setContentView(root)
    }

    private fun saveBinding(accountId: String) {
        HomeWidgetPlugin.getData(this).edit()
            .putString("widget_account_$widgetId", accountId)
            .apply()
        val manager = AppWidgetManager.getInstance(this)
        manager.getAppWidgetInfo(widgetId)?.provider?.let { provider ->
            sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                component = provider
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            })
        }
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }
}
