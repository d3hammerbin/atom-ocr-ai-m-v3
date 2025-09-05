package mx.d3c.dev.atom_ocr_ai_m_v3

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.RippleDrawable
import android.graphics.drawable.StateListDrawable
import android.content.res.ColorStateList
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.provider.MediaStore
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter

class IneServiceActivity : Activity() {
    
    companion object {
        private const val TAG = "IneServiceActivity"
        const val EXTRA_IMAGE_PATH = "image_path"
        const val EXTRA_IMAGE_URI = "image_uri"
        const val EXTRA_SIDE = "side"
        const val EXTRA_RESULT_RECEIVER = "result_receiver"
        
        // Códigos de resultado
        const val RESULT_SUCCESS = 100
        const val RESULT_ERROR = 101
        
        // Código de solicitud de permisos
        private const val PERMISSION_REQUEST_CODE = 1001
        
        // Claves para el resultado JSON
        const val KEY_SUCCESS = "success"
        const val KEY_DATA = "data"
        const val KEY_ERROR = "error"
        const val KEY_MESSAGE = "message"
        
        // Configuración de límite temporal del servicio
        private const val EXPIRATION_DATE = "2025-11-01 00:00:00"
        private const val EXPIRATION_MESSAGE = "El servicio INE ha expirado. Contacte al administrador para renovar la licencia."
        private const val DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
        
        // Colores del tema Material Dark
        private const val COLOR_BACKGROUND = "#2C2C2C"        // Fondo principal más claro
        private const val COLOR_SURFACE = "#3A3A3A"           // Superficie elevada
        private const val COLOR_SURFACE_VARIANT = "#424242"   // Variante de superficie
        private const val COLOR_PRIMARY = "#BB86FC"           // Color primario (púrpura)
        private const val COLOR_PRIMARY_VARIANT = "#9C27B0"   // Variante del primario
        private const val COLOR_SECONDARY = "#424242"         // Color secundario (gris)
        private const val COLOR_ON_BACKGROUND = "#FFFFFF"     // Texto sobre fondo
        private const val COLOR_ON_SURFACE = "#E0E0E0"       // Texto sobre superficie
        private const val COLOR_ON_SURFACE_MEDIUM = "#B0B0B0" // Texto medio
        private const val COLOR_ERROR = "#FF6B6B"            // Color de error
        private const val COLOR_SUCCESS = "#4CAF50"          // Color de éxito
        private const val COLOR_STATUS_BAR = "#2A2A2A"       // Barra de estado
        private const val COLOR_BORDER = "#616161"           // Bordes
    }
    
    private lateinit var imageView: ImageView
    private lateinit var sideTextView: TextView
    private lateinit var progressBar: ProgressBar
    private lateinit var statusTextView: TextView
    private lateinit var processButton: Button
    private lateinit var cancelButton: Button
    
    private var imagePath: String? = null
    private var imageUri: Uri? = null
    private var side: String? = null
    private var resultReceiver: ResultReceiver? = null
    private var bitmap: Bitmap? = null
    private var processorBridge: IneProcessorBridge? = null

    /**
     * Verifica si todos los permisos necesarios están concedidos
     */
    private fun checkPermissions(): Boolean {
        val requiredPermissions = getRequiredPermissions()
        return requiredPermissions.all { permission ->
            ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
        }
    }

