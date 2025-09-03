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
  final String tipo;
  final String lado;
  final String estado;
  final String municipio;
  final String localidad;
  final String photoPath;
  final String signaturePath;
  final String qrContent;
  final String qrImagePath;
  final String barcodeContent;
  final String barcodeImagePath;
  final String mrzContent;
  final String mrzImagePath;
  final String mrzDocumentNumber;
  final String mrzNationality;
  final String mrzBirthDate;
  final String mrzExpiryDate;
  final String mrzSex;
  final String signatureHuellaImagePath;

  const CredencialIneModel({
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
    required this.lado,
    required this.estado,
    required this.municipio,
    required this.localidad,
    required this.photoPath,
    required this.signaturePath,
    required this.qrContent,
    required this.qrImagePath,
    required this.barcodeContent,
    required this.barcodeImagePath,
    required this.mrzContent,
    required this.mrzImagePath,
    required this.mrzDocumentNumber,
    required this.mrzNationality,
    required this.mrzBirthDate,
    required this.mrzExpiryDate,
    required this.mrzSex,
    required this.signatureHuellaImagePath,
  });

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
    String? lado,
    String? estado,
    String? municipio,
    String? localidad,
    String? photoPath,
    String? signaturePath,
    String? qrContent,
    String? qrImagePath,
    String? barcodeContent,
    String? barcodeImagePath,
    String? mrzContent,
    String? mrzImagePath,
    String? mrzDocumentNumber,
    String? mrzNationality,
    String? mrzBirthDate,
    String? mrzExpiryDate,
    String? mrzSex,
    String? signatureHuellaImagePath,
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
      lado: lado ?? this.lado,
      estado: estado ?? this.estado,
      municipio: municipio ?? this.municipio,
      localidad: localidad ?? this.localidad,
      photoPath: photoPath ?? this.photoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      qrContent: qrContent ?? this.qrContent,
      qrImagePath: qrImagePath ?? this.qrImagePath,
      barcodeContent: barcodeContent ?? this.barcodeContent,
      barcodeImagePath: barcodeImagePath ?? this.barcodeImagePath,
      mrzContent: mrzContent ?? this.mrzContent,
      mrzImagePath: mrzImagePath ?? this.mrzImagePath,
      mrzDocumentNumber: mrzDocumentNumber ?? this.mrzDocumentNumber,
      mrzNationality: mrzNationality ?? this.mrzNationality,
      mrzBirthDate: mrzBirthDate ?? this.mrzBirthDate,
      mrzExpiryDate: mrzExpiryDate ?? this.mrzExpiryDate,
      mrzSex: mrzSex ?? this.mrzSex,
      signatureHuellaImagePath: signatureHuellaImagePath ?? this.signatureHuellaImagePath,
    );
  }

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
      'lado': lado,
      'estado': estado,
      'municipio': municipio,
      'localidad': localidad,
      'photoPath': photoPath,
      'signaturePath': signaturePath,
      'qrContent': qrContent,
      'qrImagePath': qrImagePath,
      'barcodeContent': barcodeContent,
      'barcodeImagePath': barcodeImagePath,
      'mrzContent': mrzContent,
      'mrzImagePath': mrzImagePath,
      'mrzDocumentNumber': mrzDocumentNumber,
      'mrzNationality': mrzNationality,
      'mrzBirthDate': mrzBirthDate,
      'mrzExpiryDate': mrzExpiryDate,
      'mrzSex': mrzSex,
      'signatureHuellaImagePath': signatureHuellaImagePath,
    };
  }

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
      lado: json['lado'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      localidad: json['localidad'] ?? '',
      photoPath: json['photoPath'] ?? '',
      signaturePath: json['signaturePath'] ?? '',
      qrContent: json['qrContent'] ?? '',
      qrImagePath: json['qrImagePath'] ?? '',
      barcodeContent: json['barcodeContent'] ?? '',
      barcodeImagePath: json['barcodeImagePath'] ?? '',
      mrzContent: json['mrzContent'] ?? '',
      mrzImagePath: json['mrzImagePath'] ?? '',
      mrzDocumentNumber: json['mrzDocumentNumber'] ?? '',
      mrzNationality: json['mrzNationality'] ?? '',
      mrzBirthDate: json['mrzBirthDate'] ?? '',
      mrzExpiryDate: json['mrzExpiryDate'] ?? '',
      mrzSex: json['mrzSex'] ?? '',
      signatureHuellaImagePath: json['signatureHuellaImagePath'] ?? '',
    );
  }

  factory CredencialIneModel.empty() {
    return const CredencialIneModel(
      nombre: '',
      domicilio: '',
      claveElector: '',
      curp: '',
      fechaNacimiento: '',
      sexo: '',
      anoRegistro: '',
      seccion: '',
      vigencia: '',
      tipo: '',
      lado: '',
      estado: '',
      municipio: '',
      localidad: '',
      photoPath: '',
      signaturePath: '',
      qrContent: '',
      qrImagePath: '',
      barcodeContent: '',
      barcodeImagePath: '',
      mrzContent: '',
      mrzImagePath: '',
      mrzDocumentNumber: '',
      mrzNationality: '',
      mrzBirthDate: '',
      mrzExpiryDate: '',
      mrzSex: '',
      signatureHuellaImagePath: '',
    );
  }

  @override
  String toString() {
    return 'CredencialIneModel(nombre: $nombre, claveElector: $claveElector, curp: $curp, tipo: $tipo, lado: $lado)';
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
        other.lado == lado &&
        other.estado == estado &&
        other.municipio == municipio &&
        other.localidad == localidad &&
        other.photoPath == photoPath &&
        other.signaturePath == signaturePath &&
        other.qrContent == qrContent &&
        other.qrImagePath == qrImagePath &&
        other.barcodeContent == barcodeContent &&
        other.barcodeImagePath == barcodeImagePath &&
        other.mrzContent == mrzContent &&
        other.mrzImagePath == mrzImagePath &&
        other.mrzDocumentNumber == mrzDocumentNumber &&
        other.mrzNationality == mrzNationality &&
        other.mrzBirthDate == mrzBirthDate &&
        other.mrzExpiryDate == mrzExpiryDate &&
        other.mrzSex == mrzSex &&
        other.signatureHuellaImagePath == signatureHuellaImagePath;
  }

  @override
  int get hashCode {
    return Object.hashAll([
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
      lado,
      estado,
      municipio,
      localidad,
      photoPath,
      signaturePath,
      qrContent,
      qrImagePath,
      barcodeContent,
      barcodeImagePath,
      mrzContent,
      mrzImagePath,
      mrzDocumentNumber,
      mrzNationality,
      mrzBirthDate,
      mrzExpiryDate,
      mrzSex,
      signatureHuellaImagePath,
    ]);
  }
}