import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Servicio para combinar y manipular imágenes
class ImageMergeService {
  /// Combina dos imágenes verticalmente con bordes
  /// [imagePath1] - Ruta de la primera imagen (arriba)
  /// [imagePath2] - Ruta de la segunda imagen (abajo)
  /// [outputPath] - Ruta donde guardar la imagen combinada
  /// [borderSize] - Tamaño del borde en píxeles (por defecto 10)
  /// [backgroundColor] - Color de fondo y bordes (por defecto blanco)
  static Future<File> mergeImagesVerticallyWithBorders(
    String imagePath1,
    String imagePath2,
    String outputPath, {
    int borderSize = 10,
    img.ColorRgb8? backgroundColor,
  }) async {
    try {
      // Color de fondo por defecto (blanco)
      final bgColor = backgroundColor ?? img.ColorRgb8(255, 255, 255);
      
      // Cargar las imágenes
      final image1Bytes = await File(imagePath1).readAsBytes();
      final image2Bytes = await File(imagePath2).readAsBytes();
      
      final image1 = img.decodeImage(image1Bytes);
      final image2 = img.decodeImage(image2Bytes);
      
      if (image1 == null || image2 == null) {
        throw Exception('No se pudieron decodificar las imágenes');
      }
      
      // Calcular dimensiones de la imagen final
      final maxWidth = math.max(image1.width, image2.width);
      final totalWidth = maxWidth + (borderSize * 2);
      final totalHeight = image1.height + image2.height + (borderSize * 3); // 3 bordes: arriba, medio, abajo
      
      // Crear imagen combinada con fondo
      final mergedImage = img.Image(
        width: totalWidth,
        height: totalHeight,
      );
      
      // Llenar con color de fondo
      img.fill(mergedImage, color: bgColor);
      
      // Calcular posiciones centradas
      final image1X = (totalWidth - image1.width) ~/ 2;
      final image1Y = borderSize;
      
      final image2X = (totalWidth - image2.width) ~/ 2;
      final image2Y = borderSize + image1.height + borderSize;
      
      // Copiar la primera imagen (arriba)
      img.compositeImage(
        mergedImage,
        image1,
        dstX: image1X,
        dstY: image1Y,
      );
      
      // Copiar la segunda imagen (abajo)
      img.compositeImage(
        mergedImage,
        image2,
        dstX: image2X,
        dstY: image2Y,
      );
      
      // Guardar la imagen combinada
      final mergedBytes = img.encodePng(mergedImage);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(mergedBytes);
      
      return outputFile;
    } catch (e) {
      throw Exception('Error combinando imágenes: $e');
    }
  }
  
  /// Combina dos imágenes horizontalmente con bordes
  /// [imagePath1] - Ruta de la primera imagen (izquierda)
  /// [imagePath2] - Ruta de la segunda imagen (derecha)
  /// [outputPath] - Ruta donde guardar la imagen combinada
  /// [borderSize] - Tamaño del borde en píxeles (por defecto 10)
  /// [backgroundColor] - Color de fondo y bordes (por defecto blanco)
  static Future<File> mergeImagesHorizontallyWithBorders(
    String imagePath1,
    String imagePath2,
    String outputPath, {
    int borderSize = 10,
    img.ColorRgb8? backgroundColor,
  }) async {
    try {
      // Color de fondo por defecto (blanco)
      final bgColor = backgroundColor ?? img.ColorRgb8(255, 255, 255);
      
      // Cargar las imágenes
      final image1Bytes = await File(imagePath1).readAsBytes();
      final image2Bytes = await File(imagePath2).readAsBytes();
      
      final image1 = img.decodeImage(image1Bytes);
      final image2 = img.decodeImage(image2Bytes);
      
      if (image1 == null || image2 == null) {
        throw Exception('No se pudieron decodificar las imágenes');
      }
      
      // Calcular dimensiones de la imagen final
      final maxHeight = math.max(image1.height, image2.height);
      final totalWidth = image1.width + image2.width + (borderSize * 3); // 3 bordes: izq, medio, der
      final totalHeight = maxHeight + (borderSize * 2);
      
      // Crear imagen combinada con fondo
      final mergedImage = img.Image(
        width: totalWidth,
        height: totalHeight,
      );
      
      // Llenar con color de fondo
      img.fill(mergedImage, color: bgColor);
      
      // Calcular posiciones centradas
      final image1X = borderSize;
      final image1Y = (totalHeight - image1.height) ~/ 2;
      
      final image2X = borderSize + image1.width + borderSize;
      final image2Y = (totalHeight - image2.height) ~/ 2;
      
      // Copiar la primera imagen (izquierda)
      img.compositeImage(
        mergedImage,
        image1,
        dstX: image1X,
        dstY: image1Y,
      );
      
      // Copiar la segunda imagen (derecha)
      img.compositeImage(
        mergedImage,
        image2,
        dstX: image2X,
        dstY: image2Y,
      );
      
      // Guardar la imagen combinada
      final mergedBytes = img.encodePng(mergedImage);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(mergedBytes);
      
      return outputFile;
    } catch (e) {
      throw Exception('Error combinando imágenes: $e');
    }
  }
  
  /// Redimensiona una imagen manteniendo la proporción
  /// [imagePath] - Ruta de la imagen original
  /// [outputPath] - Ruta donde guardar la imagen redimensionada
  /// [maxWidth] - Ancho máximo (opcional)
  /// [maxHeight] - Alto máximo (opcional)
  static Future<File> resizeImage(
    String imagePath,
    String outputPath, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      img.Image resizedImage = image;
      
      if (maxWidth != null || maxHeight != null) {
        resizedImage = img.copyResize(
          image,
          width: maxWidth,
          height: maxHeight,
          maintainAspect: true,
        );
      }
      
      final resizedBytes = img.encodePng(resizedImage);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(resizedBytes);
      
      return outputFile;
    } catch (e) {
      throw Exception('Error redimensionando imagen: $e');
    }
  }
}