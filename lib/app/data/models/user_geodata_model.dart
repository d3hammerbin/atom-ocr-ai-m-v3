/// Modelo de datos para la tabla user_geodata
class UserGeodataModel {
  final int? id;
  final int userId;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;

  const UserGeodataModel({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });

  /// Crea una instancia desde un Map (resultado de consulta SQL)
  factory UserGeodataModel.fromMap(Map<String, dynamic> map) {
    return UserGeodataModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  /// Convierte la instancia a Map para inserción/actualización SQL
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  /// Crea una copia del modelo con valores actualizados
  UserGeodataModel copyWith({
    int? id,
    int? userId,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return UserGeodataModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserGeodataModel(id: $id, userId: $userId, latitude: $latitude, longitude: $longitude, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserGeodataModel &&
        other.id == id &&
        other.userId == userId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        createdAt.hashCode;
  }
}