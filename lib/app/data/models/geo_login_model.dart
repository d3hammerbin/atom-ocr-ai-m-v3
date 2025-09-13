import '../../core/enums/location_method.dart';

class GeoLoginModel {
  final int? id;
  final String usuario; // PIN de 4 dígitos
  final double latitud;
  final double longitud;
  final DateTime fechaInsercion;
  final LocationMethod metodoUbicacion;

  const GeoLoginModel({
    this.id,
    required this.usuario,
    required this.latitud,
    required this.longitud,
    required this.fechaInsercion,
    this.metodoUbicacion = LocationMethod.gps,
  });

  /// Crea una instancia desde un Map (para SQLite)
  factory GeoLoginModel.fromMap(Map<String, dynamic> map) {
    return GeoLoginModel(
      id: map['id'] as int?,
      usuario: map['usuario'] as String,
      latitud: map['latitud'] as double,
      longitud: map['longitud'] as double,
      fechaInsercion: DateTime.parse(map['fecha_insercion'] as String),
      metodoUbicacion: LocationMethod.fromString(map['metodo_ubicacion'] as String? ?? 'gps'),
    );
  }

  /// Convierte la instancia a Map (para SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'usuario': usuario,
      'latitud': latitud,
      'longitud': longitud,
      'fecha_insercion': fechaInsercion.toIso8601String(),
      'metodo_ubicacion': metodoUbicacion.toDbString(),
    };
  }

  /// Crea una copia con valores modificados
  GeoLoginModel copyWith({
    int? id,
    String? usuario,
    double? latitud,
    double? longitud,
    DateTime? fechaInsercion,
    LocationMethod? metodoUbicacion,
  }) {
    return GeoLoginModel(
      id: id ?? this.id,
      usuario: usuario ?? this.usuario,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaInsercion: fechaInsercion ?? this.fechaInsercion,
      metodoUbicacion: metodoUbicacion ?? this.metodoUbicacion,
    );
  }

  @override
  String toString() {
    return 'GeoLoginModel(id: $id, usuario: $usuario, latitud: $latitud, longitud: $longitud, fechaInsercion: $fechaInsercion)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeoLoginModel &&
        other.id == id &&
        other.usuario == usuario &&
        other.latitud == latitud &&
        other.longitud == longitud &&
        other.fechaInsercion == fechaInsercion;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        usuario.hashCode ^
        latitud.hashCode ^
        longitud.hashCode ^
        fechaInsercion.hashCode;
  }
}