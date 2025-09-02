class CredencialIneModel {
  final String nombre;
  final String domicilio;
  final String claveElector;
  final String curp;
  final String fechaNacimiento;
  final String sexo;
  final String anoRegistro;
  final String seccion;
  final String vigencia;
  final String tipo; // "Tipo 1" o "Tipo 2"
  final String estado; // Solo para Tipo 2
  final String municipio; // Solo para Tipo 2
  final String localidad; // Solo para Tipo 2

  CredencialIneModel({
    required this.nombre,
    required this.domicilio,
    required this.claveElector,
    required this.curp,
    required this.fechaNacimiento,
    required this.sexo,
    required this.anoRegistro,
    required this.seccion,
    required this.vigencia,
    required this.tipo,
    required this.estado,
    required this.municipio,
    required this.localidad,
  });

  /// Crea una instancia vacía de CredencialIneModel
  CredencialIneModel.empty()
    : nombre = '',
      domicilio = '',
      claveElector = '',
      curp = '',
      fechaNacimiento = '',
      sexo = '',
      anoRegistro = '',
      seccion = '',
      vigencia = '',
      tipo = '',
      estado = '',
      municipio = '',
      localidad = '';

  /// Crea una instancia desde un Map
  factory CredencialIneModel.fromJson(Map<String, dynamic> json) {
    return CredencialIneModel(
      nombre: json['nombre'] ?? '',
      domicilio: json['domicilio'] ?? '',
      claveElector: json['claveElector'] ?? '',
      curp: json['curp'] ?? '',
      fechaNacimiento: json['fechaNacimiento'] ?? '',
      sexo: json['sexo'] ?? '',
      anoRegistro: json['anoRegistro'] ?? '',
      seccion: json['seccion'] ?? '',
      vigencia: json['vigencia'] ?? '',
      tipo: json['tipo'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      localidad: json['localidad'] ?? '',
    );
  }

  /// Convierte la instancia a Map
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'domicilio': domicilio,
      'claveElector': claveElector,
      'curp': curp,
      'fechaNacimiento': fechaNacimiento,
      'sexo': sexo,
      'anoRegistro': anoRegistro,
      'seccion': seccion,
      'vigencia': vigencia,
      'tipo': tipo,
      'estado': estado,
      'municipio': municipio,
      'localidad': localidad,
    };
  }

  /// Crea una copia con valores modificados
  CredencialIneModel copyWith({
    String? nombre,
    String? domicilio,
    String? claveElector,
    String? curp,
    String? fechaNacimiento,
    String? sexo,
    String? anoRegistro,
    String? seccion,
    String? vigencia,
    String? tipo,
    String? estado,
    String? municipio,
    String? localidad,
  }) {
    return CredencialIneModel(
      nombre: nombre ?? this.nombre,
      domicilio: domicilio ?? this.domicilio,
      claveElector: claveElector ?? this.claveElector,
      curp: curp ?? this.curp,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      anoRegistro: anoRegistro ?? this.anoRegistro,
      seccion: seccion ?? this.seccion,
      vigencia: vigencia ?? this.vigencia,
      tipo: tipo ?? this.tipo,
      estado: estado ?? this.estado,
      municipio: municipio ?? this.municipio,
      localidad: localidad ?? this.localidad,
    );
  }

  /// Verifica si la credencial tiene datos válidos
  bool get isValid {
    return nombre.isNotEmpty && curp.isNotEmpty && fechaNacimiento.isNotEmpty;
  }

  /// Verifica si la credencial está completamente llena
  bool get isComplete {
    final baseFieldsComplete = nombre.isNotEmpty &&
           domicilio.isNotEmpty &&
           claveElector.isNotEmpty &&
           curp.isNotEmpty &&
           fechaNacimiento.isNotEmpty &&
           sexo.isNotEmpty &&
           anoRegistro.isNotEmpty &&
           seccion.isNotEmpty &&
           vigencia.isNotEmpty &&
           tipo.isNotEmpty;
    
    // Para credenciales Tipo 2, también verificar campos específicos
    if (tipo == 'Tipo 2') {
      return baseFieldsComplete &&
             estado.isNotEmpty &&
             municipio.isNotEmpty &&
             localidad.isNotEmpty;
    }
    
    return baseFieldsComplete;
  }

  @override
  String toString() {
    return 'CredencialIneModel(nombre: $nombre, domicilio: $domicilio, claveElector: $claveElector, curp: $curp, fechaNacimiento: $fechaNacimiento, sexo: $sexo, anoRegistro: $anoRegistro, seccion: $seccion, vigencia: $vigencia, tipo: $tipo, estado: $estado, municipio: $municipio, localidad: $localidad)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CredencialIneModel &&
        other.nombre == nombre &&
        other.domicilio == domicilio &&
        other.claveElector == claveElector &&
        other.curp == curp &&
        other.fechaNacimiento == fechaNacimiento &&
        other.sexo == sexo &&
        other.anoRegistro == anoRegistro &&
        other.seccion == seccion &&
        other.vigencia == vigencia &&
        other.tipo == tipo &&
        other.estado == estado &&
        other.municipio == municipio &&
        other.localidad == localidad;
  }

  @override
  int get hashCode {
    return Object.hash(
      nombre,
      domicilio,
      claveElector,
      curp,
      fechaNacimiento,
      sexo,
      anoRegistro,
      seccion,
      vigencia,
      tipo,
      estado,
      municipio,
      localidad,
    );
  }
}
