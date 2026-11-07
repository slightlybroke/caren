package com.caren.app.caren

import androidx.annotation.NonNull
import com.caren.app.caren.smartspectra.SmartSpectraBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var smartSpectraBridge: SmartSpectraBridge? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        smartSpectraBridge = SmartSpectraBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onDestroy() {
        smartSpectraBridge?.cleanup()
        super.onDestroy()
    }
}
