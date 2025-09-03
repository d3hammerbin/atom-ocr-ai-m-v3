import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/services/logger_service.dart';
import '../../core/utils/snackbar_utils.dart';

class ProcessingController extends GetxController {
  // Observable para el estado de procesamiento
  final RxBool isProcessing = false.obs;
  final RxString processingStatus = 'Procesando credencial...'.obs;
  
  // Imagen capturada
  final Rxn<File> capturedImage = Rxn<File>();
  
  // Datos dummy de la credencial
  final RxMap<String, String> credentialData = <String, String>{
    'timestamp': '2024-01-01T12:00:00Z',
    'nombre': 'JUAN CARLOS PÉREZ GARCÍA',
    'sexo': 'MASCULINO',
    'domicilio': 'CALLE REFORMA 123, COL. CENTRO, CIUDAD DE MÉXICO',
    'clave_de_elector': 'PGJCRN85031512H700',
    'curp': 'PEGJ850315HDFRRN09',
    'anio_registro': '2019',
    'fecha_nacimiento': '15/03/1985',
    'seccion': '1234',
    'vigencia': '2024',
  }.obs;
  
  @override
  void onInit() {
    super.onInit();
    _setPortraitOrientation();
  }
  
  Future<void> _setPortraitOrientation() async {
    // Forzar orientación portrait al entrar a la pantalla
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // Pequeño delay para asegurar que la orientación se aplique
    await Future.delayed(const Duration(milliseconds: 200));
    _initializeProcessing();
  }
  
  Future<void> _initializeProcessing() async {
    try {
      await Log.i('ProcessingController', 'Iniciando procesamiento...');
      
      // Verificar que el directorio seguro esté listo
      final bool isSecureReady = await SecureStorage.isSecureDirectoryReady();
      await Log.d('ProcessingController', 'Directorio seguro listo: $isSecureReady');
      if (!isSecureReady) {
        processingStatus.value = 'Error: Directorio seguro no disponible';
        return;
      }
      
      // Obtener la imagen del argumento de navegación
      final arguments = Get.arguments;
      await Log.d('ProcessingController', 'Argumentos recibidos: $arguments');
      
      if (arguments != null && arguments['imagePath'] != null) {
        final String imagePath = arguments['imagePath'] as String;
        await Log.d('ProcessingController', 'Ruta de imagen: $imagePath');
        final File imageFile = File(imagePath);
        
        // Verificar que la imagen existe en el directorio seguro
        final bool imageExists = await imageFile.exists();
        await Log.d('ProcessingController', 'Imagen existe: $imageExists');
        
        if (imageExists) {
          capturedImage.value = imageFile;
          await Log.i('ProcessingController', 'Imagen asignada, iniciando procesamiento...');
          startProcessing();
        } else {
          processingStatus.value = 'Error: Imagen no encontrada en directorio seguro';
          await Log.w('ProcessingController', 'Error - Imagen no encontrada');
        }
      } else {
        processingStatus.value = 'Error: No se proporcionó ruta de imagen';
        await Log.w('ProcessingController', 'Error - No se proporcionó ruta de imagen');
      }
    } catch (e) {
      processingStatus.value = 'Error inicializando procesamiento: $e';
      await Log.e('ProcessingController', 'Error en inicialización', e);
    }
  }
  
  void startProcessing() {
    isProcessing.value = true;
    processingStatus.value = 'Analizando imagen...';
    
    // Simular procesamiento con delay
    Future.delayed(const Duration(seconds: 2), () {
      processingStatus.value = 'Extrayendo texto...';
    });
    
    Future.delayed(const Duration(seconds: 4), () {
      processingStatus.value = 'Validando información...';
    });
    
    Future.delayed(const Duration(seconds: 6), () {
      processingStatus.value = 'Procesamiento completado';
      isProcessing.value = false;
    });
  }
  
  void cancelProcessing() {
    // Mostrar diálogo de confirmación antes de salir
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar salida'),
        content: const Text('¿Estás seguro de que deseas salir? Se perderán los datos procesados.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Get.back(); // Cerrar diálogo
              Get.offAllNamed('/home'); // Ir al home
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
  
  void reCaptureImage() {
    // Navegar de vuelta a la cámara para capturar una nueva imagen
    Get.toNamed('/camera');
  }
  
  void saveCredential() {
    // Aquí se implementaría la lógica para guardar la credencial
    SnackbarUtils.showSuccess(
      title: 'Éxito',
      message: 'Credencial guardada correctamente',
    );
    
    // Navegar directamente al home
    Get.offAllNamed('/home');
  }
  
  Future<void> shareImage() async {
    try {
      if (capturedImage.value != null) {
        await Log.i('ProcessingController', 'Compartiendo imagen...');
        
        // Crear un texto con los datos extraídos
        final StringBuffer dataText = StringBuffer();
        dataText.writeln('Datos extraídos de la credencial:');
        dataText.writeln('');
        
        credentialData.forEach((key, value) {
           final label = formatLabel(key);
           dataText.writeln('$label: $value');
         });
        
        // Compartir la imagen junto con los datos
        await Share.shareXFiles(
          [XFile(capturedImage.value!.path)],
          text: dataText.toString(),
          subject: 'Credencial procesada - Atom OCR AI',
        );
        
        await Log.i('ProcessingController', 'Imagen compartida exitosamente');
      } else {
        SnackbarUtils.showError(
          title: 'Error',
          message: 'No hay imagen para compartir',
        );
        await Log.w('ProcessingController', 'Error - No hay imagen para compartir');
      }
    } catch (e) {
      SnackbarUtils.showError(
        title: 'Error',
        message: 'Error al compartir imagen: $e',
      );
      await Log.e('ProcessingController', 'Error al compartir imagen', e);
    }
  }
  
  String formatLabel(String key) {
    switch (key) {
      case 'timestamp':
        return 'FECHA Y HORA DE CAPTURA';
      case 'nombre':
        return 'NOMBRE COMPLETO';
      case 'sexo':
        return 'SEXO';
      case 'domicilio':
        return 'DOMICILIO';
      case 'clave_de_elector':
        return 'CLAVE DE ELECTOR';
      case 'curp':
        return 'CURP';
      case 'anio_registro':
        return 'AÑO DE REGISTRO';
      case 'fecha_nacimiento':
        return 'FECHA DE NACIMIENTO';
      case 'seccion':
        return 'SECCIÓN';
      case 'vigencia':
        return 'VIGENCIA';
      default:
        return key.toUpperCase();
    }
  }

  @override
  void onClose() {
    // Restaurar todas las orientaciones al salir de la pantalla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.onClose();
  }
}