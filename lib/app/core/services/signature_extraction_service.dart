import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'mlkit_text_recognition_service.dart';

class SignatureExtractionService {
  /// Extrae la firma de una credencial T3 basándose en referencias de texto OCR
  /// La firma se ubica entre las etiquetas "CLAVE DE ELECTOR" y "CURP" (tope)
  /// y a la altura del valor de "FECHA DE NACIMIENTO" (borde inferior)
  /// Retorna la ruta del archivo de la firma extraída o cadena vacía si no se encuentra
  static Future<String> extractSignatureFromT3Credential({
    required String imagePath,
    required String facePhotoPath,
    required String credentialId,
  }) async {
    try {
      // Cargar la imagen original de la credencial
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        print('Error: Archivo de imagen no encontrado: $imagePath');
        return '';
      }

      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        print('Error: No se pudo decodificar la imagen');
        return '';
      }

      // Cargar la imagen del rostro para obtener sus dimensiones y posición
      final faceFile = File(facePhotoPath);
      if (!faceFile.existsSync()) {
        print('Error: Archivo de foto del rostro no encontrado: $facePhotoPath');
        return '';
      }

      // Calcular la posición de la firma basándose en referencias de texto OCR
      final signatureRegion = await _calculateSignatureRegionFromOCR(imagePath, originalImage);
      if (signatureRegion == null) {
        print('Error: No se pudo calcular la región de la firma usando OCR');
        return '';
      }

      // Extraer la región de la firma
      final signatureImage = img.copyCrop(
        originalImage,
        x: signatureRegion['x']!,
        y: signatureRegion['y']!,
        width: signatureRegion['width']!,
        height: signatureRegion['height']!,
      );

      // Mejorar la calidad de la imagen de la firma
      final enhancedSignature = _enhanceSignatureImage(signatureImage);

      // Guardar la imagen de la firma
      final signaturePath = await _saveSignatureImage(enhancedSignature, credentialId);
      
