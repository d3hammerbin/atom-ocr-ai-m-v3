import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/snackbar_utils.dart';
import '../../core/services/logger_service.dart';
import '../../data/models/credential_model.dart';
import '../../data/repositories/credential_repository.dart';
import '../../routes/app_pages.dart';

class CredentialEditController extends GetxController {
  final CredentialRepository _credentialRepository = CredentialRepository();
  
  // Estado de la credencial
  final Rx<CredentialModel?> credential = Rx<CredentialModel?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Controladores de texto para los campos del formulario
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController curpController = TextEditingController();
  final TextEditingController claveElectorController = TextEditingController();
  final TextEditingController fechaNacimientoController = TextEditingController();
  final TextEditingController domicilioController = TextEditingController();
  final TextEditingController seccionController = TextEditingController();
  final TextEditingController anoRegistroController = TextEditingController();
  final TextEditingController vigenciaController = TextEditingController();

  // Dropdown values
  final RxString selectedSexo = 'H'.obs;
  final RxString selectedEstado = ''.obs;
  
  // Date picker
  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  
  // Estados de México
  final List<String> estadosMexico = [
    'Aguascalientes', 'Baja California', 'Baja California Sur', 'Campeche',
    'Chiapas', 'Chihuahua', 'Ciudad de México', 'Coahuila', 'Colima',
    'Durango', 'Estado de México', 'Guanajuato', 'Guerrero', 'Hidalgo',
    'Jalisco', 'Michoacán', 'Morelos', 'Nayarit', 'Nuevo León', 'Oaxaca',
    'Puebla', 'Querétaro', 'Quintana Roo', 'San Luis Potosí', 'Sinaloa',
    'Sonora', 'Tabasco', 'Tamaulipas', 'Tlaxcala', 'Veracruz', 'Yucatán', 'Zacatecas'
  ];
  
  // Mapeo de códigos numéricos a nombres de estados
  final Map<String, String> estadosCodigos = {
    '01': 'Aguascalientes', '02': 'Baja California', '03': 'Baja California Sur',
    '04': 'Campeche', '05': 'Coahuila', '06': 'Colima', '07': 'Chiapas',
    '08': 'Chihuahua', '09': 'Ciudad de México', '10': 'Durango',
    '11': 'Guanajuato', '12': 'Guerrero', '13': 'Hidalgo', '14': 'Jalisco',
    '15': 'Estado de México', '16': 'Michoacán', '17': 'Morelos', '18': 'Nayarit',
    '19': 'Nuevo León', '20': 'Oaxaca', '21': 'Puebla', '22': 'Querétaro',
    '23': 'Quintana Roo', '24': 'San Luis Potosí', '25': 'Sinaloa', '26': 'Sonora',
    '27': 'Tabasco', '28': 'Tamaulipas', '29': 'Tlaxcala', '30': 'Veracruz',
    '31': 'Yucatán', '32': 'Zacatecas'
  };
  
  // Opciones de sexo
  final List<Map<String, String>> sexoOptions = [
    {'value': 'H', 'label': 'H (Hombre)'},
    {'value': 'M', 'label': 'M (Mujer)'}
  ];
  
  // Clave del formulario para validación
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  
  @override
  void onInit() {
    super.onInit();
    final arguments = Get.arguments;
    int? credentialId;
    
    if (arguments is Map<String, dynamic>) {
      credentialId = arguments['credentialId'] as int?;
    } else if (arguments is int) {
      credentialId = arguments;
    }
    
    if (credentialId != null) {
      loadCredential(credentialId);
    } else {
      errorMessage.value = 'ID de credencial no válido';
    }
  }
  
