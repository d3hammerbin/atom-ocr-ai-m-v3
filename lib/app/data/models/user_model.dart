/// Modelo de datos para la tabla users
class UserModel {
  final int? id;
  final String identifier; // ID de 4 dígitos numéricos
  final bool enabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    this.id,
    required this.identifier,
    this.enabled = true,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  /// Crea una instancia desde un Map (resultado de consulta SQL)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      identifier: map['identifier'] as String,
      enabled: (map['enabled'] as int) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      lastLoginAt: map['last_login_at'] != null
          ? DateTime.parse(map['last_login_at'] as String)
          : null,
    );
  }

  /// Convierte la instancia a Map para inserción/actualización SQL
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'identifier': identifier,
      'enabled': enabled ? 1 : 0,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (lastLoginAt != null) 'last_login_at': lastLoginAt!.toIso8601String(),
    };
  }

  /// Crea una copia del modelo con valores actualizados
  UserModel copyWith({
    int? id,
    String? identifier,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      identifier: identifier ?? this.identifier,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Valida que el identifier tenga exactamente 4 dígitos numéricos
  static bool isValidIdentifier(String identifier) {
    if (identifier.length != 4) return false;
    return RegExp(r'^[0-9]{4}$').hasMatch(identifier);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, identifier: $identifier, enabled: $enabled, createdAt: $createdAt, updatedAt: $updatedAt, lastLoginAt: $lastLoginAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.identifier == identifier &&
        other.enabled == enabled &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLoginAt == lastLoginAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        identifier.hashCode ^
        enabled.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        lastLoginAt.hashCode;
  }
}