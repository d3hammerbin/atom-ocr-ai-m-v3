package mx.d3c.dev.atom_ocr_ai_m_v3

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NATIVE_BRIDGE_CHANNEL = "mx.d3c.dev.atom_ocr_ai_m_v3/native_bridge"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Registrar el MethodChannel para el bridge nativo
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NATIVE_BRIDGE_CHANNEL).setMethodCallHandler { call, result ->
            // El handler real se configurará desde el lado de Flutter (NativeBridgeService)
            result.notImplemented()
        }
    }
}
