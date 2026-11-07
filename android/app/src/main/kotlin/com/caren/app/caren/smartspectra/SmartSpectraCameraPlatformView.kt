package com.caren.app.caren.smartspectra

import android.content.Context
import android.view.View
import androidx.camera.view.PreviewView
import com.presagetech.smartspectra.SmartSpectraSdk
import io.flutter.plugin.platform.PlatformView

/**
 * Android PlatformView hosting CameraX [PreviewView] embedded in Flutter.
 * Connects directly to SmartSpectra SDK 3.4.0 camera preview pipeline via
 * `sdk.config.previewSurfaceProvider = previewView.surfaceProvider`.
 */
class SmartSpectraCameraPlatformView(
    context: Context
) : PlatformView {
    private val previewView: PreviewView = PreviewView(context).apply {
        implementationMode = PreviewView.ImplementationMode.COMPATIBLE
    }

    init {
        try {
            SmartSpectraSdk.shared.config.previewSurfaceProvider = previewView.surfaceProvider
        } catch (_: Exception) {
            // SDK might not be initialized yet; bridge will wire when started
        }
    }

    fun attachToSdk() {
        try {
            SmartSpectraSdk.shared.config.previewSurfaceProvider = previewView.surfaceProvider
        } catch (_: Exception) {}
    }

    fun detachFromSdk() {
        try {
            if (SmartSpectraSdk.shared.config.previewSurfaceProvider == previewView.surfaceProvider) {
                SmartSpectraSdk.shared.config.previewSurfaceProvider = null
            }
        } catch (_: Exception) {}
    }

    override fun getView(): View {
        return previewView
    }

    override fun dispose() {
        detachFromSdk()
    }
}

