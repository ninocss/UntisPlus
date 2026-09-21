package com.ninocss.untisplus

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var nativeChannels: NativeChannelRegistry? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        nativeChannels = NativeChannelRegistry(this, flutterEngine).also { registry ->
            registry.register()
            registry.handleIntent(intent)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        nativeChannels?.handleIntent(intent)
    }

    @Deprecated("Deprecated in AndroidX Activity but required by FlutterActivity's current host API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        nativeChannels?.onActivityResult(requestCode, resultCode, data)
    }
}
