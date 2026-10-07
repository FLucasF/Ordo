package dev.lucasfelipe.task_manager

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var widgetChannel: MethodChannel? = null

    /** The calendar widget's tap that launched the app, until the app takes it. */
    private var widgetAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        widgetAction = intent?.getStringExtra(CalendarWidget.EXTRA_ACTION)
        // "tarefas/widget": the app redraws the home-screen calendar after writing its data, and takes
        // the tap that opened it (later taps arrive as "action").
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tarefas/widget").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "refresh" -> {
                        CalendarWidget.updateAll(applicationContext)
                        result.success(null)
                    }
                    "takeAction" -> {
                        result.success(widgetAction)
                        widgetAction = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.getStringExtra(CalendarWidget.EXTRA_ACTION)?.let { widgetChannel?.invokeMethod("action", it) }
    }
}
