import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Título de la aplicación
            Text(
              'ATOMIA',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            
            // Subtítulo
            Text(
              'Escáner Inteligente de Credenciales',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 48),
            
            // Indicador de carga y estado
            Obx(() => Column(
              children: [
                CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  controller.statusMessage.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Información del estado del GPS (solo visible después de la verificación)
                if (controller.locationCapabilities.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: controller.hasOptimalGps() 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : controller.hasAnyLocationSource()
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          controller.hasOptimalGps() 
                              ? Icons.gps_fixed
                              : controller.hasAnyLocationSource()
                                  ? Icons.gps_not_fixed
                                  : Icons.gps_off,
                          color: controller.hasOptimalGps() 
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : controller.hasAnyLocationSource()
                                  ? Theme.of(context).colorScheme.onSecondaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.getGpsStatusMessage(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: controller.hasOptimalGps() 
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : controller.hasAnyLocationSource()
                                      ? Theme.of(context).colorScheme.onSecondaryContainer
                                      : Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            )),
            
            const SizedBox(height: 32),
            
            // Botones de acción (visible si hay error o problemas de GPS)
            Obx(() => (controller.hasError.value || 
                      (controller.locationCapabilities.isNotEmpty && !controller.hasAnyLocationSource()))
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        // Botón principal de reintentar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.retryInitialization,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Reintentar',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        
                        // Botones adicionales para GPS (solo si hay problemas de ubicación)
                        if (controller.locationCapabilities.isNotEmpty && !controller.hasOptimalGps()) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              // Botón para verificar GPS nuevamente
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.retryGpsVerification,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Verificar GPS',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón para habilitar servicios
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.requestLocationServices,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Habilitar GPS',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}