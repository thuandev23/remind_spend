package com.example.remind_spend.bridge

import android.database.ContentObserver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import com.example.remind_spend.config.BankRule
import com.example.remind_spend.config.RegexConfigLoader
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.RegexConfigEntry
import com.example.remind_spend.security.SecurityManager
import org.json.JSONArray
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class NativeBridgePlugin(
    private val context: Context,
    methodChannel: MethodChannel,
    eventChannel: EventChannel
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        const val METHOD_CHANNEL = "com.example.remind_spend/transaction_bridge"
        const val EVENT_CHANNEL  = "com.example.remind_spend/permission_status"
        private const val TAG    = "NativeBridgePlugin"
    }

    private val job   = SupervisorJob()
    private val scope = CoroutineScope(job + Dispatchers.Main)

    private val securityManager by lazy { SecurityManager() }
    private val db by lazy {
        AppDatabase.getInstance(context.applicationContext, securityManager.getDatabasePassphrase())
    }

    private var permissionObserver: ContentObserver? = null

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    // ── MethodChannel ────────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAndClearQueue"                 -> handleGetAndClearQueue(result)
            "checkPermissionStatus"            -> result.success(permissionStatus())
            "requestPermission"                -> handleRequestPermission(result)
            "getManufacturerInfo"              -> handleGetManufacturerInfo(result)
            "checkBatteryOptimization"         -> result.success(isBatteryOptimizationIgnored())
            "requestBatteryOptimizationWhitelist" -> handleRequestBatteryWhitelist(result)
            "clearIdempotencyCache"            -> handleClearIdempotencyCache(result)
            "updateRegexConfig"                -> handleUpdateRegexConfig(call, result)
            else                               -> result.notImplemented()
        }
    }

    private fun handleGetAndClearQueue(result: MethodChannel.Result) {
        scope.launch {
            runCatching {
                val items = withContext(Dispatchers.IO) { db.pendingTransactionDao().dequeueAll() }
                items.map { tx ->
                    mapOf(
                        "id"           to tx.id,
                        "package_name" to tx.packageName,
                        "bank_id"      to tx.bankId,
                        "amount_vnd"   to tx.rawAmount,
                        "sign"         to tx.sign,
                        "timestamp_ms" to tx.timestampMs,
                        "created_at"   to tx.createdAt
                    )
                }
            }.fold(
                onSuccess  = { result.success(it) },
                onFailure  = { e ->
                    Log.e(TAG, "getAndClearQueue failed", e)
                    result.error("DB_ERROR", e.message, null)
                }
            )
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        runCatching {
            context.startActivity(
                Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            )
            result.success(true)
        }.onFailure { e ->
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun handleGetManufacturerInfo(result: MethodChannel.Result) {
        val manufacturer = Build.MANUFACTURER.lowercase()
        val type = when {
            getSystemProperty("ro.miui.ui.version.name").isNotEmpty()  -> "miui"
            manufacturer == "samsung"                                   -> "oneui"
            getSystemProperty("ro.build.version.opporom").isNotEmpty() -> "coloros"
            else                                                        -> "stock"
        }
        result.success(mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model"        to Build.MODEL,
            "type"         to type
        ))
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        val pm = context.getSystemService(PowerManager::class.java)
        return pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    private fun handleRequestBatteryWhitelist(result: MethodChannel.Result) {
        runCatching {
            context.startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            )
            result.success(null)
        }.onFailure { e ->
            result.error("SETTINGS_ERROR", e.message, null)
        }
    }

    private fun handleClearIdempotencyCache(result: MethodChannel.Result) {
        scope.launch {
            runCatching {
                withContext(Dispatchers.IO) { db.idempotencyCacheDao().purgeExpired(0L) }
            }.fold(
                onSuccess  = { result.success(null) },
                onFailure  = { e ->
                    Log.e(TAG, "clearIdempotencyCache failed", e)
                    result.error("DB_ERROR", e.message, null)
                }
            )
        }
    }

    private fun handleUpdateRegexConfig(call: MethodCall, result: MethodChannel.Result) {
        val rulesRaw = call.arguments as? List<*> ?: run {
            result.error("INVALID_ARGS", "Expected list of rule maps", null)
            return
        }
        scope.launch {
            runCatching {
                val rules = rulesRaw.mapNotNull { item ->
                    val map = item as? Map<*, *> ?: return@mapNotNull null
                    val bankId = map["bank_id"] as? String ?: return@mapNotNull null
                    val packageNames = (map["package_names"] as? List<*>)
                        ?.mapNotNull { it as? String } ?: emptyList()
                    val patterns = (map["patterns"] as? List<*>)
                        ?.mapNotNull { it as? String } ?: emptyList()
                    val amountGroup = (map["amount_group"] as? Int) ?: 1
                    val sign = map["sign"] as? String ?: "debit"
                    BankRule(bankId, packageNames, patterns, amountGroup, sign)
                }
                RegexConfigLoader.updateActiveRules(rules)
                val nowMs = System.currentTimeMillis()
                withContext(Dispatchers.IO) {
                    for (rule in rules) {
                        db.regexConfigDao().upsert(
                            RegexConfigEntry(
                                bankId = rule.bankId,
                                packageNamesJson = JSONArray(rule.packageNames).toString(),
                                patternsJson = JSONArray(rule.patterns).toString(),
                                amountGroup = rule.amountGroup,
                                sign = rule.sign,
                                version = (nowMs / 1000L).toInt(),
                                fetchedAt = nowMs
                            )
                        )
                    }
                }
            }.fold(
                onSuccess  = { result.success(null) },
                onFailure  = { e ->
                    Log.e(TAG, "updateRegexConfig failed", e)
                    result.error("CONFIG_ERROR", e.message, null)
                }
            )
        }
    }

    // ── EventChannel ─────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        events.success(permissionStatus())

        val handler = Handler(Looper.getMainLooper())
        permissionObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                handler.post { events.success(permissionStatus()) }
            }
        }
        context.contentResolver.registerContentObserver(
            Settings.Secure.getUriFor("enabled_notification_listeners"),
            false,
            permissionObserver!!
        )
    }

    override fun onCancel(arguments: Any?) {
        val obs = permissionObserver
        if (obs != null) context.contentResolver.unregisterContentObserver(obs)
        permissionObserver = null
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    fun destroy() {
        onCancel(null)
        job.cancel()
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun permissionStatus(): String {
        val listeners = Settings.Secure.getString(
            context.contentResolver,
            "enabled_notification_listeners"
        ) ?: ""
        return if (listeners.contains(context.packageName)) "granted" else "denied"
    }

    private fun getSystemProperty(key: String): String {
        return try {
            Runtime.getRuntime().exec(arrayOf("getprop", key))
                .inputStream.bufferedReader().readText().trim()
        } catch (e: Exception) {
            ""
        }
    }
}
