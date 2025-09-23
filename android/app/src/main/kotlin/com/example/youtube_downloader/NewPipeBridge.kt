package com.example.youtube_downloader

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.BinaryMessenger
import okhttp3.OkHttpClient
import okhttp3.Request as OkRequest
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ExtractionException
import org.schabi.newpipe.extractor.localization.Localization
import java.io.IOException
import java.nio.charset.Charset
import java.util.concurrent.TimeUnit

class OkHttpDownloader : Downloader() {
    private val client: OkHttpClient = OkHttpClient.Builder()
        .followRedirects(true)
        .followSslRedirects(true)
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    override fun execute(request: Request): Response {
        val builder = OkRequest.Builder().url(request.url())
        when (request.httpMethod()) {
            "GET" -> builder.get()
            "HEAD" -> builder.head()
            "POST" -> {
                val data = request.dataToSend() ?: ByteArray(0)
                builder.post(okhttp3.RequestBody.create(null, data))
            }
            else -> builder.get()
        }
        // headers provided by Request already include localization if set
        request.headers().forEach { (key, values) ->
            values.forEach { v -> builder.addHeader(key, v) }
        }

        val resp = client.newCall(builder.build()).execute()
        val headersMap = mutableMapOf<String, List<String>>()
        resp.headers.names().forEach { name ->
            headersMap[name] = resp.headers.values(name)
        }
        val bodyStr = resp.body?.string()
        val latestUrl = resp.request.url.toString()
        return Response(resp.code, resp.message, headersMap, bodyStr, latestUrl)
    }
}

object NewPipeBridge: MethodChannel.MethodCallHandler {
    private const val CHANNEL = "com.example.youtube_downloader/newpipe"
    private var channel: MethodChannel? = null
    private var initialized = false

    fun attachTo(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (channel == null) {
            channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
            channel?.setMethodCallHandler(this)
        }
        if (!initialized) {
            try {
                NewPipe.init(OkHttpDownloader(), Localization.DEFAULT)
                initialized = true
            } catch (e: Exception) {
                Log.e("NewPipeBridge", "Init error", e)
            }
        }
    }

    fun attachToEngine(messenger: BinaryMessenger) {
        if (channel == null) {
            channel = MethodChannel(messenger, CHANNEL)
            channel?.setMethodCallHandler(this)
        }
        if (!initialized) {
            try {
                NewPipe.init(OkHttpDownloader(), Localization.DEFAULT)
                initialized = true
            } catch (e: Exception) {
                Log.e("NewPipeBridge", "Init error", e)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getVideoInfo" -> {
                val url = call.argument<String>("url") ?: return result.error("ARG", "url is required", null)
                Thread {
                    try {
                        val service = NewPipe.getServiceByUrl(url)
                        val handler = service.streamLHFactory.fromUrl(url)
                        val extractor = service.getStreamExtractor(handler)
                        extractor.fetchPage()
                        val thumbs = try { extractor.thumbnails } catch (e: Exception) { emptyList() }
                        val thumbUrl = thumbs.firstOrNull()?.url ?: ""
                        val info = mapOf(
                            "id" to extractor.id,
                            "title" to extractor.name,
                            "author" to (extractor.uploaderName ?: ""),
                            "thumbnailUrl" to thumbUrl,
                            // Format upload date to ISO string if available
                            "uploadDate" to (try { extractor.uploadDate?.offsetDateTime()?.toString() } catch (e: Exception) { null } ?: "")
                        )
                        result.success(info)
                    } catch (e: Exception) {
                        Log.e("NewPipeBridge", "getVideoInfo failed", e)
                        result.error("ERR", "${e::class.simpleName}: ${e.message}", Log.getStackTraceString(e))
                    }
                }.start()
            }
            "getStreams" -> {
                val url = call.argument<String>("url") ?: return result.error("ARG", "url is required", null)
                Thread {
                    try {
                        val service = NewPipe.getServiceByUrl(url)
                        val handler = service.streamLHFactory.fromUrl(url)
                        val extractor = service.getStreamExtractor(handler)
                        extractor.fetchPage()
                        val streams = mutableListOf<Map<String, Any?>>()
                        fun extFromMime(mime: String): String {
                            val lower = mime.lowercase()
                            return when {
                                lower.contains("mp4") && lower.contains("audio") && lower.contains("mpeg") -> "m4a"
                                lower.contains("m4a") -> "m4a"
                                lower.contains("webm") && lower.contains("audio") -> "webm"
                                lower.contains("webm") && lower.contains("video") -> "webm"
                                lower.contains("mp4") -> "mp4"
                                else -> "mp4"
                            }
                        }
                        // Muxed (audio+video)
                        extractor.videoStreams.forEach { vs ->
                            val mime = vs.format?.mimeType ?: ""
                            streams.add(
                                mapOf(
                                    "url" to vs.url,
                                    "format" to mime,
                                    "quality" to vs.resolution,
                                    "isVideoOnly" to false,
                                    "isAudioOnly" to false,
                                    "fileExtension" to extFromMime(mime)
                                )
                            )
                        }
                        // Video-only
                        extractor.videoOnlyStreams.forEach { vo ->
                            val mime = vo.format?.mimeType ?: ""
                            streams.add(
                                mapOf(
                                    "url" to vo.url,
                                    "format" to mime,
                                    "quality" to (vo.resolution ?: ""),
                                    "isVideoOnly" to true,
                                    "isAudioOnly" to false,
                                    "fileExtension" to extFromMime(mime)
                                )
                            )
                        }
                        // Audio-only
                        extractor.audioStreams.forEach { ao ->
                            val mime = ao.format?.mimeType ?: ""
                            streams.add(
                                mapOf(
                                    "url" to ao.url,
                                    "format" to mime,
                                    "quality" to (ao.averageBitrate ?: 0),
                                    "isVideoOnly" to false,
                                    "isAudioOnly" to true,
                                    "fileExtension" to extFromMime(mime)
                                )
                            )
                        }
                        result.success(streams)
                    } catch (e: Exception) {
                        Log.e("NewPipeBridge", "getStreams failed", e)
                        result.error("ERR", "${e::class.simpleName}: ${e.message}", Log.getStackTraceString(e))
                    }
                }.start()
            }
            else -> result.notImplemented()
        }
    }
}
