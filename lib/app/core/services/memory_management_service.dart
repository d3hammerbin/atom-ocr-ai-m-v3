import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';

/// Servicio para gestionar y monitorear el uso de memoria de la aplicación
class MemoryManagementService {
  static const MethodChannel _channel = MethodChannel('memory_management');
  
  /// Umbral de memoria en MB para activar limpieza automática
  static const int _memoryThresholdMB = 150;
  
  /// Fuerza la recolección de basura
  static Future<void> forceGarbageCollection() async {
    try {
      // Intentar liberar memoria nativa primero si es posible
      if (Platform.isAndroid) {
        try {
          await _channel.invokeMethod('forceGC');
          await _channel.invokeMethod('trimMemory');
        } catch (e) {
          print('⚠️ No se pudo forzar GC nativo: $e');
        }
      }
      
      // Esperar un momento para que se complete la limpieza nativa
      await Future.delayed(Duration(milliseconds: 200));
      
      print('🧹 Recolección de basura forzada');
    } catch (e) {
      print('⚠️ Error al forzar recolección de basura: $e');
    }
  }
  
  /// Obtiene información básica de memoria (estimada)
  static Future<Map<String, dynamic>> getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod('getMemoryInfo');
        return Map<String, dynamic>.from(result ?? {});
      }
    } catch (e) {
      print('⚠️ No se pudo obtener información de memoria: $e');
    }
    
    return {
      'available': 0,
      'used': 0,
      'total': 0,
    };
  }
  
  /// Verifica si la memoria está cerca del límite
  static Future<bool> isMemoryLow() async {
    try {
      final memInfo = await getMemoryInfo();
      final usedMB = (memInfo['used'] ?? 0) / (1024 * 1024);
      return usedMB > _memoryThresholdMB;
    } catch (e) {
      print('⚠️ Error al verificar memoria: $e');
      return false;
    }
  }
  
  /// Limpia memoria antes de operaciones intensivas
  static Future<void> prepareForIntensiveOperation() async {
    print('🔧 Preparando memoria para operación intensiva...');
    
    // Forzar recolección de basura
    await forceGarbageCollection();
    
    // Esperar un momento para que se complete la limpieza
    await Future.delayed(Duration(milliseconds: 200));
    
    final isLow = await isMemoryLow();
    if (isLow) {
      print('⚠️ Memoria baja detectada antes de operación intensiva');
      // Intentar una segunda limpieza
      await forceGarbageCollection();
    }
  }
  
  /// Limpia memoria después de operaciones intensivas
  static Future<void> cleanupAfterIntensiveOperation() async {
    print('🧹 Limpiando memoria después de operación intensiva...');
    
    // Esperar un momento antes de limpiar
    await Future.delayed(Duration(milliseconds: 100));
    
    // Forzar recolección de basura
    await forceGarbageCollection();
  }
  
  /// Monitorea la memoria y ejecuta limpieza automática si es necesario
  static Future<void> monitorAndCleanup() async {
    final isLow = await isMemoryLow();
    if (isLow) {
      print('🚨 Memoria baja detectada, ejecutando limpieza automática...');
      await forceGarbageCollection();
    }
  }
}