    /**
     * Obtiene la lista de permisos requeridos según la versión de Android
     */
    private fun getRequiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ - Permisos granulares para medios
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.READ_MEDIA_IMAGES
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ - Gestión de almacenamiento externo
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.MANAGE_EXTERNAL_STORAGE
            )
        } else {
            // Android 10 y anteriores
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            )
        }
    }

    /**
     * Solicita los permisos faltantes al usuario
     */
    private fun requestPermissions() {
        val requiredPermissions = getRequiredPermissions()
        val missingPermissions = requiredPermissions.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED
        }.toTypedArray()

        if (missingPermissions.isNotEmpty()) {
            Log.d(TAG, "Solicitando permisos: ${missingPermissions.joinToString(", ")}")
            ActivityCompat.requestPermissions(this, missingPermissions, PERMISSION_REQUEST_CODE)
        }
    }

    /**
     * Verifica si se debe mostrar la explicación de permisos
     */
    private fun shouldShowPermissionRationale(): Boolean {
        val requiredPermissions = getRequiredPermissions()
        return requiredPermissions.any { permission ->
            ActivityCompat.shouldShowRequestPermissionRationale(this, permission)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Verificar si el servicio ha expirado
        if (isServiceExpired()) {
            handleServiceExpired()
            return
        }
        
        // Configurar layout programáticamente (sin XML)
        setupLayout()
        
        // Verificar permisos iniciales
        if (!checkPermissions()) {
            Log.w(TAG, "Permisos no concedidos al inicializar")
            updateStatusText("Verificando permisos necesarios...", isError = false)
        }
        
        // Inicializar bridge de Flutter
        initializeFlutterBridge()
        
        // Procesar intent recibido
        processIntent()
    }
    
    private fun setupLayout() {
        // Configurar tema oscuro para la actividad
        window.statusBarColor = Color.parseColor(COLOR_STATUS_BAR)
        
        // Crear layout principal con tema oscuro
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(24), dpToPx(24), dpToPx(24), dpToPx(24))
            setBackgroundColor(Color.parseColor(COLOR_BACKGROUND))
        }
        
        // Título con estilo Material Dark
        val titleTextView = TextView(this).apply {
            text = "Servicio de Procesamiento INE"
            textSize = 24f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(Color.parseColor(COLOR_ON_BACKGROUND))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dpToPx(32))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        layout.addView(titleTextView)
        
        // ImageView para preview con bordes redondeados
        imageView = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(300)
            ).apply {
                bottomMargin = dpToPx(20)
            }
            scaleType = ImageView.ScaleType.CENTER_CROP
            background = createRoundedBackground(Color.parseColor(COLOR_SURFACE_VARIANT), dpToPx(12))
            setPadding(dpToPx(8), dpToPx(8), dpToPx(8), dpToPx(8))
        }
        layout.addView(imageView)
        
        // TextView para mostrar el lado con estilo Material
        sideTextView = TextView(this).apply {
            text = "Lado: No especificado"
            textSize = 16f
            setTextColor(Color.parseColor(COLOR_ON_SURFACE))
            setTypeface(null, android.graphics.Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(12))
            background = createRoundedBackground(Color.parseColor(COLOR_SURFACE), dpToPx(8))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(20)
            }
        }
        layout.addView(sideTextView)
        
        // ProgressBar con tema oscuro
        progressBar = ProgressBar(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(20)
            }
            visibility = View.GONE
            indeterminateDrawable?.setColorFilter(Color.parseColor(COLOR_PRIMARY), android.graphics.PorterDuff.Mode.SRC_IN)
        }
        layout.addView(progressBar)
        
        // TextView para estado con estilo Material
        statusTextView = TextView(this).apply {
            text = "Listo para procesar"
            textSize = 14f
            setTextColor(Color.parseColor(COLOR_ON_BACKGROUND))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dpToPx(24))
        }
        layout.addView(statusTextView)
        
        // Contenedor horizontal para los botones
        val buttonContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        }
        
        // Botón de procesar con estilo gris/transparente
        processButton = Button(this).apply {
            text = "PROCESAR"
            layoutParams = LinearLayout.LayoutParams(
                0,
                dpToPx(56) // Altura estándar Material
            ).apply {
                weight = 1f
                rightMargin = dpToPx(8)
            }
            setTextColor(Color.parseColor(COLOR_ON_SURFACE))
            textSize = 14f
            setTypeface(null, android.graphics.Typeface.BOLD)
            background = createMaterialButtonSecondary(Color.parseColor("#40FFFFFF")) // Gris transparente
            elevation = dpToPx(2).toFloat()
            setOnClickListener { startProcessing() }
        }
        buttonContainer.addView(processButton)
        
        // Botón de cancelar con estilo gris/transparente
        cancelButton = Button(this).apply {
            text = "CANCELAR"
            layoutParams = LinearLayout.LayoutParams(
                0,
                dpToPx(56) // Altura estándar Material
            ).apply {
                weight = 1f
                leftMargin = dpToPx(8)
            }
            setTextColor(Color.parseColor(COLOR_ON_SURFACE))
            textSize = 14f
            setTypeface(null, android.graphics.Typeface.BOLD)
            background = createMaterialButtonSecondary(Color.parseColor("#30FFFFFF")) // Gris transparente más sutil
            elevation = dpToPx(2).toFloat()
            setOnClickListener { cancelProcessing() }
        }
        buttonContainer.addView(cancelButton)
        
        layout.addView(buttonContainer)
        
        setContentView(layout)
    }
    
    private fun processIntent() {
        try {
            // Verificar expiración antes de procesar
            if (isServiceExpired()) {
                handleServiceExpired()
                return
            }
            
            // Obtener parámetros del intent
            imagePath = intent.getStringExtra(EXTRA_IMAGE_PATH)
            val imageUriString = intent.getStringExtra(EXTRA_IMAGE_URI)
            side = intent.getStringExtra(EXTRA_SIDE)
            resultReceiver = intent.getParcelableExtra(EXTRA_RESULT_RECEIVER)
            val testMode = intent.getStringExtra("testMode")
            
            if (imageUriString != null) {
                imageUri = Uri.parse(imageUriString)
            }
            
            Log.d(TAG, "Parámetros recibidos - Path: $imagePath, URI: $imageUri, Side: $side, TestMode: $testMode")
            
            // Validar que se proporcionen los parámetros requeridos
            if ((imagePath == null && imageUri == null) || side == null) {
                Log.e(TAG, "Parámetros requeridos faltantes - Path: $imagePath, URI: $imageUri, Side: $side")
                showError("Error: Se requieren parámetros de imagen y lado para procesar")
                return
            }
            
            // Actualizar UI
            sideTextView.text = "Lado: ${side?.uppercase()}"
            
            // Cargar imagen
            loadImage()
            
        } catch (e: Exception) {
            Log.e(TAG, "Error procesando intent", e)
            showError("Error procesando parámetros: ${e.message}")
        }
    }
    

    
    private fun loadImage() {
        // Verificar permisos antes de procesar la imagen
        if (!checkPermissions()) {
            Log.w(TAG, "Permisos no concedidos, solicitando permisos")
            updateStatusText("Verificando permisos...", isError = false)
            requestPermissions()
            return
        }
        
        try {
            Log.d(TAG, "Intentando cargar imagen - Path: $imagePath, URI: $imageUri")
            
            bitmap = when {
                imagePath != null -> {
                    val file = File(imagePath!!)
                    Log.d(TAG, "Verificando archivo: ${file.absolutePath}")
                    Log.d(TAG, "Archivo existe: ${file.exists()}, Puede leer: ${file.canRead()}, Tamaño: ${file.length()}")
                    
                    if (file.exists() && file.canRead()) {
                        val decodedBitmap = BitmapFactory.decodeFile(imagePath)
                        Log.d(TAG, "Bitmap decodificado: ${decodedBitmap != null}")
                        decodedBitmap
                    } else {
                        Log.e(TAG, "Archivo no encontrado o no se puede leer: $imagePath")
                        null
                    }
                }
                imageUri != null -> {
                    Log.d(TAG, "Cargando desde URI: $imageUri")
                    val inputStream: InputStream? = contentResolver.openInputStream(imageUri!!)
                    inputStream?.use { BitmapFactory.decodeStream(it) }
                }
                else -> {
                    Log.e(TAG, "No hay imagen path ni URI")
                    null
                }
            }
            
            if (bitmap != null) {
                imageView.setImageBitmap(bitmap)
                updateStatusText("Imagen cargada correctamente", isSuccess = true)
                Log.d(TAG, "Imagen cargada exitosamente")
            } else {
                Log.e(TAG, "Bitmap es null después de intentar cargar")
                showError("No se pudo cargar la imagen")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error cargando imagen", e)
            showError("Error cargando imagen: ${e.message}")
        }
    }
    
    private fun initializeFlutterBridge() {
        try {
            processorBridge = IneProcessorBridge(this)
            updateStatusText("Inicializando servicio...")
            
            processorBridge?.initialize {
                runOnUiThread {
                    updateStatusText("Servicio listo para procesar", isSuccess = true)
                    processButton.isEnabled = true
                    
                    // Si tenemos parámetros válidos, iniciar procesamiento automáticamente
                    // (con ResultReceiver para aplicaciones externas o en testMode para pruebas)
                    val testMode = intent.getBooleanExtra("testMode", false)
                    if (bitmap != null && side != null && (resultReceiver != null || testMode)) {
                        Log.d(TAG, "Iniciando procesamiento automático... (TestMode: $testMode)")
                        startProcessing()
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error inicializando Flutter Bridge", e)
            showError("Error inicializando servicio: ${e.message}")
        }
    }
    
    private fun startProcessing() {
        // Verificar expiración antes de iniciar procesamiento
        if (isServiceExpired()) {
            handleServiceExpired()
            return
        }
        
        if (bitmap == null) {
            showError("No hay imagen para procesar")
            return
        }
        
        if (processorBridge == null) {
            showError("Servicio no inicializado")
            return
        }
        
        // Obtener ruta de imagen real
        val realImagePath = getRealImagePath()
        if (realImagePath == null) {
            showError("No se pudo obtener la ruta de la imagen")
            return
        }
        
        // Mostrar loader
        progressBar.visibility = View.VISIBLE
        updateStatusText("Procesando credencial...")
        processButton.isEnabled = false
        
        // Procesar con el servicio Flutter real
        processorBridge?.processCredential(
            realImagePath,
            side ?: "frontal",
            object : IneProcessorBridge.ProcessingCallback {
                override fun onSuccess(result: JSONObject) {
                    runOnUiThread {
                        handleProcessingSuccess(result)
                    }
                }
                
                override fun onError(error: String) {
                    runOnUiThread {
                        handleProcessingError(error)
                    }
                }
            }
        )
    }
    
    private fun getRealImagePath(): String? {
        return when {
            imagePath != null -> {
                val file = File(imagePath!!)
                if (file.exists()) imagePath else null
            }
            imageUri != null -> {
                // Convertir URI a ruta de archivo temporal
                copyUriToTempFile(imageUri!!)
            }
            else -> null
        }
    }
    
    private fun copyUriToTempFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri)
            val tempFile = File(cacheDir, "temp_credential_${System.currentTimeMillis()}.jpg")
            
            inputStream?.use { input ->
                FileOutputStream(tempFile).use { output ->
                    input.copyTo(output)
                }
            }
            
            tempFile.absolutePath
        } catch (e: Exception) {
            Log.e(TAG, "Error copiando URI a archivo temporal", e)
            null
        }
    }
    
    private fun handleProcessingSuccess(result: JSONObject) {
        try {
            // Ocultar loader
            progressBar.visibility = View.GONE
            updateStatusText("Procesamiento completado", isSuccess = true)
            processButton.isEnabled = true
            
            // Extraer datos del resultado
            val success = result.optBoolean("success", false)
            
            if (success) {
                val data = result.optJSONObject("data")
                val credentialType = result.optString("credentialType", "desconocido")
                val detectedSide = result.optString("side", "desconocido")
                
                Log.d(TAG, "Procesamiento exitoso - Tipo: $credentialType, Lado: $detectedSide")
                
                // Enviar resultado
                sendResult(true, data, null)
                
                // Mostrar éxito y cerrar
                Toast.makeText(this, "Procesamiento exitoso", Toast.LENGTH_SHORT).show()
                
                Handler(Looper.getMainLooper()).postDelayed({
                    finish()
                }, 1500)
            } else {
                val error = result.optString("error", "Error desconocido")
                handleProcessingError(error)
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error manejando resultado exitoso", e)
            handleProcessingError("Error procesando resultado: ${e.message}")
        }
    }
    
    private fun handleProcessingError(error: String) {
        Log.e(TAG, "Error en procesamiento: $error")
        
        // Ocultar loader
        progressBar.visibility = View.GONE
        updateStatusText("Error en procesamiento", isError = true)
        processButton.isEnabled = true
        
        // Mostrar error
        showError("Error procesando: $error")
    }
    
    private fun createMockResponse(): JSONObject {
        val data = JSONObject()
        
        when (side?.lowercase()) {
            "frontal" -> {
                // Datos para credencial frontal (T2 o T3)
                data.put("nombre", "JUAN CARLOS")
                data.put("apellidoPaterno", "PÉREZ")
                data.put("apellidoMaterno", "GONZÁLEZ")
                data.put("fechaNacimiento", "15/03/1985")
                data.put("sexo", "H")
                data.put("curp", "PEGJ850315HDFRNN09")
                data.put("numeroCredencial", "1234567890123")
                data.put("vigencia", "2029")
                data.put("tipoCredencial", "T3")
                data.put("lado", "frontal")
            }
            "reverso" -> {
                // Datos para credencial reverso (solo T3)
                data.put("domicilio", "CALLE EJEMPLO 123, COL. CENTRO")
                data.put("municipio", "GUADALAJARA")
                data.put("estado", "JALISCO")
                data.put("codigoPostal", "44100")
                data.put("claveElector", "PGNJPR85031512H400")
                data.put("tipoCredencial", "T3")
                data.put("lado", "reverso")
            }
            else -> {
                data.put("error", "Lado no válido")
            }
        }
        
        return data
    }
    
    private fun sendResult(success: Boolean, data: JSONObject?, error: String?) {
        try {
            val result = Bundle().apply {
                putBoolean(KEY_SUCCESS, success)
                if (success && data != null) {
                    putString(KEY_DATA, data.toString())
                } else if (!success && error != null) {
                    putString(KEY_ERROR, error)
                }
            }
            
            val testMode = intent.getStringExtra("testMode")
            
            if (resultReceiver != null) {
                // Modo normal con ResultReceiver
                resultReceiver?.send(
                    if (success) RESULT_SUCCESS else RESULT_ERROR,
                    result
                )
                Log.d(TAG, "Resultado enviado via ResultReceiver: success=$success")
            } else if (testMode == "true") {
                // Modo de prueba - mostrar resultado en logs
                Log.i(TAG, "=== RESULTADO DE PRUEBA ===")
                Log.i(TAG, "Success: $success")
                if (success && data != null) {
                    Log.i(TAG, "Data: ${data.toString(2)}")
                } else if (!success && error != null) {
                    Log.i(TAG, "Error: $error")
                }
                Log.i(TAG, "==========================")
            }
            
        } catch (e: Exception) {
            Log.e(TAG, "Error enviando resultado", e)
        }
    }
    
    private fun cancelProcessing() {
        sendResult(false, null, "Procesamiento cancelado por el usuario")
        finish()
    }
    
    private fun showError(message: String) {
        statusTextView.apply {
            text = "Error: $message"
            setTextColor(Color.parseColor(COLOR_ERROR)) // Rojo suave para errores
        }
        
        // Toast personalizado con tema oscuro
        val toast = Toast.makeText(this, message, Toast.LENGTH_LONG)
        toast.view?.setBackgroundColor(Color.parseColor(COLOR_SURFACE))
        toast.show()
        
        sendResult(false, null, message)
    }
    
    private fun updateStatusText(message: String, isError: Boolean = false, isSuccess: Boolean = false) {
        statusTextView.apply {
            text = message
            setTextColor(when {
                isError -> Color.parseColor(COLOR_ERROR)    // Rojo suave para errores
                isSuccess -> Color.parseColor(COLOR_ON_BACKGROUND)  // Blanco para éxito
                else -> Color.parseColor(COLOR_ON_SURFACE_MEDIUM)       // Gris medio para estado normal
            })
        }
    }
    
    // Funciones de verificación de límite temporal
    private fun isServiceExpired(): Boolean {
        return try {
            val currentDate = LocalDateTime.now()
            val expirationDate = parseExpirationDate()
            val isExpired = currentDate.isAfter(expirationDate)
            
            Log.d(TAG, "Verificación de expiración:")
            Log.d(TAG, "- Fecha actual: ${formatCurrentDate(currentDate)}")
            Log.d(TAG, "- Fecha de expiración: $EXPIRATION_DATE")
            Log.d(TAG, "- Servicio expirado: $isExpired")
            
            isExpired
        } catch (e: Exception) {
            Log.e(TAG, "Error al verificar expiración del servicio", e)
            // En caso de error, permitir el funcionamiento
            false
        }
    }
    
    private fun parseExpirationDate(): LocalDateTime {
        val formatter = DateTimeFormatter.ofPattern(DATE_FORMAT)
        return LocalDateTime.parse(EXPIRATION_DATE, formatter)
    }
    
    private fun formatCurrentDate(date: LocalDateTime): String {
        val formatter = DateTimeFormatter.ofPattern(DATE_FORMAT)
        return date.format(formatter)
    }
    
    private fun handleServiceExpired() {
        Log.w(TAG, "Servicio INE expirado. Fecha límite: $EXPIRATION_DATE")
        
        // Enviar mensaje de expiración si hay un receiver
        resultReceiver?.let { receiver ->
            val bundle = Bundle().apply {
                putString(KEY_ERROR, EXPIRATION_MESSAGE)
                putString("status", "expired")
                putString("expiration_date", EXPIRATION_DATE)
            }
            receiver.send(RESULT_ERROR, bundle)
            Log.d(TAG, "Mensaje de expiración enviado al receiver")
        }
        
        // Mostrar mensaje en logs para modo test
        val testMode = intent.getStringExtra("testMode")
        if (testMode == "true") {
            Log.e(TAG, "SERVICIO_EXPIRADO: $EXPIRATION_MESSAGE")
            Log.e(TAG, "FECHA_EXPIRACION: $EXPIRATION_DATE")
        }
        
        // Cerrar la actividad
        finish()
    }
    
    // Funciones auxiliares para el tema Material Design
    private fun dpToPx(dp: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            dp.toFloat(),
            resources.displayMetrics
        ).toInt()
    }
    
    private fun createRoundedBackground(color: Int, cornerRadius: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(color)
            this.cornerRadius = cornerRadius.toFloat()
        }
    }
    
    private fun createMaterialButton(normalColor: Int, pressedColor: Int): RippleDrawable {
        // Crear el fondo del botón
        val backgroundDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(normalColor)
            cornerRadius = dpToPx(8).toFloat()
        }
        
        // Crear máscara para el ripple
        val maskDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(Color.WHITE)
            cornerRadius = dpToPx(8).toFloat()
        }
        
        // Crear efecto ripple
        val rippleColor = ColorStateList.valueOf(Color.parseColor("#40FFFFFF"))
        return RippleDrawable(rippleColor, backgroundDrawable, maskDrawable)
    }
    
    private fun createMaterialButtonSecondary(normalColor: Int): RippleDrawable {
        // Crear el fondo del botón secundario
        val backgroundDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(normalColor)
            cornerRadius = dpToPx(8).toFloat()
            setStroke(dpToPx(1), Color.parseColor("#616161"))
        }
        
        // Crear máscara para el ripple
        val maskDrawable = GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            setColor(Color.WHITE)
            cornerRadius = dpToPx(8).toFloat()
        }
        
        // Crear efecto ripple más sutil para botón secundario
        val rippleColor = ColorStateList.valueOf(Color.parseColor("#20FFFFFF"))
        return RippleDrawable(rippleColor, backgroundDrawable, maskDrawable)
    }
    
    /**
     * Maneja la respuesta del usuario a la solicitud de permisos
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val allPermissionsGranted = grantResults.isNotEmpty() && 
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            
            if (allPermissionsGranted) {
                Log.d(TAG, "Todos los permisos concedidos")
                updateStatusText("Permisos concedidos. Continuando con el procesamiento...", isSuccess = true)
                
                // Continuar con la carga de imagen si hay parámetros válidos
                if (imagePath != null || imageUri != null) {
                    loadImage()
                }
            } else {
                Log.w(TAG, "Algunos permisos fueron denegados")
                val deniedPermissions = permissions.filterIndexed { index, _ -> 
                    grantResults[index] != PackageManager.PERMISSION_GRANTED 
                }
                
                val errorMessage = "Permisos requeridos denegados: ${deniedPermissions.joinToString(", ")}"
                updateStatusText(errorMessage, isError = true)
                
                // Verificar si se debe mostrar explicación
                if (shouldShowPermissionRationale()) {
                    showPermissionRationaleDialog()
                } else {
                    // El usuario marcó "No volver a preguntar"
                    showPermissionSettingsDialog()
                }
            }
        }
    }
    
    /**
     * Muestra un diálogo explicando por qué se necesitan los permisos
     */
    private fun showPermissionRationaleDialog() {
        updateStatusText("Los permisos son necesarios para procesar imágenes de credenciales", isError = true)
        Toast.makeText(
            this,
            "Esta aplicación necesita acceso a la cámara y almacenamiento para procesar credenciales INE",
            Toast.LENGTH_LONG
        ).show()
        
        // Enviar error al receptor
        sendResult(
            success = false,
            data = null,
            error = "Permisos requeridos no concedidos"
        )
    }
    
    /**
     * Muestra un diálogo sugiriendo ir a configuración para habilitar permisos
     */
    private fun showPermissionSettingsDialog() {
        updateStatusText("Configure los permisos en Ajustes de la aplicación", isError = true)
        Toast.makeText(
            this,
            "Por favor, habilite los permisos de cámara y almacenamiento en Ajustes > Aplicaciones",
            Toast.LENGTH_LONG
        ).show()
        
        // Enviar error al receptor
        sendResult(
            success = false,
            data = null,
            error = "Permisos requeridos no concedidos. Configure en Ajustes."
        )
    }

    override fun onDestroy() {
        super.onDestroy()
        bitmap?.recycle()
        processorBridge?.dispose()
    }
}