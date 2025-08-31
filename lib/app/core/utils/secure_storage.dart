import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SecureStorage {
  static const String _hiddenDirName = '.atom_ocr_secure';
  static Directory? _secureDirectory;

  /// Obtiene el directorio oculto y seguro para almacenar imágenes
  static Future<Directory> getSecureDirectory() async {
    if (_secureDirectory != null && await _secureDirectory!.exists()) {
      return _secureDirectory!;
    }

    // Obtener directorio de datos de la aplicación (más seguro que documentos)
    final Directory appSupportDir = await getApplicationSupportDirectory();
    
    // Crear directorio oculto dentro del directorio de soporte de la aplicación
    final String securePath = '${appSupportDir.path}/$_hiddenDirName';
    _secureDirectory = Directory(securePath);

    // Crear el directorio si no existe
    if (!await _secureDirectory!.exists()) {
      await _secureDirectory!.create(recursive: true);
      
      // En Android, establecer permisos restrictivos
      if (Platform.isAndroid) {
        await _setRestrictivePermissions(_secureDirectory!);
      }
    }

    return _secureDirectory!;
  }

  /// Establece permisos restrictivos en el directorio (solo para Android)
  static Future<void> _setRestrictivePermissions(Directory directory) async {
    try {
      // Cambiar permisos del directorio para que solo la aplicación pueda acceder
      // 700 = rwx------ (solo el propietario puede leer, escribir y ejecutar)
      final result = await Process.run('chmod', ['700', directory.path]);
      if (result.exitCode != 0) {
        print('Advertencia: No se pudieron establecer permisos restrictivos');
      }
    } catch (e) {
      print('Error estableciendo permisos: $e');
    }
  }

  /// Genera un nombre de archivo único para una imagen
  static String generateSecureFileName({String prefix = 'img', String extension = 'jpg'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return '${prefix}_${timestamp}_$random.$extension';
  }

  /// Guarda datos de imagen en el directorio seguro
  static Future<File> saveImageBytes(List<int> imageBytes, {String? fileName}) async {
    final Directory secureDir = await getSecureDirectory();
    final String finalFileName = fileName ?? generateSecureFileName();
    final String filePath = '${secureDir.path}/$finalFileName';
    
    final File imageFile = File(filePath);
    await imageFile.writeAsBytes(imageBytes);
    
    return imageFile;
  }

  /// Obtiene una imagen del directorio seguro
  static Future<File?> getImageFile(String fileName) async {
    try {
      final Directory secureDir = await getSecureDirectory();
      final File imageFile = File('${secureDir.path}/$fileName');
      
      if (await imageFile.exists()) {
        return imageFile;
      }
      return null;
    } catch (e) {
      print('Error obteniendo imagen: $e');
      return null;
    }
  }

  /// Lista todas las imágenes en el directorio seguro
  static Future<List<File>> listImages() async {
    try {
      final Directory secureDir = await getSecureDirectory();
      final List<FileSystemEntity> entities = await secureDir.list().toList();
      
      return entities
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.jpg') || 
                         file.path.toLowerCase().endsWith('.png') ||
                         file.path.toLowerCase().endsWith('.jpeg'))
          .toList();
    } catch (e) {
      print('Error listando imágenes: $e');
      return [];
    }
  }

  /// Elimina una imagen específica
  static Future<bool> deleteImage(String fileName) async {
    try {
      final Directory secureDir = await getSecureDirectory();
      final File imageFile = File('${secureDir.path}/$fileName');
      
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error eliminando imagen: $e');
      return false;
    }
  }

  /// Limpia todas las imágenes del directorio seguro
  static Future<void> clearAllImages() async {
    try {
      final List<File> images = await listImages();
      for (final File image in images) {
        await image.delete();
      }
    } catch (e) {
      print('Error limpiando imágenes: $e');
    }
  }

  /// Verifica si el directorio seguro está configurado correctamente
  static Future<bool> isSecureDirectoryReady() async {
    try {
      final Directory secureDir = await getSecureDirectory();
      return await secureDir.exists();
    } catch (e) {
      return false;
    }
  }
}