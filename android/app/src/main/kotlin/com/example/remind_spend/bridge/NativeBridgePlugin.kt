package com.example.remind_spend.bridge

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
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
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.example.remind_spend.config.BankRule
import com.example.remind_spend.config.RegexConfigLoader
import com.example.remind_spend.db.AppDatabase
import com.example.remind_spend.db.IdempotencyEntry
import com.example.remind_spend.db.PendingTransaction
import com.example.remind_spend.db.RegexConfigEntry
import com.example.remind_spend.notification.LocalNotificationHelper
import com.example.remind_spend.notification.TransactionEventBus
import com.example.remind_spend.security.SecurityManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONArray

class NativeBridgePlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler, ActivityAware {

    companion object {
        private const val TAG                     = "NativeBridgePlugin"
        private const val METHOD_CHANNEL          = "com.example.remind_spend/transaction_bridge"
        private const val EVENT_CHANNEL           = "com.example.remind_spend/permission_status"
        private const val TX_EVENT_CHANNEL        = "com.example.remind_spend/transaction_events"
        private const val REQUEST_CODE_POST_NOTIF = 1001
    }

    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var txEventChannel: EventChannel

    private val pluginScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    private val permissionsResultListener =
        PluginRegistry.RequestPermissionsResultListener { requestCode, _, grantResults ->
            if (requestCode == REQUEST_CODE_POST_NOTIF) {
                val granted = grantResults.isNotEmpty() &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED
                pendingPermissionResult?.success(granted)
                pendingPermissionResult = null
                true
            } else {
                false
            }
        }

    // SecurityManager nhận context khi attached
    private val securityManager by lazy { SecurityManager(context) }
    private val db by lazy {
        AppDatabase.getInstance(context, securityManager.getDatabasePassphrase())
    }

    private var eventSink: EventChannel.EventSink? = null
    private var permissionObserver: ContentObserver? = null

