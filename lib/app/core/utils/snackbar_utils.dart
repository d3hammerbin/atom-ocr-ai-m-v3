import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utilidad para mostrar snackbars con estilo consistente
class SnackbarUtils {
  /// Muestra una snackbar con el estilo estándar de la aplicación
  /// 
  /// Características:
  /// - Posición superior
  /// - Fondo gris grafito con transparencia
  /// - Sin bordes redondeados
  /// - No interfiere con controles inferiores
  static void showSnackbar({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? colorText,
    IconData? icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: backgroundColor ?? Colors.grey[800]?.withOpacity(0.85),
      colorText: colorText ?? Colors.white,
      borderRadius: 0, // Sin bordes redondeados
      margin: const EdgeInsets.all(0),
      duration: duration,
      icon: icon != null ? Icon(icon, color: colorText ?? Colors.white) : null,
      shouldIconPulse: false,
      barBlur: 0,
      overlayBlur: 0,
      snackStyle: SnackStyle.GROUNDED,
    );
  }

  /// Muestra una snackbar de éxito
  static void showSuccess({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      title: title,
      message: message,
      duration: duration,
      icon: Icons.check_circle,
    );
  }

  /// Muestra una snackbar de error
  static void showError({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showSnackbar(
      title: title,
      message: message,
      duration: duration,
      backgroundColor: Colors.red[800]?.withOpacity(0.85),
      icon: Icons.error,
    );
  }

  /// Muestra una snackbar de advertencia
  static void showWarning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      title: title,
      message: message,
      duration: duration,
      backgroundColor: Colors.orange[800]?.withOpacity(0.85),
      icon: Icons.warning,
    );
  }

  /// Muestra una snackbar informativa
  static void showInfo({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackbar(
      title: title,
      message: message,
      duration: duration,
      backgroundColor: Colors.blue[800]?.withOpacity(0.85),
      icon: Icons.info,
    );
  }
}