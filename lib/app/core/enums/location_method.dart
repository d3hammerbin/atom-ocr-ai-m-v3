/// Enumeración de métodos de ubicación disponibles
enum LocationMethod {
  /// GPS físico del dispositivo (mayor precisión)
  gps('GPS'),
  
  /// Ubicación por red (WiFi/torres celulares)
  network('Network'),
  
  /// Ubicación pasiva (obtenida por otras aplicaciones)
  passive('Passive'),
  
  /// No se pudo obtener ubicación
  none('None');

  const LocationMethod(this.displayName);
  
  final String displayName;

  /// Convierte desde string a enum
  static LocationMethod fromString(String value) {
    switch (value.toLowerCase()) {
      case 'gps':
        return LocationMethod.gps;
      case 'network':
        return LocationMethod.network;
      case 'passive':
        return LocationMethod.passive;
      case 'none':
        return LocationMethod.none;
      default:
        return LocationMethod.none;
    }
  }

  /// Convierte el enum a string para base de datos
  String toDbString() {
    return name;
  }

  /// Obtiene la prioridad del método (menor número = mayor prioridad)
  int get priority {
    switch (this) {
      case LocationMethod.gps:
        return 1;
      case LocationMethod.network:
        return 2;
      case LocationMethod.passive:
        return 3;
      case LocationMethod.none:
        return 4;
    }
  }

  /// Verifica si el método es confiable para uso en producción
  bool get isReliable {
    return this == LocationMethod.gps || this == LocationMethod.network;
  }
}