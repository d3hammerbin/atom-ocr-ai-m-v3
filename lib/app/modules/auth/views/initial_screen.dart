import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/app_version_service.dart';
import '../controllers/auth_controller.dart';

class InitialScreen extends GetView<AuthController> {
  const InitialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 65, 41),
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
                                'assets/SEIN_W.png',
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Obx(
                              () => TextFormField(
                                onChanged: controller.updateIdentifier,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                maxLength: 4,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0000',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    letterSpacing: 8,
                                  ),
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  errorText:
                                      controller.errorMessage.value.isNotEmpty
                                          ? controller.errorMessage.value
                                          : null,
                                  errorStyle: const TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ),
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
                                  foregroundColor: Colors.white,
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
                                  disabledBackgroundColor: Colors.grey[300],
                                  disabledForegroundColor: Colors.grey[500],
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
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
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
