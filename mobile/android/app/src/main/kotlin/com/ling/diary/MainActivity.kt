package com.ling.diary

import android.content.Intent
import android.app.Activity
import android.content.pm.ShortcutInfo
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.SystemClock
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.BufferedOutputStream
import java.nio.ByteOrder
import java.util.ArrayDeque
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
    private val placeRequestCode = 7041
    private var pendingPlaceResult: MethodChannel.Result? = null
    private data class IncomingShare(val id: String, val text: String, val images: List<Uri>)

    private val pendingShares = ArrayDeque<IncomingShare>()
    private val pendingShortcuts = ArrayDeque<String>()
    private var shareChannel: MethodChannel? = null
    private val audioDecodes = ConcurrentHashMap<String, AtomicBoolean>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerShortcuts()
        captureShare(intent)
        captureShortcut(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        captureShare(intent)
        captureShortcut(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ling.diary/offline_transcription")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCapabilities" -> {
                        result.success(mapOf(
                            "supported" to (Build.VERSION.SDK_INT >= 27 && android.os.Process.is64Bit()),
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "minSdkInt" to 27,
                            "abi" to Build.SUPPORTED_ABIS.firstOrNull()
                        ))
                    }
                    "cancelDecode" -> {
                        (call.arguments as? String)?.let { audioDecodes[it]?.set(true) }
                        result.success(null)
                    }
                    "releaseDecodedAudio" -> {
                        val path = call.arguments as? String
                        try {
                            if (path != null) {
                                val file = File(path).canonicalFile
                                val directory = File(cacheDir, "offline-transcription").canonicalFile
                                if (file.parentFile == directory && file.name.startsWith("decoded-")) {
                                    file.delete()
                                }
                            }
                            result.success(null)
                        } catch (_: Exception) {
                            result.error("AUDIO_CACHE_ERROR", "Unable to clean decoded audio", null)
                        }
                    }
                    "decodeToPcm16" -> {
                        val arguments = call.arguments as? Map<*, *>
                        val path = arguments?.get("audioPath") as? String
                        val requestId = arguments?.get("requestId") as? String
                        if (path.isNullOrEmpty() || requestId.isNullOrEmpty()) {
                            result.error("AUDIO_INVALID", "Invalid audio request", null)
                            return@setMethodCallHandler
                        }
                        val cancelled = AtomicBoolean(false)
                        synchronized(audioDecodes) {
                            if (audioDecodes.isNotEmpty()) {
                                result.error("AUDIO_BUSY", "Another recording is being decoded", null)
                                return@setMethodCallHandler
                            }
                            audioDecodes[requestId] = cancelled
                        }
                        Thread {
                            try {
                                val decoded = decodeAudioToPcm16(path, cancelled)
                                runOnUiThread {
                                    audioDecodes.remove(requestId)
                                    if (cancelled.get()) {
                                        File(decoded.path).delete()
                                        result.error("AUDIO_CANCELLED", "Audio decoding cancelled", null)
                                    } else {
                                        result.success(mapOf(
                                            "pcmPath" to decoded.path,
                                            "sampleRate" to 16000,
                                            "samples" to decoded.samples
                                        ))
                                    }
                                }
                            } catch (error: Exception) {
                                val code = if (error is AudioDecodeFailure) error.code else "AUDIO_DECODE_FAILED"
                                runOnUiThread {
                                    audioDecodes.remove(requestId)
                                    result.error(code, "Unable to decode local recording", null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ling.diary/local_assistant")
            .setMethodCallHandler { call, result ->
                if (call.method != "capabilities") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(mapOf(
                    "supported" to (Build.VERSION.SDK_INT >= 29 && android.os.Process.is64Bit()),
                    "sdkInt" to Build.VERSION.SDK_INT,
                    "abi" to Build.SUPPORTED_ABIS.firstOrNull()
                ))
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ling.diary/amap_location")
            .setMethodCallHandler { call, result ->
                if (call.method != "pickPlace" && call.method != "showPlace") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val arguments = call.arguments as? Map<*, *>
                val key = (arguments?.get("key") as? String).orEmpty().trim()
                if (key.isEmpty()) {
                    result.error("NO_KEY", "请先配置高德 Android Key", null)
                    return@setMethodCallHandler
                }
                if (pendingPlaceResult != null) {
                    result.error("BUSY", "位置选择正在进行中", null)
                    return@setMethodCallHandler
                }
                val placeIntent = Intent(this, AmapPlaceActivity::class.java).apply {
                    putExtra("key", key)
                    putExtra("viewOnly", call.method == "showPlace")
                    putExtra("name", arguments?.get("name") as? String)
                    putExtra("address", arguments?.get("address") as? String)
                    putExtra("latitude", (arguments?.get("latitude") as? Number)?.toDouble())
                    putExtra("longitude", (arguments?.get("longitude") as? Number)?.toDouble())
                    for (colorKey in listOf("paperColor", "surfaceColor", "inkColor",
                        "mutedColor", "lineColor", "accentColor", "accentSoftColor", "onAccentColor")) {
                        (arguments?.get(colorKey) as? Number)?.toInt()?.let { putExtra(colorKey, it) }
                    }
                    putExtra("darkTheme", arguments?.get("darkTheme") as? Boolean ?: false)
                    putExtra("includeThumbnail", arguments?.get("includeThumbnail") as? Boolean ?: true)
                }
                try {
                    pendingPlaceResult = result
                    @Suppress("DEPRECATION")
                    startActivityForResult(placeIntent, placeRequestCode)
                } catch (error: Exception) {
                    pendingPlaceResult = null
                    result.error("OPEN_FAILED", error.message, null)
                }
            }
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.ling.diary/incoming_share")
        shareChannel?.setMethodCallHandler { call, result ->
            if (call.method == "takePendingShortcut") {
                result.success(synchronized(pendingShortcuts) {
                    if (pendingShortcuts.isEmpty()) null else pendingShortcuts.removeFirst()
                })
                return@setMethodCallHandler
            }
            if (call.method == "completePendingShare") {
                val id = call.arguments as? String
                synchronized(pendingShares) {
                    if (pendingShares.peekFirst()?.id == id) pendingShares.removeFirst()
                }
                result.success(null)
                return@setMethodCallHandler
            }
            if (call.method != "takePendingShare") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val share = synchronized(pendingShares) { pendingShares.peekFirst() }
            if (share == null) {
                result.success(null)
                return@setMethodCallHandler
            }
            Thread {
                try {
                    val imagePaths = share.images.map(::copyImageToCache)
                    runOnUiThread {
                        result.success(mapOf("id" to share.id, "text" to share.text, "imagePaths" to imagePaths))
                    }
                } catch (error: Exception) {
                    runOnUiThread {
                        result.error("SHARE_IMPORT_FAILED", "无法读取分享的图片", null)
                    }
                }
            }.start()
        }
    }

    override fun onDestroy() {
        audioDecodes.values.forEach { it.set(true) }
        super.onDestroy()
    }

    private class AudioDecodeFailure(val code: String) : Exception(code)
    private data class DecodedAudio(val path: String, val samples: Int)

    /** MediaCodec decoding and resampling run only on the caller's worker thread. */
    private fun decodeAudioToPcm16(path: String, cancelled: AtomicBoolean): DecodedAudio {
        val source = File(path)
        if (!source.isFile || source.length() <= 0L) throw AudioDecodeFailure("AUDIO_INVALID")
        if (source.length() > 50L * 1024 * 1024) throw AudioDecodeFailure("AUDIO_TOO_LARGE")
        val directory = File(cacheDir, "offline-transcription").apply { mkdirs() }
        // Crash leftovers contain only decoded local audio; keep no long-lived copy.
        val staleBefore = System.currentTimeMillis() - 24L * 60 * 60 * 1000
        directory.listFiles()?.filter { it.name.startsWith("decoded-") && it.lastModified() < staleBefore }
            ?.forEach { it.delete() }
        val destination = File.createTempFile("decoded-", ".pcm", directory)
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        var successful = false
        try {
            extractor.setDataSource(source.absolutePath)
            val track = (0 until extractor.trackCount).firstOrNull {
                extractor.getTrackFormat(it).getString(MediaFormat.KEY_MIME)?.startsWith("audio/") == true
            } ?: throw AudioDecodeFailure("AUDIO_UNSUPPORTED")
            val format = extractor.getTrackFormat(track)
            if (format.containsKey(MediaFormat.KEY_DURATION) &&
                format.getLong(MediaFormat.KEY_DURATION) > 180L * 1_000_000) {
                throw AudioDecodeFailure("AUDIO_TOO_LONG")
            }
            var sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
            var channels = format.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
            var encoding = AudioFormat.ENCODING_PCM_16BIT
            validatePcmFormat(sampleRate, channels, encoding)
            extractor.selectTrack(track)
            val codec = MediaCodec.createDecoderByType(format.getString(MediaFormat.KEY_MIME)!!)
            decoder = codec
            codec.configure(format, null, null, 0)
            codec.start()
            val info = MediaCodec.BufferInfo()
            var inputEnded = false
            var outputEnded = false
            val started = SystemClock.elapsedRealtime()
            var lastOutput = started
            var resampler: Pcm16Resampler? = null
            BufferedOutputStream(FileOutputStream(destination), 64 * 1024).use { output ->
                while (!outputEnded) {
                    if (cancelled.get()) throw AudioDecodeFailure("AUDIO_CANCELLED")
                    val now = SystemClock.elapsedRealtime()
                    if (now - started > 120_000L || now - lastOutput > 20_000L) {
                        throw AudioDecodeFailure("AUDIO_TIMEOUT")
                    }
                    if (!inputEnded) {
                        val inputIndex = codec.dequeueInputBuffer(10_000)
                        if (inputIndex >= 0) {
                            val input = codec.getInputBuffer(inputIndex)
                                ?: throw AudioDecodeFailure("AUDIO_DECODE_FAILED")
                            input.clear()
                            val count = extractor.readSampleData(input, 0)
                            if (count < 0) {
                                codec.queueInputBuffer(inputIndex, 0, 0, 0L, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                                inputEnded = true
                            } else {
                                codec.queueInputBuffer(inputIndex, 0, count, extractor.sampleTime, 0)
                                extractor.advance()
                            }
                        }
                    }
                    val outputIndex = codec.dequeueOutputBuffer(info, 10_000)
                    if (outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        val actual = codec.outputFormat
                        sampleRate = actual.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        channels = actual.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                        encoding = if (actual.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                            actual.getInteger(MediaFormat.KEY_PCM_ENCODING)
                        } else AudioFormat.ENCODING_PCM_16BIT
                        validatePcmFormat(sampleRate, channels, encoding)
                        if (resampler != null && resampler!!.inputSampleRate != sampleRate) {
                            throw AudioDecodeFailure("AUDIO_UNSUPPORTED")
                        }
                    } else if (outputIndex >= 0) {
                        try {
                            val buffer = codec.getOutputBuffer(outputIndex)
                                ?: throw AudioDecodeFailure("AUDIO_DECODE_FAILED")
                            if (info.size > 0) {
                                lastOutput = SystemClock.elapsedRealtime()
                                val active = resampler ?: Pcm16Resampler(sampleRate, output).also { resampler = it }
                                val bytesPerSample = if (encoding == AudioFormat.ENCODING_PCM_FLOAT) 4 else 2
                                if (info.size % (channels * bytesPerSample) != 0) {
                                    throw AudioDecodeFailure("AUDIO_INVALID")
                                }
                                buffer.position(info.offset)
                                buffer.limit(info.offset + info.size)
                                buffer.order(ByteOrder.LITTLE_ENDIAN)
                                val frames = info.size / (channels * bytesPerSample)
                                for (frame in 0 until frames) {
                                    if ((frame and 4095) == 0 && cancelled.get()) {
                                        throw AudioDecodeFailure("AUDIO_CANCELLED")
                                    }
                                    var mono = 0.0
                                    for (channel in 0 until channels) {
                                        val sample = if (encoding == AudioFormat.ENCODING_PCM_FLOAT) {
                                            buffer.float.toDouble()
                                        } else buffer.short.toDouble() / 32768.0
                                        mono += if (sample.isFinite()) sample.coerceIn(-1.0, 1.0) else 0.0
                                    }
                                    active.accept(mono / channels)
                                }
                            }
                            if ((info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0) outputEnded = true
                        } finally {
                            codec.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
            }
            if (cancelled.get()) throw AudioDecodeFailure("AUDIO_CANCELLED")
            val samples = resampler?.writtenSamples ?: 0
            if (samples <= 0) throw AudioDecodeFailure("AUDIO_INVALID")
            successful = true
            return DecodedAudio(destination.absolutePath, samples)
        } finally {
            try { decoder?.stop() } catch (_: Exception) {}
            try { decoder?.release() } catch (_: Exception) {}
            extractor.release()
            if (!successful) destination.delete()
        }
    }

    private fun validatePcmFormat(rate: Int, channels: Int, encoding: Int) {
        if (rate !in 8000..96000 || channels !in 1..8 ||
            (encoding != AudioFormat.ENCODING_PCM_16BIT && encoding != AudioFormat.ENCODING_PCM_FLOAT)) {
            throw AudioDecodeFailure("AUDIO_UNSUPPORTED")
        }
    }

    private class Pcm16Resampler(val inputSampleRate: Int, private val output: BufferedOutputStream) {
        private var frames = 0L
        private var previous = 0.0
        private var nextSample = 0.0
        private val step = inputSampleRate.toDouble() / 16000.0
        var writtenSamples = 0
            private set

        fun accept(current: Double) {
            if (frames >= inputSampleRate * 180L) throw AudioDecodeFailure("AUDIO_TOO_LONG")
            while (nextSample <= frames.toDouble()) {
                if (writtenSamples >= 16000 * 180) throw AudioDecodeFailure("AUDIO_TOO_LONG")
                val mixed = if (frames == 0L) current else {
                    val fraction = (nextSample - (frames - 1)).coerceIn(0.0, 1.0)
                    previous + (current - previous) * fraction
                }
                val value = (mixed.coerceIn(-1.0, 1.0) * 32768.0).toInt().coerceIn(-32768, 32767)
                output.write(value and 255)
                output.write((value shr 8) and 255)
                writtenSamples++
                nextSample += step
            }
            previous = current
            frames++
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != placeRequestCode) return
        val pending = pendingPlaceResult ?: return
        pendingPlaceResult = null
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending.success(null)
            return
        }
        pending.success(mapOf(
            "name" to data.getStringExtra("name"),
            "address" to data.getStringExtra("address"),
            "latitude" to data.getDoubleExtra("latitude", 0.0),
            "longitude" to data.getDoubleExtra("longitude", 0.0),
            "thumbnailPath" to data.getStringExtra("thumbnailPath")
        ))
    }

    private fun registerShortcuts() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N_MR1) return
        val manager = getSystemService(ShortcutManager::class.java) ?: return
        fun shortcut(id: String, label: String, action: String, icon: Int, rank: Int): ShortcutInfo =
            ShortcutInfo.Builder(this, id)
                .setShortLabel(label)
                .setLongLabel(label)
                .setIcon(Icon.createWithResource(this, icon))
                .setIntent(Intent(this, MainActivity::class.java).apply {
                    this.action = action
                    addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                })
                .setRank(rank)
                .build()
        manager.dynamicShortcuts = listOf(
            shortcut("quick-capture", "快速记录", "com.ling.diary.action.QUICK_CAPTURE", R.drawable.ic_shortcut_quick_capture, 0),
            shortcut("open-chat", "打开对话", "com.ling.diary.action.OPEN_CHAT", R.drawable.ic_shortcut_chat, 1),
            shortcut("new-entry", "写完整日记", "com.ling.diary.action.NEW_ENTRY", R.drawable.ic_shortcut_new_entry, 2),
        )
    }

    private fun captureShortcut(intent: Intent?) {
        val shortcut = when (intent?.action) {
            "com.ling.diary.action.QUICK_CAPTURE" -> "quick-capture"
            "com.ling.diary.action.OPEN_CHAT" -> "open-chat"
            "com.ling.diary.action.NEW_ENTRY" -> "new-entry"
            else -> null
        } ?: return
        synchronized(pendingShortcuts) { pendingShortcuts.addLast(shortcut) }
        shareChannel?.invokeMethod("shortcutAvailable", null)
    }

    @Suppress("DEPRECATION")
    private fun captureShare(intent: Intent?) {
        if (intent == null ||
            (intent.action != Intent.ACTION_SEND && intent.action != Intent.ACTION_SEND_MULTIPLE)) return

        val text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString().orEmpty()
        val images = if (intent.action == Intent.ACTION_SEND_MULTIPLE) {
            intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty()
        } else {
            listOfNotNull(intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM))
        }.filter { uri -> (contentResolver.getType(uri) ?: intent.type.orEmpty()).startsWith("image/") }
        if (text.isBlank() && images.isEmpty()) return
        synchronized(pendingShares) { pendingShares.addLast(IncomingShare(UUID.randomUUID().toString(), text, images)) }
        shareChannel?.invokeMethod("shareAvailable", null)
    }

    private fun copyImageToCache(uri: Uri): String {
        val mime = contentResolver.getType(uri).orEmpty()
        val extension = when (mime) {
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            "image/gif" -> ".gif"
            "image/bmp" -> ".bmp"
            else -> ".jpg"
        }
        val directory = File(cacheDir, "incoming-shares").apply { mkdirs() }
        val destination = File.createTempFile("shared-", extension, directory)
        try {
            val source = contentResolver.openInputStream(uri)
                ?: throw IllegalArgumentException("Shared image is unavailable")
            source.use { input ->
                FileOutputStream(destination).use { output ->
                    val buffer = ByteArray(64 * 1024)
                    var copied = 0L
                    while (true) {
                        val count = input.read(buffer)
                        if (count < 0) break
                        copied += count
                        if (copied > 128L * 1024 * 1024) {
                            throw IllegalArgumentException("Shared image is too large")
                        }
                        output.write(buffer, 0, count)
                    }
                }
            }
            return destination.absolutePath
        } catch (error: Exception) {
            destination.delete()
            throw error
        }
    }
}
