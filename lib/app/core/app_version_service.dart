import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/logger_service.dart';

/// Servicio GetX para manejar la información de versión de la aplicación
class AppVersionService extends GetxService {
  static AppVersionService get to => Get.find();

  // Variables reactivas para la información de la versión
  final _version = ''.obs;
  final _buildNumber = ''.obs;
  final _appName = ''.obs;
  final _packageName = ''.obs;
  final _isLoading = true.obs;

  // Getters para acceder a la información de versión
  String get version => _version.value;
  String get buildNumber => _buildNumber.value;
  String get appName => _appName.value;
  String get packageName => _packageName.value;
  bool get isLoading => _isLoading.value;

  // Getter para obtener la versión completa formateada
  String get fullVersion => '${_version.value}+${_buildNumber.value}';

  // Getter para el título de la aplicación con versión
  String get appTitle =>
      '${_appName.value} v${_version.value}+${_buildNumber.value}';

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadPackageInfo();
  }

  /// Carga la información del paquete usando package_info_plus
  Future<void> _loadPackageInfo() async {
    try {
      _isLoading.value = true;
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      _appName.value = "Atom OCR AI"; //packageInfo.appName;
      _packageName.value = packageInfo.packageName;
      _version.value = packageInfo.version;
      _buildNumber.value = packageInfo.buildNumber;

      _isLoading.value = false;
    } catch (e) {
      await Log.e('AppVersionService', 'Error al cargar información del paquete', e);
      // Valores por defecto en caso de error
      _appName.value = 'Atom OCR AI';
      _version.value = '1.0.0';
      _buildNumber.value = '1';
      _isLoading.value = false;
    }
  }

  /// Método para refrescar la información de versión
  Future<void> refreshVersionInfo() async {
    await _loadPackageInfo();
  }
}
