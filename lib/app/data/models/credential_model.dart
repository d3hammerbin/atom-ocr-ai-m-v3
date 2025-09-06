/// Modelo de datos para las credenciales almacenadas en la base de datos
class CredentialModel {
  final int? id;
  final int userId;
  
  // Campos principales
  final String? nombre;
  final String? curp;
  final String? claveElector;
  final String? fechaNacimiento;
  final String? sexo;
  final String? domicilio;
  
  // Datos electorales
  final String? estado;
  final String? municipio;
  final String? localidad;
  final String? seccion;
  final String? anoRegistro;
  final String? vigencia;
  
  // Metadatos
  final String? tipo; // T2 o T3
  final String? lado; // frontal o trasera
  final DateTime? fechaCaptura;
  
  // Rutas de imágenes
  final String? photoPath;
  final String? signaturePath;
  final String? qrImagePath;
  final String? barcodeImagePath;
  final String? mrzImagePath;
  final String? signatureHuellaImagePath;
  
  // Contenidos extraídos
  final String? qrContent;
  final String? barcodeContent;
  final String? mrzContent;
  
  // Auditoría
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CredentialModel({
    this.id,
    required this.userId,
    this.nombre,
    this.curp,
    this.claveElector,
    this.fechaNacimiento,
    this.sexo,
    this.domicilio,
    this.estado,
    this.municipio,
    this.localidad,
    this.seccion,
    this.anoRegistro,
    this.vigencia,
    this.tipo,
    this.lado,
    this.fechaCaptura,
    this.photoPath,
    this.signaturePath,
    this.qrImagePath,
    this.barcodeImagePath,
    this.mrzImagePath,
    this.signatureHuellaImagePath,
    this.qrContent,
    this.barcodeContent,
    this.mrzContent,
    this.createdAt,
    this.updatedAt,
  });

  /// Constructor vacío
  factory CredentialModel.empty() {
    return const CredentialModel(
      userId: 0,
    );
  }

  /// Crea una instancia desde un Map (base de datos)
  factory CredentialModel.fromMap(Map<String, dynamic> map) {
    return CredentialModel(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      nombre: map['nombre'],
      curp: map['curp'],
      claveElector: map['clave_elector'],
      fechaNacimiento: map['fecha_nacimiento'],
      sexo: map['sexo'],
      domicilio: map['domicilio'],
      estado: map['estado'],
      municipio: map['municipio'],
      localidad: map['localidad'],
      seccion: map['seccion'],
      anoRegistro: map['ano_registro'],
      vigencia: map['vigencia'],
      tipo: map['tipo'],
      lado: map['lado'],
      fechaCaptura: map['fecha_captura'] != null 
          ? DateTime.parse(map['fecha_captura']) 
          : null,
      photoPath: map['photo_path'],
      signaturePath: map['signature_path'],
      qrImagePath: map['qr_image_path'],
      barcodeImagePath: map['barcode_image_path'],
      mrzImagePath: map['mrz_image_path'],
      signatureHuellaImagePath: map['signature_huella_image_path'],
      qrContent: map['qr_content'],
      barcodeContent: map['barcode_content'],
      mrzContent: map['mrz_content'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at']) 
          : null,
    );
  }

  /// Convierte la instancia a un Map (para base de datos)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'nombre': nombre,
      'curp': curp,
      'clave_elector': claveElector,
      'fecha_nacimiento': fechaNacimiento,
      'sexo': sexo,
      'domicilio': domicilio,
      'estado': estado,
      'municipio': municipio,
      'localidad': localidad,
      'seccion': seccion,
      'ano_registro': anoRegistro,
      'vigencia': vigencia,
      'tipo': tipo,
      'lado': lado,
      'fecha_captura': fechaCaptura?.toIso8601String(),
      'photo_path': photoPath,
      'signature_path': signaturePath,
      'qr_image_path': qrImagePath,
      'barcode_image_path': barcodeImagePath,
      'mrz_image_path': mrzImagePath,
      'signature_huella_image_path': signatureHuellaImagePath,
      'qr_content': qrContent,
      'barcode_content': barcodeContent,
      'mrz_content': mrzContent,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea una copia con valores modificados
  CredentialModel copyWith({
    int? id,
    int? userId,
    String? nombre,
    String? curp,
    String? claveElector,
    String? fechaNacimiento,
    String? sexo,
    String? domicilio,
    String? estado,
    String? municipio,
    String? localidad,
    String? seccion,
    String? anoRegistro,
    String? vigencia,
    String? tipo,
    String? lado,
    DateTime? fechaCaptura,
    String? photoPath,
    String? signaturePath,
    String? qrImagePath,
    String? barcodeImagePath,
    String? mrzImagePath,
    String? signatureHuellaImagePath,
    String? qrContent,
    String? barcodeContent,
    String? mrzContent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CredentialModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nombre: nombre ?? this.nombre,
      curp: curp ?? this.curp,
      claveElector: claveElector ?? this.claveElector,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      domicilio: domicilio ?? this.domicilio,
      estado: estado ?? this.estado,
      municipio: municipio ?? this.municipio,
      localidad: localidad ?? this.localidad,
      seccion: seccion ?? this.seccion,
      anoRegistro: anoRegistro ?? this.anoRegistro,
      vigencia: vigencia ?? this.vigencia,
      tipo: tipo ?? this.tipo,
      lado: lado ?? this.lado,
      fechaCaptura: fechaCaptura ?? this.fechaCaptura,
      photoPath: photoPath ?? this.photoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      qrImagePath: qrImagePath ?? this.qrImagePath,
      barcodeImagePath: barcodeImagePath ?? this.barcodeImagePath,
      mrzImagePath: mrzImagePath ?? this.mrzImagePath,
      signatureHuellaImagePath: signatureHuellaImagePath ?? this.signatureHuellaImagePath,
      qrContent: qrContent ?? this.qrContent,
      barcodeContent: barcodeContent ?? this.barcodeContent,
      mrzContent: mrzContent ?? this.mrzContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CredentialModel(id: $id, userId: $userId, nombre: $nombre, curp: $curp, tipo: $tipo, fechaCaptura: $fechaCaptura)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CredentialModel &&
        other.id == id &&
        other.userId == userId &&
        other.curp == curp &&
        other.claveElector == claveElector;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        curp.hashCode ^
        claveElector.hashCode;
  }
}