import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class SignatureExtractionService {
  /// Extrae la firma de una credencial T3 ubicada debajo de la fotografía
  /// La firma tiene el mismo ancho que la fotografía y un alto del 50% de la altura de la firma
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

      // Calcular la posición de la firma basándose en la ubicación del rostro
      final signatureRegion = _calculateSignatureRegion(originalImage, facePhotoPath);
      if (signatureRegion == null) {
        print('Error: No se pudo calcular la región de la firma');
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

  /// Calcula la región donde se encuentra la firma basándose en la posición del rostro
  /// Para credenciales T3, la firma está debajo de la fotografía del rostro
  static Map<String, int>? _calculateSignatureRegion(img.Image originalImage, String facePhotoPath) {
    try {
      // Para simplificar, asumimos que la firma está en la parte inferior izquierda
      // de la credencial, debajo de donde típicamente está la fotografía
      
      // Dimensiones típicas de una credencial INE (proporción aproximada)
      final credentialWidth = originalImage.width;
      final credentialHeight = originalImage.height;
      
      // La fotografía típicamente está en el lado izquierdo de la credencial
      // Asumimos que ocupa aproximadamente el 30% del ancho y 40% del alto
      final photoWidth = (credentialWidth * 0.3).round();
      final photoHeight = (credentialHeight * 0.4).round();
      
      // La fotografía típicamente comienza en el 5% del ancho desde la izquierda
      final photoX = (credentialWidth * 0.05).round();
      final photoY = (credentialHeight * 0.15).round(); // 15% desde arriba
      
      // La firma está debajo de la fotografía
      final signatureX = photoX + (credentialWidth * 0.03).round(); // Desplazada 3% a la derecha (4% - 1% izq)
      final signatureY = photoY + photoHeight + (photoHeight * 0.5).round() + 10 - (credentialHeight * 0.03).round(); // Bajada 50% adicional + 10 píxeles - subida 3%
      final signatureWidth = (photoWidth * 0.88).round(); // 12% menos ancho que la fotografía (5% + 7%)
      
      // El alto de la firma es el 50% de la altura de la fotografía
      final signatureHeight = (photoHeight * 0.5).round();
      
      // Verificar que la región esté dentro de los límites de la imagen
      if (signatureX + signatureWidth > credentialWidth ||
          signatureY + signatureHeight > credentialHeight) {
        print('Error: La región de la firma está fuera de los límites de la imagen');
        return null;
      }
      
      print('Región de firma calculada: x=$signatureX, y=$signatureY, width=$signatureWidth, height=$signatureHeight');
      
      return {
        'x': signatureX,
        'y': signatureY,
        'width': signatureWidth,
        'height': signatureHeight,
      };
    } catch (e) {
      print('Error al calcular la región de la firma: $e');
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