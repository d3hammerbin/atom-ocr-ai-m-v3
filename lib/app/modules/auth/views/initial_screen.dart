import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/app_version_service.dart';
import '../controllers/auth_controller.dart';
import 'package:pinput/pinput.dart';

class InitialScreen extends GetView<AuthController> {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 252, 252),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header con logo/título
                    Flexible(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Inicio del contenedor del logotipo
                          Transform.translate(
                            offset: const Offset(0, 32),
                            child: Container(
                              width: 120,
                              height: 120,
                              color: Colors.transparent,
                              child: Image.asset(
                                'assets/SEIN.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          // Fin del contenedor del logotipo
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Formulario
                    Flexible(
                      flex: 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Campo de entrada para el identificador
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    0,
                                    0,
                                    0,
                                  ).withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              // Inicio del objeto Pinput para PIN
                              child: Pinput(
                                length: 4,
                                keyboardType: TextInputType.number,
                                onChanged: controller.updateIdentifier,
                                onCompleted: controller.updateIdentifier,
                                autofocus: false,
                                showCursor: false,
                                separatorBuilder:
                                    (index) => const SizedBox(width: 12),
                                defaultPinTheme: PinTheme(
                                  width: 56,
                                  height: 64,
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  decoration: BoxDecoration(
                                    //color: Colors.white,
                                    color: const Color.fromARGB(
                                      255,
                                      213,
                                      241,
                                      237,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                        255,
                                        221,
                                        221,
                                        221,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                                focusedPinTheme: PinTheme(
                                  width: 56,
                                  height: 64,
                                  textStyle: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withValues(alpha: 0.12),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Fin del objeto Pinput para PIN
                            ),
                          ),

                          // Mostrar error debajo del campo de PIN (si existe)
                          Obx(
                            () =>
                                controller.errorMessage.value.isNotEmpty
                                    ? Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        controller.errorMessage.value,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                          height: 1.2,
                                        ),
                                      ),
                                    )
                                    : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 32),

                          // Botón Comenzar
                          Obx(
                            () => SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    controller.isLoading.value
                                        ? null
                                        : controller.isValidIdentifier.value
                                        ? controller.handleStartProcess
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  // Inicio ajuste color de texto del botón (light)
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  // Fin ajuste color de texto del botón (light)
                                  elevation:
                                      controller.isValidIdentifier.value
                                          ? 8
                                          : 2,
                                  shadowColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade500,
                                ),
                                child:
                                    controller.isLoading.value
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          'Comenzar',
                                          // Inicio ajuste de color de texto del botón (light): se elimina color forzado para respetar el foregroundColor del botón (Theme.of(context).colorScheme.onPrimary)
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          // Fin ajuste de color de texto del botón (light)
                                        ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Footer
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Inicio del footer con nombre y versión de la aplicación
                          Obx(() {
                            final versionService = AppVersionService.to;
                            final footerText =
                                versionService.isLoading
                                    ? versionService.appName
                                    : versionService.appTitle;
                            return Text(
                              footerText,
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                                height: 1.4,
                              ),
                            );
                          }),
                          // Fin del footer con nombre y versión de la aplicación
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
