import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/logger_service.dart';

class LogsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<File> logFiles = <File>[].obs;
  final RxMap<String, dynamic> logStats = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadLogFiles();
    loadLogStats();
  }

  /// Carga la lista de archivos de log
  Future<void> loadLogFiles() async {
    try {
      isLoading.value = true;
      final files = await LoggerService.instance.getLogFiles();
      logFiles.assignAll(files);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar los archivos de log: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Carga las estadísticas de logs
  Future<void> loadLogStats() async {
    try {
      final stats = await LoggerService.instance.getLogStats();
      logStats.assignAll(stats);
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudieron cargar las estadísticas: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Exporta todos los logs
  Future<void> exportLogs() async {
    try {
      isLoading.value = true;
      
      final tempDir = await getTemporaryDirectory();
      final exportFile = File('${tempDir.path}/logs_export.txt');
      
      final buffer = StringBuffer();
      buffer.writeln('=== EXPORTACIÓN DE LOGS ===');
      buffer.writeln('Fecha de exportación: ${DateTime.now()}');
      buffer.writeln('Total de archivos: ${logFiles.length}');
      buffer.writeln('');
      
      for (final file in logFiles) {
        buffer.writeln('--- ${file.path.split('/').last} ---');
        try {
          final content = await file.readAsString();
          buffer.writeln(content);
        } catch (e) {
          buffer.writeln('Error leyendo archivo: $e');
        }
        buffer.writeln('');
      }
      
      await exportFile.writeAsString(buffer.toString());
      
      await Share.shareXFiles(
        [XFile(exportFile.path)],
        text: 'Logs de la aplicación',
      );
      
      Get.snackbar(
        'Éxito',
        'Logs exportados correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al exportar logs: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Limpia todos los logs
  Future<void> clearAllLogs() async {
    try {
      isLoading.value = true;
      await LoggerService.instance.clearAllLogs();
      await loadLogFiles();
      await loadLogStats();
      
      Get.snackbar(
        'Éxito',
        'Logs eliminados correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al eliminar logs: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresca los datos
  Future<void> refresh() async {
    await Future.wait([
      loadLogFiles(),
      loadLogStats(),
    ]);
  }
}