package com.caren.app.caren

import androidx.annotation.NonNull
import com.caren.app.caren.smartspectra.SmartSpectraBridge
import com.caren.app.caren.smartspectra.SmartSpectraCameraViewFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var smartSpectraBridge: SmartSpectraBridge? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val bridge = SmartSpectraBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        smartSpectraBridge = bridge

        // Register CameraX PreviewView platform view for SmartSpectra
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "com.caren.app/smartspectra_camera_view",
            SmartSpectraCameraViewFactory(bridge)
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        smartSpectraBridge?.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onPause() {
        super.onPause()
        smartSpectraBridge?.onPause()
    }

    override fun onResume() {
        super.onResume()
        smartSpectraBridge?.onResume()
    }

    override fun onDestroy() {
        smartSpectraBridge?.cleanup()
        super.onDestroy()
    }
}
