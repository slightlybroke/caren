// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class WebCameraPreviewWidget extends StatefulWidget {
  const WebCameraPreviewWidget({super.key});

  @override
  State<WebCameraPreviewWidget> createState() => _WebCameraPreviewWidgetState();
}

class _WebCameraPreviewWidgetState extends State<WebCameraPreviewWidget> {
  static int _viewIdCounter = 0;
  late final String _viewType;
  html.MediaStream? _mediaStream;
  html.VideoElement? _videoElement;
  bool _hasPermissionError = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'caren_web_camera_view_${_viewIdCounter++}';
    _videoElement = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..style.transform = 'scaleX(-1)'; // Mirror for front-facing camera preview

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => _videoElement!,
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _hasPermissionError = false);
    try {
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });
      if (stream != null && mounted) {
        _mediaStream = stream;
        _videoElement?.srcObject = stream;
        setState(() => _hasPermissionError = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasPermissionError = true);
      }
    }
  }

  @override
  void dispose() {
    _mediaStream?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        HtmlElementView(viewType: _viewType),
        if (_hasPermissionError && _mediaStream == null)
          Positioned(
            bottom: 12,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _initCamera,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white30, width: 0.8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Allow Camera Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget createWebCameraPreview() => const WebCameraPreviewWidget();