      print('Firma extraída exitosamente: $signaturePath');
      return signaturePath;
    } catch (e) {
      print('Error al extraer la firma: $e');
      return '';
    }
  }

  /// Calcula la región donde se encuentra la firma basándose en referencias de texto OCR
  /// Utiliza las posiciones de "CLAVE DE ELECTOR", "CURP" y "FECHA DE NACIMIENTO" como referencias
  static Future<Map<String, int>?> _calculateSignatureRegionFromOCR(String imagePath, img.Image originalImage) async {
    try {
      // Obtener la instancia singleton del servicio de OCR
      final ocrService = MLKitTextRecognitionService();
      
      // Extraer texto detallado con coordenadas
      final ocrResult = await ocrService.extractDetailedTextFromImage(imagePath);
      if (ocrResult == null || ocrResult['blocks'] == null) {
        print('Error: No se pudo extraer texto de la imagen para calcular la región de la firma');
        return null;
      }
      
      // Buscar las coordenadas de las etiquetas de referencia
      Map<String, dynamic>? claveElectorBounds;
      Map<String, dynamic>? curpBounds;
      Map<String, dynamic>? fechaNacimientoBounds;
      
      final blocks = ocrResult['blocks'] as List<dynamic>;
      
      // Debug: Imprimir todos los bloques de texto encontrados
      print('=== BLOQUES DE TEXTO ENCONTRADOS POR OCR ===');
      for (int i = 0; i < blocks.length; i++) {
        final blockText = (blocks[i]['text'] as String).toUpperCase();
        print('Bloque $i: "$blockText"');
      }
      print('=== FIN DE BLOQUES ===');
      
      for (final block in blocks) {
        final blockText = (block['text'] as String).toUpperCase();
        final boundingBox = block['boundingBox'] as Map<String, dynamic>;
        
        // Buscar "CLAVE DE ELECTOR" con más flexibilidad
        if ((blockText.contains('CLAVE') && blockText.contains('ELECTOR')) || 
            blockText.contains('CLAVE DE ELECTOR') || 
            blockText.contains('CLAVE ELECTOR') ||
            blockText.contains('CLAVEELECTOR')) {
          claveElectorBounds = boundingBox;
          print('✅ Encontrada CLAVE DE ELECTOR en: $boundingBox (texto: "$blockText")');
        }
        
        // Buscar "CURP" con más flexibilidad
        if (blockText.contains('CURP') && !blockText.contains('CLAVE')) {
          curpBounds = boundingBox;
          print('✅ Encontrada CURP en: $boundingBox (texto: "$blockText")');
        }
        
        // Buscar "FECHA DE NACIMIENTO" o variantes con más flexibilidad
        if ((blockText.contains('FECHA') && (blockText.contains('NACIMIENTO') || blockText.contains('NAC'))) ||
            blockText.contains('FECHANACIMIENTO') ||
            blockText.contains('FECHA NAC')) {
          fechaNacimientoBounds = boundingBox;
          print('✅ Encontrada FECHA DE NACIMIENTO en: $boundingBox (texto: "$blockText")');
        }
      }
      
      // Si no se encontraron las referencias exactas, intentar búsqueda más amplia
      if (claveElectorBounds == null || curpBounds == null) {
        print('⚠️ Búsqueda inicial fallida. Intentando búsqueda más amplia...');
        
        for (final block in blocks) {
          final blockText = (block['text'] as String).toUpperCase();
          final boundingBox = block['boundingBox'] as Map<String, dynamic>;
          
          // Búsqueda más amplia para CLAVE DE ELECTOR
          if (claveElectorBounds == null && 
              (blockText.contains('CLAVE') || blockText.contains('ELECTOR') || 
               blockText.contains('ELEC') || blockText.contains('CLAV'))) {
            claveElectorBounds = boundingBox;
            print('🔍 Encontrada referencia de CLAVE (amplia): $boundingBox (texto: "$blockText")');
          }
          
          // Búsqueda más amplia para CURP
          if (curpBounds == null && 
              (blockText.contains('CURP') || blockText.contains('CUR') || 
               blockText.length == 4 && blockText.contains('C'))) {
            curpBounds = boundingBox;
            print('🔍 Encontrada referencia de CURP (amplia): $boundingBox (texto: "$blockText")');
          }
        }
      }
      
      // Verificar que se encontraron las referencias necesarias
      if (claveElectorBounds == null || curpBounds == null) {
        print('❌ Error: No se encontraron las etiquetas de referencia necesarias (CLAVE DE ELECTOR y CURP)');
        print('   - CLAVE DE ELECTOR encontrada: ${claveElectorBounds != null}');
        print('   - CURP encontrada: ${curpBounds != null}');
        return null;
      }
      
      print('✅ Referencias encontradas exitosamente');
      
      // Calcular la región de la firma basándose en las referencias encontradas
      final credentialWidth = originalImage.width;
      final credentialHeight = originalImage.height;
      
      // El tope de la firma está entre CLAVE DE ELECTOR y CURP
      final topY = ((claveElectorBounds['bottom'] as double) + (curpBounds['top'] as double)) / 2;
      
      // El borde inferior está a la altura de FECHA DE NACIMIENTO
      // Si no se encuentra, usar una estimación basada en las otras referencias
      final bottomY = fechaNacimientoBounds != null 
          ? (fechaNacimientoBounds['bottom'] as double)
          : topY + (credentialHeight * 0.15); // 15% de la altura como fallback
      
      // La firma típicamente está en el lado izquierdo, alineada con la fotografía
      final leftX = credentialWidth * 0.05; // 5% desde el borde izquierdo
      final rightX = credentialWidth * 0.4; // Hasta el 40% del ancho
      
      final signatureX = leftX.round();
      final signatureY = topY.round();
      final signatureWidth = (rightX - leftX).round();
      final signatureHeight = (bottomY - topY).round();
      
      // Verificar que la región esté dentro de los límites de la imagen
      if (signatureX + signatureWidth > credentialWidth ||
          signatureY + signatureHeight > credentialHeight ||
          signatureX < 0 || signatureY < 0 ||
          signatureWidth <= 0 || signatureHeight <= 0) {
        print('Error: La región de la firma calculada está fuera de los límites válidos');
        print('Región calculada: x=$signatureX, y=$signatureY, width=$signatureWidth, height=$signatureHeight');
        print('Límites de imagen: width=$credentialWidth, height=$credentialHeight');
        return null;
      }
      
      print('Región de firma calculada usando OCR: x=$signatureX, y=$signatureY, width=$signatureWidth, height=$signatureHeight');
      
      return {
        'x': signatureX,
        'y': signatureY,
        'width': signatureWidth,
        'height': signatureHeight,
      };
    } catch (e) {
      print('Error al calcular la región de la firma usando OCR: $e');
      return null;
    }
  }

  /// Mejora la calidad de la imagen de la firma
  static img.Image _enhanceSignatureImage(img.Image signatureImage) {
    try {
      // Aplicar mejoras para hacer la firma más clara
      var enhanced = img.copyResize(signatureImage, width: signatureImage.width * 2);
      
      // Aumentar el contraste para hacer la firma más visible
      enhanced = img.adjustColor(enhanced, contrast: 1.5);
      
      // Ajustar el brillo
      enhanced = img.adjustColor(enhanced, brightness: 1.1);
      
      // Nota: Se removió el filtro de nitidez para evitar errores
      
      return enhanced;
    } catch (e) {
      print('Error al mejorar la imagen de la firma: $e');
      return signatureImage; // Retornar la imagen original si hay error
    }
  }

  /// Guarda la imagen de la firma en el directorio de documentos
  static Future<String> _saveSignatureImage(img.Image signatureImage, String credentialId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final signaturesDir = Directory(path.join(directory.path, 'signatures'));
      
      // Crear el directorio si no existe
      if (!signaturesDir.existsSync()) {
        signaturesDir.createSync(recursive: true);
      }
      
      // Generar nombre único para el archivo
      final fileName = 'signature_${credentialId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = path.join(signaturesDir.path, fileName);
      
      // Codificar y guardar la imagen
      final pngBytes = img.encodePng(signatureImage);
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);
      
      print('Imagen de firma guardada en: $filePath');
      return filePath;
    } catch (e) {
      print('Error al guardar la imagen de la firma: $e');
      throw Exception('No se pudo guardar la imagen de la firma: $e');
    }
  }

  /// Limpia los recursos del servicio
  static void dispose() {
    // No hay recursos específicos que limpiar en este servicio
    print('SignatureExtractionService: Recursos limpiados');
  }
}