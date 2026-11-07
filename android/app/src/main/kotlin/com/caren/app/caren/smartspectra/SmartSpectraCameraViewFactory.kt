package com.caren.app.caren.smartspectra

import android.content.Context
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Factory for creating [SmartSpectraCameraPlatformView] instances requested by Flutter.
 */
class SmartSpectraCameraViewFactory(
    private val bridge: SmartSpectraBridge
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val platformView = SmartSpectraCameraPlatformView(context)
        bridge.registerCameraPlatformView(platformView)
        return platformView
    }
}

