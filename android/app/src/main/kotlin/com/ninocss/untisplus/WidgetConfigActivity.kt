package com.ninocss.untisplus

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

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
        val surface = getColor(R.color.widget_surface)
        val surfaceVariant = getColor(R.color.widget_surface_variant)
        val onSurface = getColor(R.color.widget_on_surface)
        val onSurfaceVariant = getColor(R.color.widget_on_surface_variant)
        fun rounded(color: Int, radius: Int) = GradientDrawable().apply {
            setColor(color)
            cornerRadius = dp(radius).toFloat()
            setStroke(dp(1), surfaceVariant)
        }
        fun text(value: String, size: Float, color: Int, bold: Boolean = false) =
            TextView(this).apply {
                this.text = value
                textSize = size
                setTextColor(color)
                if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
            }
        val prefs = HomeWidgetPlugin.getData(this)
        val nativeCopy = try { JSONObject(prefs.getString("widget_native_copy", "{}") ?: "{}") } catch (_: Exception) { JSONObject() }
        fun copy(key: String, fallback: String) = nativeCopy.optString(key, fallback)

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(28), dp(24), dp(24))
            setBackgroundColor(surface)
        }
        root.addView(text(copy("setupTitle", "Widget einrichten"), 24f, onSurface, true))
        root.addView(text(copy("setupAccount", "Konto für dieses Widget"), 14f, onSurfaceVariant).apply {
            setPadding(0, dp(6), 0, dp(18))
        })

        val isCustomWidget = AppWidgetManager.getInstance(this)
            .getAppWidgetInfo(widgetId)?.provider?.className?.endsWith("UntisWidgetCustom") == true
        if (isCustomWidget) {
            val rawProfiles = prefs.getString("widget_configurations_v1", "[]") ?: "[]"
            val profiles = try { JSONArray(rawProfiles) } catch (_: Exception) { JSONArray() }
            root.addView(text(copy("setupProfile", "Widget-Profil"), 14f, onSurfaceVariant).apply {
                setPadding(0, dp(6), 0, dp(18))
            })
            if (profiles.length() == 0) {
                root.addView(text(copy("setupNoProfile", "Erstelle zuerst ein Profil im Untis+-Widget-Editor."), 15f, Color.rgb(100, 78, 62)))
            } else {
                for (index in 0 until profiles.length()) {
                    val item = profiles.optJSONObject(index) ?: continue
                    val profileId = item.optString("id")
                    if (profileId.isEmpty()) continue
                    val accountId = item.optString("accountId")
                    val row = LinearLayout(this).apply {
                        orientation = LinearLayout.VERTICAL
                        setPadding(dp(16), dp(14), dp(16), dp(14))
                        background = rounded(surface, 24)
                        isClickable = true
                        isFocusable = true
                        setOnClickListener { saveBinding(accountId, profileId) }
                    }
                    row.addView(text(item.optString("name", "Widget"), 17f, onSurface, true))
                    row.addView(text(copy("setupProfileHint", "Profil aus dem Widget-Editor"), 13f, Color.rgb(100, 78, 62)))
                    root.addView(row, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { bottomMargin = dp(12) })
                }
            }
            root.gravity = Gravity.TOP
            setContentView(ScrollView(this).apply { addView(root) })
            return
        }
        val raw = prefs.getString("widget_accounts", "[]") ?: "[]"
        val accounts = try { JSONArray(raw) } catch (_: Exception) { JSONArray() }
        val preferredAccount = prefs.getString("widget_preferred_account", null)
        if (accounts.length() == 0) {
            root.addView(text(copy("setupNoAccount", "Öffne Untis+ und füge zuerst ein Konto hinzu."), 15f, Color.rgb(100, 78, 62)))
        } else {
            val indices = (0 until accounts.length()).sortedBy { index ->
                if (accounts.optJSONObject(index)?.optString("id") == preferredAccount) 0 else 1
            }
            for (index in indices) {
                val item = accounts.optJSONObject(index) ?: continue
                val id = item.optString("id")
                if (id.isEmpty()) continue
                val isPreferred = id == preferredAccount
                val label = item.optString("label", "Untis+")
                val school = item.optString("school")
                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(18), dp(14), dp(18), dp(14))
                    background = rounded(
                        if (isPreferred) surfaceVariant else surface,
                        24,
                    )
                    isClickable = true
                    isFocusable = true
                    setOnClickListener { saveBinding(id) }
                }
                row.addView(text(
                    if (isPreferred) "$label  ✓" else label,
                    17f,
                    Color.rgb(65, 45, 32),
                    true,
                ))
                if (school.isNotEmpty()) row.addView(text(school, 13f, Color.rgb(100, 78, 62)))
                root.addView(row, LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { bottomMargin = dp(12) })
            }
        }
        root.gravity = Gravity.TOP
        setContentView(ScrollView(this).apply { addView(root) })
    }

    private fun saveBinding(accountId: String, configurationId: String? = null) {
        val prefs = HomeWidgetPlugin.getData(this)
        val editor = prefs.edit()
            .putString("widget_account_$widgetId", accountId)
            .remove("widget_preferred_account")
        (configurationId ?: prefs.getString("widget_preferred_configuration", null))?.let { selectedConfigurationId ->
            editor.putString("widget_configuration_$widgetId", selectedConfigurationId)
                .remove("widget_preferred_configuration")
        }
        editor.apply()
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
