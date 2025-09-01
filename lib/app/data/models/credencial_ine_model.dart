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
        vigencia = '';

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
    );
  }

  /// Verifica si la credencial tiene datos válidos
  bool get isValid {
    return nombre.isNotEmpty && 
           curp.isNotEmpty && 
           fechaNacimiento.isNotEmpty;
  }

  /// Verifica si la credencial está completamente llena
  bool get isComplete {
    return nombre.isNotEmpty &&
           domicilio.isNotEmpty &&
           claveElector.isNotEmpty &&
           curp.isNotEmpty &&
           fechaNacimiento.isNotEmpty &&
           sexo.isNotEmpty &&
           anoRegistro.isNotEmpty &&
           seccion.isNotEmpty &&
           vigencia.isNotEmpty;
  }

  @override
  String toString() {
    return 'CredencialIneModel(nombre: $nombre, domicilio: $domicilio, claveElector: $claveElector, curp: $curp, fechaNacimiento: $fechaNacimiento, sexo: $sexo, anoRegistro: $anoRegistro, seccion: $seccion, vigencia: $vigencia)';
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
        other.vigencia == vigencia;
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
    );
  }
}