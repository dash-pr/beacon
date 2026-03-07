package com.tasuke.tasuke

import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.beacon.app/satellite"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isSatelliteMode" -> {
                    result.success(checkSatelliteMode())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkSatelliteMode(): Boolean {
        // NET_CAPABILITY_NOT_BANDWIDTH_CONSTRAINED = 35, defined in API 36
        // On API < 35, satellite mode detection is not supported
        if (Build.VERSION.SDK_INT < 35) return false

        try {
            val cm = getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false

            // Check if bandwidth is constrained (satellite indicator)
            // NET_CAPABILITY_NOT_BANDWIDTH_CONSTRAINED = 35
            val hasConstrainedBandwidth = !caps.hasCapability(35)

            // On API 36+, also check for satellite transport type (value 7)
            val hasSatelliteTransport = if (Build.VERSION.SDK_INT >= 36) {
                try {
                    caps.hasTransport(7) // TRANSPORT_SATELLITE = 7
                } catch (e: Exception) {
                    false
                }
            } else {
                false
            }

            return hasConstrainedBandwidth || hasSatelliteTransport
        } catch (e: Exception) {
            return false
        }
    }
}