  /// Carga los datos de la credencial desde la base de datos
  Future<void> loadCredential(int credentialId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      Log.i('CredentialEditController', 'Cargando credencial con ID: $credentialId');
      
      final loadedCredential = await _credentialRepository.getCredentialById(credentialId);
      
      if (loadedCredential != null) {
        credential.value = loadedCredential;
        _populateFormFields(loadedCredential);
        Log.i('CredentialEditController', 'Credencial cargada exitosamente');
      } else {
        errorMessage.value = 'No se encontró la credencial';
        Log.w('CredentialEditController', 'Credencial no encontrada con ID: $credentialId');
      }
    } catch (e) {
      errorMessage.value = 'Error al cargar la credencial: $e';
      Log.e('CredentialEditController', 'Error cargando credencial', e);
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Llena los campos del formulario con los datos de la credencial
  void _populateFormFields(CredentialModel credential) {
    nombreController.text = credential.nombre ?? '';
    curpController.text = credential.curp ?? '';
    claveElectorController.text = credential.claveElector ?? '';
    fechaNacimientoController.text = credential.fechaNacimiento ?? '';
    domicilioController.text = credential.domicilio ?? '';
    seccionController.text = credential.seccion ?? '';
    anoRegistroController.text = credential.anoRegistro ?? '';
    vigenciaController.text = credential.vigencia ?? '';
    
    // Set sexo dropdown
    selectedSexo.value = credential.sexo ?? 'H';
    
    // Set estado dropdown - convertir código numérico a nombre si es necesario
    String estadoValue = credential.estado ?? '';
    if (estadoValue.isNotEmpty) {
      // Si es un código numérico, convertir a nombre
      if (RegExp(r'^\d+$').hasMatch(estadoValue)) {
        // Asegurar formato de 2 dígitos
        String codigo = estadoValue.padLeft(2, '0');
        estadoValue = estadosCodigos[codigo] ?? estadoValue;
      }
    }
    selectedEstado.value = estadoValue;
    
    // Parse fecha de nacimiento para DatePicker
    if (credential.fechaNacimiento != null && credential.fechaNacimiento!.isNotEmpty) {
      try {
        // Intentar diferentes formatos de fecha
        DateTime? parsedDate;
        final dateStr = credential.fechaNacimiento!;
        
        if (dateStr.contains('/')) {
          // Formato DD/MM/YYYY
          final parts = dateStr.split('/');
          if (parts.length == 3) {
            parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } else if (dateStr.contains('-')) {
          // Formato YYYY-MM-DD
          parsedDate = DateTime.parse(dateStr);
        }
        
        selectedDate.value = parsedDate;
      } catch (e) {
        // Si no se puede parsear, mantener null
        selectedDate.value = null;
      }
    }
  }
  
  /// Guarda los cambios realizados en la credencial
  Future<void> saveChanges() async {
    if (!formKey.currentState!.validate()) {
      SnackbarUtils.showWarning(
        title: 'Validación',
        message: 'Por favor, corrige los errores en el formulario',
      );
      return;
    }
    
    if (credential.value == null) {
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No hay credencial para actualizar',
      );
      return;
    }
    
    try {
      isSaving.value = true;
      
      Log.i('CredentialEditController', 'Guardando cambios en credencial ID: ${credential.value!.id}');
      
      // Crear credencial actualizada con los nuevos datos
      final updatedCredential = credential.value!.copyWith(
        nombre: nombreController.text.trim(),
        curp: curpController.text.trim().toUpperCase(),
        claveElector: claveElectorController.text.trim(),
        fechaNacimiento: fechaNacimientoController.text.trim(),
        sexo: selectedSexo.value,
        domicilio: domicilioController.text.trim(),
        estado: _getEstadoCodigo(selectedEstado.value),
        municipio: credential.value!.municipio, // Mantener valor original
        localidad: credential.value!.localidad, // Mantener valor original
        seccion: seccionController.text.trim(),
        anoRegistro: anoRegistroController.text.trim(),
        vigencia: vigenciaController.text.trim(),
        tipo: credential.value!.tipo, // Mantener valor original
        lado: credential.value!.lado, // Mantener valor original
        updatedAt: DateTime.now(),
      );
      
      // Actualizar en la base de datos
      await _credentialRepository.updateCredential(updatedCredential);
      
      Log.i('CredentialEditController', 'Credencial actualizada exitosamente');
      
      SnackbarUtils.showSuccess(
        title: 'Éxito',
        message: 'Credencial actualizada correctamente',
      );
      
      // Regresar al listado de credenciales procesadas
      Get.offAllNamed(Routes.CREDENTIALS_LIST);
      
    } catch (e) {
      Log.e('CredentialEditController', 'Error actualizando credencial', e);
      SnackbarUtils.showError(
        title: 'Error',
        message: 'No se pudo actualizar la credencial: $e',
      );
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Valida el formato del CURP
  String? validateCurp(String? value) {
    if (value == null || value.isEmpty) {
      return 'El CURP es requerido';
    }
    if (value.length != 18) {
      return 'El CURP debe tener 18 caracteres';
    }
    // Validación básica de formato CURP
    final curpRegex = RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z][0-9]$');
    if (!curpRegex.hasMatch(value.toUpperCase())) {
      return 'Formato de CURP inválido';
    }
    return null;
  }
  
  /// Valida el formato de la clave de elector
  String? validateClaveElector(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Campo opcional
    }
    if (value.length < 10 || value.length > 18) {
      return 'La clave de elector debe tener entre 10 y 18 caracteres';
    }
    return null;
  }
  
  /// Valida que el campo no esté vacío
  String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }
  
  /// Valida el formato de fecha
  String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La fecha es requerida';
    }
    // Validación básica de formato DD/MM/YYYY
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Formato de fecha inválido (DD/MM/YYYY)';
    }
    return null;
  }
  
  /// Valida el sexo
  String? validateSexo(String? value) {
    if (value == null || value.isEmpty) {
      return 'El sexo es requerido';
    }
    final sexoUpper = value.toUpperCase();
    if (sexoUpper != 'M' && sexoUpper != 'H' && sexoUpper != 'F') {
      return 'El sexo debe ser M (Masculino) o H/F (Femenino)';
    }
    return null;
  }
  
  /// Seleccionar fecha de nacimiento
  void selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      selectedDate.value = picked;
      fechaNacimientoController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  /// Convierte el nombre del estado a su código numérico correspondiente
  String _getEstadoCodigo(String estadoNombre) {
    if (estadoNombre.isEmpty) return '';
    
    // Si ya es un código numérico, devolverlo tal como está
    if (RegExp(r'^\d+$').hasMatch(estadoNombre)) {
      return estadoNombre;
    }
    
    // Buscar el código correspondiente al nombre
    for (var entry in estadosCodigos.entries) {
      if (entry.value == estadoNombre) {
        return entry.key;
      }
    }
    
    // Si no se encuentra, devolver el valor original
    return estadoNombre;
  }

  @override
  void onClose() {
    nombreController.dispose();
    curpController.dispose();
    claveElectorController.dispose();
    fechaNacimientoController.dispose();
    domicilioController.dispose();
    seccionController.dispose();
    anoRegistroController.dispose();
    vigenciaController.dispose();
    super.onClose();
  }
}