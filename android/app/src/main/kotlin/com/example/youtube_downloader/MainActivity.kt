package com.example.youtube_downloader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NewPipeBridge.attachToEngine(flutterEngine.dartExecutor.binaryMessenger)
    }
}
