package com.tri99er.opengo

import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "opengo/window"
        ).setMethodCallHandler { call, result ->
            if (call.method != "setFullscreen") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val fullscreen = call.arguments as? Boolean
            if (fullscreen == null) {
                result.error("invalid_argument", "Expected a fullscreen boolean", null)
                return@setMethodCallHandler
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                window.attributes = window.attributes.apply {
                    layoutInDisplayCutoutMode = if (fullscreen) {
                        android.view.WindowManager.LayoutParams
                            .LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
                    } else {
                        android.view.WindowManager.LayoutParams
                            .LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT
                    }
                }
                window.decorView.requestApplyInsets()
            }
            result.success(null)
        }
    }
}
