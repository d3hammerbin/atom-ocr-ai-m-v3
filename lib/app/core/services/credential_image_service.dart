import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../app/data/models/credential_model.dart';
import 'image_merge_service.dart';

/// Servicio para manejar imágenes de credenciales
class CredentialImageService {
  /// Combina las imágenes frontal y trasera de una credencial verticalmente con bordes
  /// [credential] - Modelo de credencial con rutas de imágenes
  /// [borderSize] - Tamaño del borde en píxeles (por defecto 15)
  /// Retorna la ruta del archivo de imagen combinada o null si no se pudo crear
  static Future<String?> createMergedCredentialImage(
    CredentialModel credential, {
    int borderSize = 15,
  }) async {
    try {
      // Verificar que existan ambas imágenes
      final frontPath = credential.frontImagePath;
      final backPath = credential.backImagePath;
      
      if (frontPath == null || frontPath.isEmpty || 
          backPath == null || backPath.isEmpty) {
        return null;
      }
      
      final frontFile = File(frontPath);
      final backFile = File(backPath);
      
      if (!await frontFile.exists() || !await backFile.exists()) {
        return null;
      }
      
      // Crear directorio temporal para la imagen combinada
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
        tempDir.path, 
        'credencial_combinada_$timestamp.png'
      );
      
      // Combinar imágenes verticalmente con bordes
      final mergedFile = await ImageMergeService.mergeImagesVerticallyWithBorders(
        frontPath,
        backPath,
        outputPath,
        borderSize: borderSize,
      );
      
      return mergedFile.path;
    } catch (e) {
      print('Error creando imagen combinada de credencial: $e');
      return null;
    }
  }
  
  /// Obtiene todas las rutas de imágenes disponibles de una credencial
  /// [credential] - Modelo de credencial
  /// [includeExtracted] - Si incluir imágenes extraídas (foto, firma, etc.)
  /// Retorna lista de rutas de archivos que existen
  static Future<List<String>> getAvailableImagePaths(
    CredentialModel credential, {
    bool includeExtracted = true,
  }) async {
    final List<String> imagePaths = [];
    
    // Imágenes principales (frontal y trasera)
    if (credential.frontImagePath != null && 
        credential.frontImagePath!.isNotEmpty) {
      final file = File(credential.frontImagePath!);
      if (await file.exists()) {
        imagePaths.add(credential.frontImagePath!);
      }
    }
    
    if (credential.backImagePath != null && 
        credential.backImagePath!.isNotEmpty) {
      final file = File(credential.backImagePath!);
      if (await file.exists()) {
        imagePaths.add(credential.backImagePath!);
      }
    }
    
    // Imágenes extraídas (si se solicitan)
    if (includeExtracted) {
      final extractedPaths = [
        credential.photoPath,
        credential.signaturePath,
        credential.qrImagePath,
        credential.barcodeImagePath,
        credential.mrzImagePath,
        credential.signatureHuellaImagePath,
      ];
      
      for (final imagePath in extractedPaths) {
        if (imagePath != null && imagePath.isNotEmpty) {
          final file = File(imagePath);
          if (await file.exists()) {
            imagePaths.add(imagePath);
          }
        }
      }
    }
    
    return imagePaths;
  }
  
  /// Crea una imagen combinada con todas las imágenes extraídas de la credencial
  /// [credential] - Modelo de credencial
  /// [borderSize] - Tamaño del borde en píxeles (por defecto 10)
  /// Retorna la ruta del archivo de imagen combinada o null si no se pudo crear
  static Future<String?> createExtractedImagesCollage(
    CredentialModel credential, {
    int borderSize = 10,
  }) async {
    try {
      final extractedPaths = await getAvailableImagePaths(
        credential, 
        includeExtracted: true,
      );
      
      // Filtrar solo imágenes extraídas (no las principales)
      final onlyExtracted = extractedPaths.where((path) => 
        path != credential.frontImagePath && 
        path != credential.backImagePath
      ).toList();
      
      if (onlyExtracted.length < 2) {
        return null; // Necesitamos al menos 2 imágenes para combinar
      }
      
      // Crear directorio temporal
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Combinar las primeras dos imágenes
      String currentPath = path.join(
        tempDir.path, 
        'collage_temp_$timestamp.png'
      );
      
      await ImageMergeService.mergeImagesVerticallyWithBorders(
        onlyExtracted[0],
        onlyExtracted[1],
        currentPath,
        borderSize: borderSize,
      );
      
      // Si hay más imágenes, combinarlas secuencialmente
      for (int i = 2; i < onlyExtracted.length; i++) {
        final nextPath = path.join(
          tempDir.path, 
          'collage_temp_${timestamp}_$i.png'
        );
        
        await ImageMergeService.mergeImagesVerticallyWithBorders(
          currentPath,
          onlyExtracted[i],
          nextPath,
          borderSize: borderSize,
        );
        
        // Eliminar archivo temporal anterior
        final oldFile = File(currentPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
        
        currentPath = nextPath;
      }
      
      // Renombrar archivo final
      final finalPath = path.join(
        tempDir.path, 
        'imagenes_extraidas_$timestamp.png'
      );
      
      final currentFile = File(currentPath);
      final finalFile = await currentFile.rename(finalPath);
      
      return finalFile.path;
    } catch (e) {
      print('Error creando collage de imágenes extraídas: $e');
      return null;
    }
  }
  
  /// Limpia archivos temporales de imágenes combinadas
  /// [filePaths] - Lista de rutas de archivos a eliminar
  static Future<void> cleanupTempImages(List<String> filePaths) async {
    for (final filePath in filePaths) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error eliminando archivo temporal: $filePath - $e');
      }
    }
  }
  
  /// Verifica si una credencial tiene imágenes frontal y trasera disponibles
  /// [credential] - Modelo de credencial
  /// Retorna true si ambas imágenes existen
  static Future<bool> hasBothMainImages(CredentialModel credential) async {
    final frontPath = credential.frontImagePath;
    final backPath = credential.backImagePath;
    
    if (frontPath == null || frontPath.isEmpty || 
        backPath == null || backPath.isEmpty) {
      return false;
    }
    
    final frontFile = File(frontPath);
    final backFile = File(backPath);
    
    return await frontFile.exists() && await backFile.exists();
  }
}