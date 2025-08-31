import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PermissionService {
  // Permisos básicos requeridos
  static const List<Permission> _basicPermissions = [
    Permission.camera,
  ];

  // Permisos de galería según la plataforma
  static const List<Permission> _galleryPermissions = [
    Permission.photos, // iOS
    Permission.mediaLibrary, // Android básico
  ];

  // Permisos de almacenamiento según la versión de Android
  static const List<Permission> _androidStoragePermissions = [
    Permission.manageExternalStorage, // Android 11+
    Permission.storage, // Android 10 y anteriores
  ];

  // Permisos para Android 13+ (API 33+)
  static const List<Permission> _android13Permissions = [
    Permission.photos, // READ_MEDIA_IMAGES
    Permission.videos, // READ_MEDIA_VIDEO
    Permission.audio,  // READ_MEDIA_AUDIO
  ];

  /// Verifica y solicita todos los permisos requeridos al inicio de la aplicación
  static Future<bool> requestAllPermissions() async {
    try {
      List<Permission> allPermissions = List.from(_basicPermissions);
      
      if (Platform.isAndroid) {
        // Para Android 13+ (API 33+), usar permisos específicos de medios
        allPermissions.addAll(_android13Permissions);
        
        // Para Android 11+ (API 30+), agregar MANAGE_EXTERNAL_STORAGE
        allPermissions.add(Permission.manageExternalStorage);
        
        // Fallback para versiones anteriores
        allPermissions.add(Permission.storage);
      } else if (Platform.isIOS) {
        // Para iOS, usar permisos de galería
        allPermissions.addAll(_galleryPermissions);
      }
      
      // Solicitar permisos por grupos para mejor UX
      bool cameraGranted = await requestCameraPermission();
      bool storageGranted = await requestStoragePermissions();
      bool galleryGranted = await requestGalleryPermissions();
      
      if (!cameraGranted || !storageGranted || !galleryGranted) {
        List<Permission> deniedPermissions = [];
        if (!cameraGranted) deniedPermissions.add(Permission.camera);
        if (!storageGranted) deniedPermissions.add(Permission.storage);
        if (!galleryGranted) deniedPermissions.add(Permission.photos);
        
        await _handleDeniedPermissions(deniedPermissions);
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error solicitando permisos: $e');
      return false;
    }
  }

  /// Solicita permisos de cámara
  static Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('Error solicitando permiso de cámara: $e');
      return false;
    }
  }

  /// Solicita permisos de almacenamiento según la versión de Android
  static Future<bool> requestStoragePermissions() async {
    try {
      if (Platform.isAndroid) {
        // Para Android 11+ intentar MANAGE_EXTERNAL_STORAGE
        final manageStorageStatus = await Permission.manageExternalStorage.request();
        if (manageStorageStatus.isGranted) {
          return true;
        }
        
        // Fallback a storage tradicional
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      }
      return true; // iOS no necesita permisos de almacenamiento explícitos
    } catch (e) {
      print('Error solicitando permisos de almacenamiento: $e');
      return false;
    }
  }

  /// Solicita permisos de galería según la plataforma
  static Future<bool> requestGalleryPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Para Android 13+, usar permisos específicos de medios
        final photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.request();
        return photosStatus.isGranted;
      }
      return true;
    } catch (e) {
      print('Error solicitando permisos de galería: $e');
      return false;
    }
  }

  /// Verifica si todos los permisos requeridos están concedidos
  static Future<bool> areAllPermissionsGranted() async {
    try {
      // Verificar permisos básicos
      for (Permission permission in _basicPermissions) {
        final status = await permission.status;
        if (!status.isGranted) {
          return false;
        }
      }
      
      // Verificar permisos de almacenamiento
      bool storageGranted = await checkStoragePermission();
      if (!storageGranted) {
        return false;
      }
      
      // Verificar permisos de galería
      bool galleryGranted = await checkGalleryPermission();
      if (!galleryGranted) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error verificando permisos: $e');
      return false;
    }
  }

  /// Solicita un permiso específico
  static Future<bool> requestSpecificPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status.isGranted;
    } catch (e) {
      print('Error solicitando permiso específico: $e');
      return false;
    }
  }

  /// Maneja los permisos denegados mostrando información al usuario
  static Future<void> _handleDeniedPermissions(List<Permission> deniedPermissions) async {
    String permissionNames = _getPermissionNames(deniedPermissions);
    
    await Get.dialog(
      AlertDialog(
        title: const Text('Permisos Requeridos'),
        content: Text(
          'La aplicación necesita los siguientes permisos para funcionar correctamente:\n\n$permissionNames\n\nPor favor, concede estos permisos en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Convierte la lista de permisos a nombres legibles
  static String _getPermissionNames(List<Permission> permissions) {
    List<String> names = [];
    
    for (Permission permission in permissions) {
      switch (permission) {
        case Permission.camera:
          names.add('• Cámara: Para capturar imágenes de credenciales');
          break;
        case Permission.storage:
        case Permission.manageExternalStorage:
          names.add('• Almacenamiento: Para guardar imágenes procesadas');
          break;
        case Permission.photos:
        case Permission.mediaLibrary:
          names.add('• Galería: Para acceder y guardar imágenes');
          break;
        default:
          names.add('• ${permission.toString().split('.').last}');
      }
    }
    
    return names.join('\n');
  }

  /// Verifica permisos específicos para la cámara
  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Verifica permisos específicos para almacenamiento
  static Future<bool> checkStoragePermission() async {
    // Verificar primero manageExternalStorage (Android 11+)
    final manageStorageStatus = await Permission.manageExternalStorage.status;
    if (manageStorageStatus.isGranted) {
      return true;
    }
    
    // Fallback a storage tradicional
    final storageStatus = await Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Verifica permisos específicos para galería
  static Future<bool> checkGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Para Android 13+, verificar READ_MEDIA_IMAGES
        final photosStatus = await Permission.photos.status;
        if (photosStatus.isGranted) {
          return true;
        }
        
        // Fallback para versiones anteriores
        final mediaStatus = await Permission.mediaLibrary.status;
        return mediaStatus.isGranted;
      } else if (Platform.isIOS) {
        final photosStatus = await Permission.photos.status;
        return photosStatus.isGranted;
      }
      return true;
    } catch (e) {
      print('Error verificando permisos de galería: $e');
      return false;
    }
  }

  /// Muestra un diálogo explicativo antes de solicitar permisos
  static Future<bool> showPermissionExplanation() async {
    bool? result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Permisos de la Aplicación'),
        content: const Text(
          'Esta aplicación necesita acceso a:\n\n'
          '• Cámara: Para capturar imágenes de credenciales\n'
          '• Almacenamiento: Para guardar y procesar imágenes\n'
          '• Galería: Para acceder a imágenes guardadas\n\n'
          '¿Deseas continuar y conceder estos permisos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Continuar'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    
    return result ?? false;
  }

  /// Inicializa el servicio de permisos al inicio de la aplicación
  static Future<bool> initialize() async {
    try {
      // Primero verificar si ya están concedidos
      bool alreadyGranted = await areAllPermissionsGranted();
      if (alreadyGranted) {
        return true;
      }
      
      // Mostrar explicación antes de solicitar
      bool userAccepted = await showPermissionExplanation();
      if (!userAccepted) {
        return false;
      }
      
      // Solicitar todos los permisos
      return await requestAllPermissions();
    } catch (e) {
      print('Error inicializando servicio de permisos: $e');
      return false;
    }
  }
}