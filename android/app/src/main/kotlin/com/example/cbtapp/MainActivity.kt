package com.example.cbtapp

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.cbtapp/screenPinning"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableScreenPinning" -> {
                    enableScreenPinning()
                    result.success(null)
                }
                "disableScreenPinning" -> {
                    disableScreenPinning()
                    result.success(null)
                }
                "bringToForeground" -> {
                    bringToForeground()
                    result.success(null)
                }
                "exitApp" -> {
                    exitApp()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)

    }

    private fun enableScreenPinning() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val activity: Activity = this
            val params = activity.window.attributes
            params.flags = params.flags or android.view.WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            activity.window.attributes = params
            activity.startLockTask()
        }
    }

    private fun disableScreenPinning() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val activity: Activity = this
            activity.stopLockTask()
        }
    }

    private fun bringToForeground() {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val appTasks = activityManager.appTasks
        if (appTasks.isNotEmpty()) {
            appTasks[0].moveToFront()
        }
    }

    private fun exitApp() {
        disableScreenPinning()
        finishAffinity()
    }

    override fun onUserLeaveHint(){
        super.onUserLeaveHint()
        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("showWarning", null)
    }
}
