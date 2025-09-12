import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ine_credential_processor_service.dart';
import '../../core/services/enhanced_credential_processor.dart';
import '../../core/services/logger_service.dart';
import '../../core/services/mlkit_text_recognition_service.dart';
import '../../core/services/image_quality_analysis_service.dart';
import '../../core/services/memory_management_service.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../data/models/credencial_ine_model.dart';

class LocalProcessController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  final MLKitTextRecognitionService _mlKitService = MLKitTextRecognitionService();
  
  // Variables observables
  final RxString selectedImagePath = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString extractedText = ''.obs;
  final RxBool isExtractingText = false.obs;
  final Rxn<CredencialIneModel> processedCredential = Rxn<CredencialIneModel>();
  final RxBool isProcessingCredential = false.obs;
  
  // Variables para análisis de calidad de imagen
  final RxBool isAnalyzingQuality = false.obs;
  final RxString qualityMessage = ''.obs;
  final RxBool hasQualityIssues = false.obs;
  final RxList<String> qualityProblems = <String>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeMLKit();
  }
  
  /// Inicializa el servicio ML Kit
  Future<void> _initializeMLKit() async {
    try {
      await _mlKitService.initialize();
    } catch (e) {
      errorMessage.value = 'Error al inicializar ML Kit: $e';
    }
  }
  
  @override
  void onClose() {
    _mlKitService.dispose();
    super.onClose();
  }
  
  /// Selecciona una imagen desde la galería
  Future<void> selectImageFromGallery() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Limpiar información anterior antes de seleccionar nueva imagen
      clearExtractedText();
      clearProcessedCredential();
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        selectedImagePath.value = image.path;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Imagen seleccionada correctamente',
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al seleccionar imagen: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo seleccionar la imagen',
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Limpia la imagen seleccionada
  void clearSelectedImage() {
    selectedImagePath.value = '';
    errorMessage.value = '';
    _clearQualityAnalysis();
  }
  
  /// Verifica si hay una imagen seleccionada
  bool get hasSelectedImage => selectedImagePath.value.isNotEmpty;
  
  /// Extrae texto de la imagen seleccionada usando ML Kit
  Future<void> extractTextFromSelectedImage() async {
    if (!hasSelectedImage) {
      SnackbarUtils.showWarning(
        title: 'Error',
        message: 'Primero selecciona una imagen',
      );
      return;
    }
    
    try {
      isExtractingText.value = true;
      errorMessage.value = '';
      extractedText.value = '';
      
      // Analizar calidad de imagen antes del OCR
      await _analyzeImageQuality();
      
      // Si hay problemas críticos de calidad, mostrar advertencia pero continuar
      if (hasQualityIssues.value) {
        SnackbarUtils.showWarning(
          title: 'Calidad de imagen',
          message: qualityMessage.value,
        );
      }
      
      final String? text = await _mlKitService.extractTextFromImage(selectedImagePath.value);
      
      if (text != null && text.isNotEmpty) {
        extractedText.value = text;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Texto extraído correctamente',
        );
      } else {
        extractedText.value = 'No se encontró texto en la imagen';
        SnackbarUtils.showInfo(
          title: 'Información',
          message: 'No se detectó texto en la imagen seleccionada',
        );
      }
    } catch (e) {
      errorMessage.value = 'Error al extraer texto: $e';
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo extraer el texto de la imagen',
      );
    } finally {
      isExtractingText.value = false;
    }
  }
  
  /// Limpia el texto extraído
  void clearExtractedText() {
    extractedText.value = '';
  }
  
  /// Verifica si hay texto extraído
  bool get hasExtractedText => extractedText.value.isNotEmpty;
  
  /// Analiza la calidad de iluminación de la imagen seleccionada
  Future<void> _analyzeImageQuality() async {
    if (!hasSelectedImage) return;
    
    try {
      // Preparar memoria para análisis intensivo
      await MemoryManagementService.prepareForIntensiveOperation();
      
      isAnalyzingQuality.value = true;
      hasQualityIssues.value = false;
      qualityProblems.clear();
      qualityMessage.value = '';
      
      // Analizar calidad de imagen
      final analysis = await ImageQualityAnalysisService.analyzeImageQuality(selectedImagePath.value);
      
      hasQualityIssues.value = analysis['hasProblems'] as bool;
      
      if (hasQualityIssues.value) {
        final problems = analysis['problems'] as List<String>;
        qualityProblems.assignAll(problems);
        
        final recommendations = analysis['recommendations'] as List<String>;
        qualityMessage.value = 'Problemas detectados: ${problems.join(", ")}. ${recommendations.isNotEmpty ? recommendations.first : ""}';
        
        LoggerService.instance.warning('ImageQuality', 'Problemas de calidad detectados en imagen: $problems');
      } else {
        final score = analysis['qualityScore'] as double;
        qualityMessage.value = 'Calidad aceptable (${score.toStringAsFixed(0)}/100)';
        LoggerService.instance.info('ImageQuality', 'Imagen con calidad aceptable: ${score.toStringAsFixed(1)}/100');
      }
    } catch (e) {
      LoggerService.instance.error('ImageQuality', 'Error al analizar calidad de imagen: ' + e.toString());
      qualityMessage.value = 'No se pudo analizar la calidad de la imagen';
    } finally {
      isAnalyzingQuality.value = false;
      // Limpiar memoria después del análisis
      await MemoryManagementService.cleanupAfterIntensiveOperation();
    }
  }
  
  /// Obtiene el resumen de calidad de la imagen actual
  Future<String> getImageQualitySummary() async {
    if (!hasSelectedImage) return 'No hay imagen seleccionada';
    
    try {
      // Preparar memoria para análisis
      await MemoryManagementService.prepareForIntensiveOperation();
      
      final summary = await ImageQualityAnalysisService.getQualitySummary(selectedImagePath.value);
      
      // Limpiar memoria después del análisis
      await MemoryManagementService.cleanupAfterIntensiveOperation();
      
      return summary;
    } catch (e) {
      return 'Error al obtener resumen de calidad';
    }
  }
  
  /// Verifica si la imagen es adecuada para OCR
  Future<bool> isImageSuitableForOCR() async {
    if (!hasSelectedImage) return false;
    
    try {
      return await ImageQualityAnalysisService.isImageSuitableForOCR(selectedImagePath.value);
    } catch (e) {
      return false;
    }
  }
  
  /// Obtiene información del servicio ML Kit
  Map<String, dynamic> getMLKitServiceInfo() {
    return _mlKitService.getServiceInfo();
  }

  /// Procesa credencial INE desde el texto extraído
  Future<void> processIneCredential() async {
    if (!hasExtractedText) {
      SnackbarUtils.showWarning(
        title: 'Error',
        message: 'Primero extrae texto de una imagen',
      );
      return;
    }

    try {
      isProcessingCredential.value = true;
      errorMessage.value = '';

      // Verificar si es una credencial INE
      print('🔍 DIAGNÓSTICO CONTROLADOR: Verificando si es credencial INE válida...');
      print('🔍 DIAGNÓSTICO CONTROLADOR: Texto para validación: ${extractedText.value}');
      final isValidIne = IneCredentialProcessorService.isIneCredential(extractedText.value);
      print('🔍 DIAGNÓSTICO CONTROLADOR: ¿Es credencial INE válida? $isValidIne');
      
      if (!isValidIne) {
        print('🔍 DIAGNÓSTICO CONTROLADOR: Texto rechazado - no contiene palabras clave INE');
        SnackbarUtils.showWarning(
          title: 'Información',
          message: 'La imagen no parece ser una credencial INE válida',
        );
        return;
      }

      // Usar el procesador completo con detección de lado, facial y extracción de firma
      print('🔍 DIAGNÓSTICO CONTROLADOR: Usando procesador completo con detección de lado...');
      print('🔍 DIAGNÓSTICO CONTROLADOR: Imagen seleccionada: ${selectedImagePath.value.isNotEmpty ? "SÍ" : "NO"}');
      print('🔍 DIAGNÓSTICO CONTROLADOR: Path imagen: ${selectedImagePath.value}');
      print('🔍 DIAGNÓSTICO CONTROLADOR: Texto extraído (${extractedText.value.length} chars): ${extractedText.value.substring(0, extractedText.value.length > 100 ? 100 : extractedText.value.length)}...');
      
      CredencialIneModel credential;
      
      // Si hay imagen seleccionada, usar procesamiento completo con detección de lado
      if (selectedImagePath.value.isNotEmpty) {
        credential = await IneCredentialProcessorService.processCredentialWithSideDetection(
          extractedText.value,
          selectedImagePath.value,
        );
        print('🔍 DIAGNÓSTICO CONTROLADOR: Procesamiento completo completado. Tipo: ${credential.tipo}, Lado: ${credential.lado}');
        print('🔍 DIAGNÓSTICO CONTROLADOR: Foto extraída: ${credential.photoPath.isNotEmpty ? "SÍ" : "NO"}');
        print('🔍 DIAGNÓSTICO CONTROLADOR: Firma extraída: ${credential.signaturePath.isNotEmpty ? "SÍ" : "NO"}');
      } else {
        // Fallback al procesador mejorado si no hay imagen
        credential = EnhancedCredentialProcessor.processWithDetailedLogging(extractedText.value);
        print('🔍 DIAGNÓSTICO CONTROLADOR: Procesamiento mejorado (sin imagen) completado. Tipo detectado: ${credential.tipo}');
      }

      // Log de diagnóstico
       if (selectedImagePath.value.isEmpty) {
         LoggerService.instance.warning(
           'LocalProcessController',
           'DIAGNÓSTICO: No hay imagen seleccionada, usando procesador mejorado sin detección de lado. Esto explica por qué no se detectan QR y códigos de barras.',
         );
         
         LoggerService.instance.debug(
           'LocalProcessController',
           'Texto extraído procesado con validaciones mejoradas para sección/domicilio',
         );
       } else {
         LoggerService.instance.info(
           'LocalProcessController',
           'Procesando credencial con procesador mejorado y detección de lado usando imagen: ${selectedImagePath.value}',
         );
       }

      if (IneCredentialProcessorService.validateExtractedData(credential)) {
        processedCredential.value = credential;
        SnackbarUtils.showSuccess(
          title: 'Éxito',
          message: 'Credencial INE procesada correctamente con validaciones mejoradas',
        );
      } else {
        SnackbarUtils.showWarning(
          title: 'Advertencia',
          message: 'Se procesó la credencial pero faltan algunos datos',
        );
        processedCredential.value = credential;
      }
    } catch (e) {
      errorMessage.value = 'Error al procesar credencial: $e';
      LoggerService.instance.error('LocalProcessController', 'Error en procesamiento mejorado: $e');
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo procesar la credencial INE',
      );
    } finally {
      isProcessingCredential.value = false;
    }
  }

  /// Extrae y procesa credencial INE en un solo paso
  Future<void> extractAndProcessIneCredential() async {
    await extractTextFromSelectedImage();
    if (hasExtractedText) {
      await processIneCredential();
    }
  }

  /// Limpia los datos de credencial procesada
  void clearProcessedCredential() {
    processedCredential.value = null;
  }

  /// Verifica si hay una credencial procesada
  bool get hasProcessedCredential => processedCredential.value != null;

  /// Limpia el análisis de calidad de imagen
  void _clearQualityAnalysis() {
    hasQualityIssues.value = false;
    qualityMessage.value = '';
    qualityProblems.clear();
    isAnalyzingQuality.value = false;
  }
  
  /// Limpia todos los datos
  void clearAllData() {
    clearSelectedImage();
    clearExtractedText();
    clearProcessedCredential();
    _clearQualityAnalysis();
  }
}