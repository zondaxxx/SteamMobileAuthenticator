package com.zondaxxx.steam_mobile_authenticator

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onResume() {
        super.onResume()
        // Live Steam Guard codes must not be visible in screenshots,
        // screen recordings or the recents app switcher.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
    }
}
