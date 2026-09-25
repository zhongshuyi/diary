package com.ling.diary

import android.content.Intent
import android.app.Activity
import android.content.pm.ShortcutInfo
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.content.pm.ShortcutManager
import android.graphics.drawable.Icon
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.util.ArrayDeque
import java.util.UUID

class MainActivity : FlutterFragmentActivity() {
    private val placeRequestCode = 7041
    private var pendingPlaceResult: MethodChannel.Result? = null
    private data class IncomingShare(val id: String, val text: String, val images: List<Uri>)

    private val pendingShares = ArrayDeque<IncomingShare>()
    private val pendingShortcuts = ArrayDeque<String>()
    private var shareChannel: MethodChannel? = null

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
            "longitude" to data.getDoubleExtra("longitude", 0.0)
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
