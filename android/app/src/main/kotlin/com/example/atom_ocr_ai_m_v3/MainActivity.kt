package com.example.atom_ocr_ai_m_v3

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import java.lang.System

class MainActivity: FlutterActivity() {
    private val CHANNEL = "memory_management"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "forceGC" -> {
                    try {
                        // Forzar recolección de basura
                        System.gc()
                        System.runFinalization()
                        
                        // Esperar un momento
                        Thread.sleep(100)
                        
                        // Forzar GC nuevamente
                        System.gc()
                        
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("GC_ERROR", "Error al forzar GC: ${e.message}", null)
                    }
                }
                "getMemoryInfo" -> {
                    try {
                        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        val memoryInfo = ActivityManager.MemoryInfo()
                        activityManager.getMemoryInfo(memoryInfo)
                        
                        val runtime = Runtime.getRuntime()
                        val usedMemory = runtime.totalMemory() - runtime.freeMemory()
                        
                        val memInfo = mapOf(
                            "available" to memoryInfo.availMem,
                            "total" to memoryInfo.totalMem,
                            "used" to usedMemory,
                            "threshold" to memoryInfo.threshold,
                            "lowMemory" to memoryInfo.lowMemory
                        )
                        
                        result.success(memInfo)
                    } catch (e: Exception) {
                        result.error("MEMORY_INFO_ERROR", "Error al obtener info de memoria: ${e.message}", null)
                    }
                }
                "trimMemory" -> {
                    try {
                        // Intentar liberar memoria no esencial
                        onTrimMemory(TRIM_MEMORY_RUNNING_CRITICAL)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("TRIM_ERROR", "Error al liberar memoria: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        
        when (level) {
            TRIM_MEMORY_RUNNING_CRITICAL,
            TRIM_MEMORY_RUNNING_LOW,
            TRIM_MEMORY_RUNNING_MODERATE -> {
                // Forzar limpieza de memoria cuando el sistema está bajo presión
                System.gc()
                System.runFinalization()
            }
        }
    }
}