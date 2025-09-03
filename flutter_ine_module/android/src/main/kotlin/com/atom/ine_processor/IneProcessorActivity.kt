package com.atom.ine_processor

import android.content.Intent
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import org.json.JSONObject

/**
 * Actividad principal del módulo Flutter para procesamiento de credenciales INE
 * Maneja la comunicación entre React Native y Flutter mediante MethodChannel
 */
class IneProcessorActivity : FlutterActivity() {
    private val CHANNEL = "ine_processor_module"
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)
        
        // Configurar MethodChannel para comunicación con React Native
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "processCredentialFromRN" -> {
                    handleProcessCredentialFromRN(call.arguments, result)
                }
                "getModuleInfo" -> {
                    result.success(getModuleInfo())
                }
                "returnToReactNative" -> {
                    handleReturnToReactNative(call.arguments)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Procesar intent si viene desde React Native
        handleIncomingIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIncomingIntent(intent)
    }
    
    /**
     * Maneja los intents entrantes desde React Native
     */
    private fun handleIncomingIntent(intent: Intent?) {
        intent?.let {
            when (it.action) {
                Intent.ACTION_VIEW -> {
                    // Procesar datos del intent
                    val data = it.data
                    if (data?.scheme == "ine-processor") {
                        val imagePath = data.getQueryParameter("imagePath")
                        val options = data.getQueryParameter("options")
                        
                        if (imagePath != null) {
                            // Enviar datos a Flutter
                            val arguments = mapOf(
                                "imagePath" to imagePath,
                                "options" to options,
                                "source" to "react_native"
                            )
                            
                            methodChannel?.invokeMethod("processCredentialFromIntent", arguments)
                        }
                    }
                }
            }
            
            // Procesar extras del intent
            val extras = it.extras
            if (extras != null && extras.containsKey("credentialData")) {
                val credentialData = extras.getString("credentialData")
                val processingOptions = extras.getString("processingOptions")
                
                val arguments = mapOf(
                    "credentialData" to credentialData,
                    "processingOptions" to processingOptions,
                    "source" to "react_native_extras"
                )
                
                methodChannel?.invokeMethod("processCredentialFromExtras", arguments)
            }
        }
    }
    
    /**
     * Maneja el procesamiento de credenciales solicitado desde React Native
     */
    private fun handleProcessCredentialFromRN(arguments: Any?, result: MethodChannel.Result) {
        try {
            if (arguments is Map<*, *>) {
                val args = arguments as Map<String, Any>
                val imagePath = args["imagePath"] as? String
                
                if (imagePath.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENTS", "La ruta de la imagen es requerida", null)
                    return
                }
                
                // Reenviar la llamada al widget Flutter
                methodChannel?.invokeMethod("processCredential", arguments, object : MethodChannel.Result {
                    override fun success(result_data: Any?) {
                        result.success(result_data)
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        result.error(errorCode, errorMessage, errorDetails)
                    }
                    
                    override fun notImplemented() {
                        result.notImplemented()
                    }
                })
            } else {
                result.error("INVALID_ARGUMENTS", "Argumentos inválidos", null)
            }
        } catch (e: Exception) {
            result.error("PROCESSING_ERROR", "Error procesando credencial: ${e.message}", null)
        }
    }
    
    /**
     * Maneja el retorno a React Native con resultados
     */
    private fun handleReturnToReactNative(arguments: Any?) {
        try {
            if (arguments is Map<*, *>) {
                val args = arguments as Map<String, Any>
                val resultData = args["resultData"]
                val success = args["success"] as? Boolean ?: false
                
                // Crear intent de resultado
                val resultIntent = Intent().apply {
                    putExtra("processing_result", resultData.toString())
                    putExtra("success", success)
                    putExtra("timestamp", System.currentTimeMillis())
                }
                
                setResult(if (success) RESULT_OK else RESULT_CANCELED, resultIntent)
                finish()
            }
        } catch (e: Exception) {
            // En caso de error, retornar con resultado de error
            val errorIntent = Intent().apply {
                putExtra("error", "Error retornando a React Native: ${e.message}")
                putExtra("success", false)
            }
            setResult(RESULT_CANCELED, errorIntent)
            finish()
        }
    }
    
    /**
     * Obtiene información del módulo
     */
    private fun getModuleInfo(): Map<String, Any> {
        return mapOf(
            "moduleName" to "INE Processor Module",
            "version" to "1.0.0",
            "platform" to "Android",
            "flutterVersion" to getFlutterVersion(),
            "supportedFeatures" to listOf(
                "OCR",
                "QR Code Detection",
                "Barcode Detection",
                "Face Detection",
                "Photo Extraction",
                "Signature Extraction",
                "Data Validation"
            ),
            "supportedCredentialTypes" to listOf("T2", "T3"),
            "timestamp" to System.currentTimeMillis()
        )
    }
    
    /**
     * Obtiene la versión de Flutter (método auxiliar)
     */
    private fun getFlutterVersion(): String {
        return try {
            // Intentar obtener la versión de Flutter desde BuildConfig o recursos
            "3.16.0" // Versión por defecto
        } catch (e: Exception) {
            "unknown"
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
    
    companion object {
        const val REQUEST_CODE_INE_PROCESSOR = 1001
        
        /**
         * Crea un intent para iniciar el módulo desde React Native
         */
        fun createIntent(
            packageName: String,
            imagePath: String,
            options: String? = null
        ): Intent {
            return Intent().apply {
                setClassName(packageName, "com.atom.ine_processor.IneProcessorActivity")
                putExtra("credentialData", imagePath)
                putExtra("processingOptions", options)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        }
    }
}