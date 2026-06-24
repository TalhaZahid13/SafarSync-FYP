package com.example.safarsync_mobileapp

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    companion object {
        private const val SOS_CHANNEL = "com.example.safarsync_mobileapp/sos_tile"
    }

    // True when the last intent that opened/resumed this activity was the SOS tile.
    private var pendingSosFromTile = false

    // Kept so we can invoke Flutter methods after the engine is configured.
    private var sosMethodChannel: MethodChannel? = null

    // ── Activity lifecycle ────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkSosIntent(intent)
    }

    // Called when the activity is already running and a new intent arrives
    // (launchMode="singleTop" ensures this fires instead of a second onCreate).
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)          // update getIntent() so Flutter can read it later
        checkSosIntent(intent)
    }

    // ── Flutter engine ─────────────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sosMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SOS_CHANNEL,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    // Flutter asks on startup: was the app launched from the QS tile?
                    "hasPendingSOS" -> {
                        result.success(pendingSosFromTile)
                        pendingSosFromTile = false   // consume the flag
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun checkSosIntent(intent: Intent?) {
        if (intent?.action == SosTileService.ACTION_SOS_TILE) {
            pendingSosFromTile = true

            // If the Flutter engine is already running (warm start / onNewIntent),
            // push the triggerSOS method directly to Dart instead of waiting for
            // the "hasPendingSOS" poll.
            sosMethodChannel?.invokeMethod("triggerSOS", null)
        }
    }
}
