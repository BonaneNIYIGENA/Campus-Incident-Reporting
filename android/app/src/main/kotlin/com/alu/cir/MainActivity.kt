package com.alu.cir

import android.os.Bundle
import android.os.SystemClock
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode

class MainActivity : FlutterActivity() {
    @Volatile
    private var flutterReady = false

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        super.onCreate(savedInstanceState)
        val started = SystemClock.uptimeMillis()
        // Hold the logo until Flutter shows its first frame, but never longer than four seconds.
        splash.setKeepOnScreenCondition {
            !flutterReady && SystemClock.uptimeMillis() - started < 4000
        }
    }

    // A texture view stays transparent until Flutter's first frame, so the launch drawable
    // (white with the logo) shows instead of a black surface.
    override fun getRenderMode(): RenderMode = RenderMode.texture

    override fun onFlutterUiDisplayed() {
        flutterReady = true
        super.onFlutterUiDisplayed()
    }
}
