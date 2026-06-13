package com.example.safarsync_mobileapp

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Android Quick Settings tile that launches SafarSync and auto-starts the SOS countdown.
 *
 * TileService lifecycle:
 *   onStartListening  — tile panel is open; update tile appearance
 *   onClick           — user tapped the tile; launch app with SOS intent
 *   onStopListening   — tile panel closed; clean up if needed
 *
 * Requires API 24 (Android 7). Android silently ignores this service on older devices.
 */
class SosTileService : TileService() {

    companion object {
        const val ACTION_SOS_TILE = "com.example.safarsync_mobileapp.ACTION_SOS_TILE"
    }

    // ── Tile panel opened ─────────────────────────────────────────────────────
    override fun onStartListening() {
        super.onStartListening()
        qsTile?.apply {
            state = Tile.STATE_INACTIVE        // Not a toggle — always "off" (ready to fire)
            label = "SafarSync SOS"
            contentDescription = "Activate emergency SOS alert"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                subtitle = "Hold to confirm"
            }
            updateTile()
        }
    }

    // ── User tapped the tile ──────────────────────────────────────────────────
    override fun onClick() {
        super.onClick()

        // Briefly flash tile to "active" so the user gets visual feedback
        qsTile?.apply {
            state = Tile.STATE_ACTIVE
            label = "Opening SOS…"
            updateTile()
        }

        // unlockAndRun: if device is locked, prompt for authentication first.
        // The block runs on the main thread once the device is unlocked.
        unlockAndRun {
            launchApp()
        }
    }

    // ── Tile panel closed ─────────────────────────────────────────────────────
    override fun onStopListening() {
        super.onStopListening()
        // Reset label in case the tile stays in "active" state
        qsTile?.apply {
            state = Tile.STATE_INACTIVE
            label = "SafarSync SOS"
            updateTile()
        }
    }

    // ── Launch app with SOS intent ─────────────────────────────────────────────
    private fun launchApp() {
        val intent = Intent(applicationContext, MainActivity::class.java).apply {
            action = ACTION_SOS_TILE
            // SINGLE_TOP: if MainActivity is already on top, onNewIntent fires instead of onCreate
            // CLEAR_TOP: bring existing task to front rather than creating a new stack
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // API 34+: startActivityAndCollapse(Intent) is deprecated; must use PendingIntent
            val pendingIntent = PendingIntent.getActivity(
                applicationContext,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }
}
