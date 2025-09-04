package mx.d3c.dev.atom_ocr_ai_m_v3

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * Bridge para comunicación entre la Activity de servicio nativa y el servicio Flutter INE
 */
class IneProcessorBridge(private val context: Context) {
    
    companion object {
        private const val TAG = "IneProcessorBridge"
        private const val CHANNEL_NAME = "mx.d3c.dev.atom_ocr_ai_m_v3/ine_processor"
    }
    
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private var isInitialized = false
    
    interface ProcessingCallback {
        fun onSuccess(result: JSONObject)
        fun onError(error: String)
    }
    
    /**
     * Inicializa el engine de Flutter y el canal de comunicación
     */
    fun initialize(callback: () -> Unit) {
        try {
            Log.d(TAG, "Inicializando Flutter Engine...")
            
            // Crear engine de Flutter
            flutterEngine = FlutterEngine(context)
            
            // Inicializar Dart
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            // Configurar MethodChannel
            methodChannel = MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger!!,
                CHANNEL_NAME
            )
            
            // Esperar a que Flutter esté listo
            Handler(Looper.getMainLooper()).postDelayed({
                isInitialized = true
                Log.d(TAG, "Flutter Engine inicializado correctamente")
                callback()
            }, 3000) // Dar tiempo para que Flutter se inicialice
            
        } catch (e: Exception) {
            Log.e(TAG, "Error inicializando Flutter Engine", e)
            isInitialized = false
        }
    }
    
    /**
     * Procesa una credencial INE usando el servicio Flutter
     */
    fun processCredential(
        imagePath: String,
        side: String,
        callback: ProcessingCallback
    ) {
        if (!isInitialized || methodChannel == null) {
            callback.onError("Bridge no inicializado")
            return
        }
        
        try {
            Log.d(TAG, "Procesando credencial - Path: $imagePath, Side: $side")
            
            val arguments = mapOf(
                "imagePath" to imagePath,
                "side" to side
            )
            
            methodChannel?.invokeMethod(
                "processCredential",
                arguments,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        try {
                            Log.d(TAG, "Procesamiento exitoso: $result")
                            
                            if (result is Map<*, *>) {
                                val jsonResult = JSONObject(result as Map<String, Any>)
                                callback.onSuccess(jsonResult)
                            } else {
                                callback.onError("Formato de resultado inválido")
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error procesando resultado", e)
                            callback.onError("Error procesando resultado: ${e.message}")
                        }
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        Log.e(TAG, "Error en procesamiento: $errorCode - $errorMessage")
                        callback.onError(errorMessage ?: "Error desconocido")
                    }
                    
                    override fun notImplemented() {
                        Log.e(TAG, "Método no implementado")
                        callback.onError("Método no implementado")
                    }
                }
            )
            
        } catch (e: Exception) {
            Log.e(TAG, "Error invocando método", e)
            callback.onError("Error invocando procesamiento: ${e.message}")
        }
    }
    
    /**
     * Valida si una imagen es una credencial INE válida
     */
    fun validateIneCredential(
        imagePath: String,
        callback: (Boolean, String?) -> Unit
    ) {
        if (!isInitialized || methodChannel == null) {
            callback(false, "Bridge no inicializado")
            return
        }
        
        try {
            val arguments = mapOf("imagePath" to imagePath)
            
            methodChannel?.invokeMethod(
                "validateIneCredential",
                arguments,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        if (result is Boolean) {
                            callback(result, null)
                        } else {
                            callback(false, "Formato de resultado inválido")
                        }
                    }
                    
                    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        callback(false, errorMessage)
                    }
                    
                    override fun notImplemented() {
                        callback(false, "Método no implementado")
                    }
                }
            )
            
        } catch (e: Exception) {
            callback(false, "Error validando: ${e.message}")
        }
    }
    
    /**
     * Libera recursos del engine de Flutter
     */
    fun dispose() {
        try {
            Log.d(TAG, "Liberando recursos del Flutter Engine")
            methodChannel = null
            flutterEngine?.destroy()
            flutterEngine = null
            isInitialized = false
        } catch (e: Exception) {
            Log.e(TAG, "Error liberando recursos", e)
        }
    }
}