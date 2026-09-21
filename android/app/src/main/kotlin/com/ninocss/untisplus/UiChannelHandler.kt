package com.ninocss.untisplus

import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

internal class UiChannelHandler(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) {
    private val channel = MethodChannel(messenger, NativeChannelContract.UI)

    fun register() {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setWindowBlur" -> {
                    applyWindowBlur((call.arguments as? Number)?.toInt() ?: 0)
                    result.success(null)
                }
                "setLauncherIcon" -> {
                    val icon = call.arguments as? String
                    result.success(icon?.let(::setLauncherIcon) ?: false)
                }
                "getSupportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                "installApk" -> {
                    val path = (call.arguments as? Map<*, *>)?.get("path") as? String
                    if (path.isNullOrBlank()) {
                        result.error("invalid_path", "No APK path supplied.", null)
                    } else {
                        installApk(path, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    fun openAssistant(query: String?) {
        channel.invokeMethod("openAssistant", query)
    }

    private fun applyWindowBlur(radius: Int) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            val method = activity.window.javaClass.getMethod(
                "setBackdropBlurRadius",
                Int::class.javaPrimitiveType,
            )
            method.invoke(activity.window, radius.coerceAtLeast(0))
        } catch (_: Exception) {
            // Some vendors omit the hidden blur API. Blur is an optional effect.
        }
    }

    private fun setLauncherIcon(icon: String): Boolean {
        val aliases = mapOf(
            "default" to ".IconDefault",
            "3d" to ".Icon3D",
            "chrom" to ".IconChrom",
            "galaxy" to ".IconGalaxy",
            "gradiant" to ".IconGradiant",
            "marmor" to ".IconMarmor",
            "paper" to ".IconPaper",
        )
        val target = aliases[icon] ?: return false
        aliases.values.forEach { alias ->
            activity.packageManager.setComponentEnabledSetting(
                ComponentName(activity.packageName, "${activity.packageName}$alias"),
                if (alias == target) PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
        return true
    }

    private fun installApk(path: String, result: MethodChannel.Result) {
        val updatesDirectory = File(activity.cacheDir, "updates").canonicalFile
        val apk = File(path).canonicalFile
        val isAllowedFile = apk.path.startsWith(updatesDirectory.path + File.separator) &&
            apk.isFile &&
            apk.name.endsWith(".apk", ignoreCase = true)
        if (!isAllowedFile) {
            result.error("invalid_path", "APK must be stored in the update cache.", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !activity.packageManager.canRequestPackageInstalls()
        ) {
            activity.startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:${activity.packageName}"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            result.success("permission")
            return
        }

        try {
            val uri = FileProvider.getUriForFile(
                activity,
                "${activity.packageName}.fileprovider",
                apk,
            )
            val intent = Intent(Intent.ACTION_VIEW)
                .setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            activity.startActivity(intent)
            result.success("installer")
        } catch (error: Exception) {
            result.error("installer_failed", error.message, null)
        }
    }
}