    // ── FlutterPlugin ─────────────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        LocalNotificationHelper.createChannel(context)

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        txEventChannel = EventChannel(binding.binaryMessenger, TX_EVENT_CHANNEL)
        txEventChannel.setStreamHandler(txEventStreamHandler)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        txEventChannel.setStreamHandler(null)
        TransactionEventBus.setSink(null)
        pluginScope.cancel()
    }

    // Separate StreamHandler for transaction events — keeps permission StreamHandler clean.
    private val txEventStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
            TransactionEventBus.setSink(events)
        }
        override fun onCancel(arguments: Any?) {
            TransactionEventBus.setSink(null)
        }
    }

    // ── MethodChannel ─────────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAndClearQueue"                       -> handleGetAndClearQueue(result)
            "checkPermissionStatus"                  -> result.success(permissionStatus())
            "requestPermission"                      -> handleRequestPermission(result)
            "getManufacturerInfo"                    -> handleGetManufacturerInfo(result)
            "checkBatteryOptimization"               -> handleCheckBatteryOptimization(result)
            "requestBatteryOptimizationWhitelist"    -> handleRequestBatteryWhitelist(result)
            "updateRegexConfig"                      -> handleUpdateRegexConfig(call, result)
            "clearIdempotencyCache"                  -> handleClearIdempotencyCache(result)
            "requestPostNotificationsPermission"     -> handleRequestPostNotificationsPermission(result)
            "mockTransaction"                        -> handleMockTransaction(call, result)
            "simulateBankNotification"               -> handleSimulateBankNotification(call, result)
            else                                     -> result.notImplemented()
        }
    }

    private fun handleGetAndClearQueue(result: MethodChannel.Result) {
        pluginScope.launch {
            runCatching {
                val txs = db.pendingTransactionDao().dequeueAll()
                txs.map { tx ->
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
                onSuccess  = { withContext(Dispatchers.Main) { result.success(it) } },
                onFailure  = { e ->
                    Log.e(TAG, "getAndClearQueue failed", e)
                    withContext(Dispatchers.Main) {
                        result.error("DB_ERROR", e.message, null)
                    }
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
            "type"         to type,
            "manufacturer" to manufacturer,
            "model"        to Build.MODEL,
            "sdk_int"      to Build.VERSION.SDK_INT
        ))
    }

    private fun handleCheckBatteryOptimization(result: MethodChannel.Result) {
        val pm = context.getSystemService(PowerManager::class.java)
        result.success(pm.isIgnoringBatteryOptimizations(context.packageName))
    }

    private fun handleRequestBatteryWhitelist(result: MethodChannel.Result) {
        runCatching {
            context.startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:${context.packageName}")
                ).apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
            )
            result.success(true)
        }.onFailure { e ->
            result.error("BATTERY_ERROR", e.message, null)
        }
    }

    private fun handleUpdateRegexConfig(call: MethodCall, result: MethodChannel.Result) {
        pluginScope.launch {
            runCatching {
                val rawList = call.arguments as? List<*> ?: emptyList<Any>()
                val rules = rawList.mapNotNull { item ->
                    val map        = item as? Map<*, *> ?: return@mapNotNull null
                    val bankId     = map["bank_id"] as? String ?: return@mapNotNull null
                    val pkgs       = (map["package_names"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                    val patterns   = (map["patterns"] as? List<*>)?.mapNotNull { it as? String } ?: emptyList()
                    val amtGroup   = (map["amount_group"] as? Int) ?: 1
                    val sign       = map["sign"] as? String ?: "debit"
                    BankRule(bankId, pkgs, patterns, amtGroup, sign)
                }
                RegexConfigLoader.updateActiveRules(rules)
                val nowMs = System.currentTimeMillis()
                for (rule in rules) {
                    db.regexConfigDao().upsert(
                        RegexConfigEntry(
                            bankId           = rule.bankId,
                            packageNamesJson = JSONArray(rule.packageNames).toString(),
                            patternsJson     = JSONArray(rule.patterns).toString(),
                            amountGroup      = rule.amountGroup,
                            sign             = rule.sign,
                            version          = (nowMs / 1000L).toInt(),
                            fetchedAt        = nowMs
                        )
                    )
                }
            }.fold(
                onSuccess  = { withContext(Dispatchers.Main) { result.success(null) } },
                onFailure  = { e ->
                    Log.e(TAG, "updateRegexConfig failed", e)
                    withContext(Dispatchers.Main) {
                        result.error("CONFIG_ERROR", e.message, null)
                    }
                }
            )
        }
    }

    private fun handleClearIdempotencyCache(result: MethodChannel.Result) {
        pluginScope.launch {
            db.idempotencyCacheDao().purgeExpired(Long.MAX_VALUE)
            withContext(Dispatchers.Main) { result.success(null) }
        }
    }

    private fun handleRequestPostNotificationsPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }
        val act = activity
        if (act == null) {
            result.success(false)
            return
        }
        if (ContextCompat.checkSelfPermission(act, Manifest.permission.POST_NOTIFICATIONS)
            == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE_POST_NOTIF
        )
    }

    private fun handleMockTransaction(call: MethodCall, result: MethodChannel.Result) {
        pluginScope.launch {
            runCatching {
                val nowMs = System.currentTimeMillis()
                val id = "mock_$nowMs"
                db.pendingTransactionDao().enqueue(
                    PendingTransaction(
                        id = id,
                        packageName = "com.VCB",
                        bankId = "vcb",
                        rawAmount = 150000L,
                        sign = "debit",
                        encryptedContent = securityManager.encrypt("Mock transaction: -150,000 VND"),
                        timestampMs = nowMs,
                        createdAt = nowMs
                    )
                )
                TransactionEventBus.notifyNewTransaction()
            }.fold(
                onSuccess = { withContext(Dispatchers.Main) { result.success(null) } },
                onFailure = { e ->
                    withContext(Dispatchers.Main) {
                        result.error("MOCK_ERROR", e.message, null)
                    }
                }
            )
        }
    }

    private fun handleSimulateBankNotification(call: MethodCall, result: MethodChannel.Result) {
        val text = call.arguments as? String ?: return result.error("BAD_ARGS", "SMS text required", null)
        
        pluginScope.launch {
            runCatching {
                // Try to find a rule that matches this text across ALL known rules
                val rules = RegexConfigLoader.hardcodedRules // Using hardcoded for simplicity in simulation
                var matchedRule: BankRule? = null
                var amount: Long? = null
                
                for (rule in rules) {
                    val a = RegexConfigLoader.parseAmount(text, rule)
                    if (a != null) {
                        matchedRule = rule
                        amount = a
                        break
                    }
                }

                if (matchedRule == null || amount == null) {
                    withContext(Dispatchers.Main) { result.success(false) }
                    return@launch
                }

                val nowMs = System.currentTimeMillis()
                val id = "sim_$nowMs"
                
                db.pendingTransactionDao().enqueue(
                    PendingTransaction(
                        id = id,
                        packageName = matchedRule.packageNames.firstOrNull() ?: "com.simulated",
                        bankId = matchedRule.bankId,
                        rawAmount = amount,
                        sign = matchedRule.sign,
                        encryptedContent = securityManager.encrypt(text),
                        timestampMs = nowMs,
                        createdAt = nowMs
                    )
                )
                TransactionEventBus.notifyNewTransaction()
                withContext(Dispatchers.Main) { result.success(true) }
            }.onFailure { e ->
                withContext(Dispatchers.Main) {
                    result.error("SIM_ERROR", e.message, null)
                }
            }
        }
    }

    // ── ActivityAware ─────────────────────────────────────────────────────────

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(permissionsResultListener)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeRequestPermissionsResultListener(permissionsResultListener)
        activityBinding = null
        activity = null
    }

    // ── EventChannel ─────────────────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        events.success(permissionStatus())

        val handler = Handler(Looper.getMainLooper())
        val obs = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                handler.post { events.success(permissionStatus()) }
            }
        }
        permissionObserver = obs
        context.contentResolver.registerContentObserver(
            Settings.Secure.getUriFor("enabled_notification_listeners"),
            false,
            obs
        )
    }

    override fun onCancel(arguments: Any?) {
        val obs = permissionObserver
        if (obs != null) {
            context.contentResolver.unregisterContentObserver(obs)
            permissionObserver = null
        }
        eventSink = null
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun permissionStatus(): String {
        val flat = Settings.Secure.getString(
            context.contentResolver, "enabled_notification_listeners"
        ) ?: return "denied"
        return if (flat.contains(context.packageName)) "granted" else "denied"
    }

    private fun getSystemProperty(key: String): String =
        runCatching {
            val clazz  = Class.forName("android.os.SystemProperties")
            val method = clazz.getMethod("get", String::class.java)
            (method.invoke(null, key) as? String) ?: ""
        }.getOrDefault("")
}