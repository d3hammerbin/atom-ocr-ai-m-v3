class CredencialIneModel {
  // Datos del lado frontal - Comunes para T2 y T3
  final String nombre;
  final String domicilio;
  final String claveElector;
  final String curp;
  final String anoRegistro;
  final String fechaNacimiento;
  final String sexo;
  final String seccion;
  final String vigencia;
  
  // Datos del lado frontal - Específicos para T2
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String estado;
  final String municipio;
  final String localidad;
  final String emision;
  
  // Datos del MRZ (lado reverso)
  final String mrzContent;
  final String mrzDocumentNumber;
  final String mrzNationality;
  final String mrzBirthDate;
  final String mrzExpiryDate;
  final String mrzSex;
  final String mrzName;
  
  // Metadatos del procesamiento
  final String tipo;
  final String lado;
  final String photoPath;
  final String signaturePath;
  final String qrContent;
  final String qrImagePath;
  final String barcodeContent;
  final String barcodeImagePath;
  final String mrzImagePath;
  final String signatureHuellaImagePath;

  const CredencialIneModel({
    // Datos del lado frontal - Comunes para T2 y T3
    required this.nombre,
    required this.domicilio,
    required this.claveElector,
    required this.curp,
    required this.anoRegistro,
    required this.fechaNacimiento,
    required this.sexo,
    required this.seccion,
    required this.vigencia,
    
    // Datos del lado frontal - Específicos para T2
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.estado,
    required this.municipio,
    required this.localidad,
    required this.emision,
    
    // Datos del MRZ (lado reverso)
    required this.mrzContent,
    required this.mrzDocumentNumber,
    required this.mrzNationality,
    required this.mrzBirthDate,
    required this.mrzExpiryDate,
    required this.mrzSex,
    required this.mrzName,
    
    // Metadatos del procesamiento
    required this.tipo,
    required this.lado,
    required this.photoPath,
    required this.signaturePath,
    required this.qrContent,
    required this.qrImagePath,
    required this.barcodeContent,
    required this.barcodeImagePath,
    required this.mrzImagePath,
    required this.signatureHuellaImagePath,
  });

  CredencialIneModel copyWith({
    // Datos del lado frontal - Comunes para T2 y T3
    String? nombre,
    String? domicilio,
    String? claveElector,
    String? curp,
    String? anoRegistro,
    String? fechaNacimiento,
    String? sexo,
    String? seccion,
    String? vigencia,
    
    // Datos del lado frontal - Específicos para T2
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? estado,
    String? municipio,
    String? localidad,
    String? emision,
    
    // Datos del MRZ (lado reverso)
    String? mrzContent,
    String? mrzDocumentNumber,
    String? mrzNationality,
    String? mrzBirthDate,
    String? mrzExpiryDate,
    String? mrzSex,
    String? mrzName,
    
    // Metadatos del procesamiento
    String? tipo,
    String? lado,
    String? photoPath,
    String? signaturePath,
    String? qrContent,
    String? qrImagePath,
    String? barcodeContent,
    String? barcodeImagePath,
    String? mrzImagePath,
    String? signatureHuellaImagePath,
  }) {
    return CredencialIneModel(
      // Datos del lado frontal - Comunes para T2 y T3
      nombre: nombre ?? this.nombre,
      domicilio: domicilio ?? this.domicilio,
      claveElector: claveElector ?? this.claveElector,
      curp: curp ?? this.curp,
      anoRegistro: anoRegistro ?? this.anoRegistro,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      seccion: seccion ?? this.seccion,
      vigencia: vigencia ?? this.vigencia,
      
      // Datos del lado frontal - Específicos para T2
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      estado: estado ?? this.estado,
      municipio: municipio ?? this.municipio,
      localidad: localidad ?? this.localidad,
      emision: emision ?? this.emision,
      
      // Datos del MRZ (lado reverso)
      mrzContent: mrzContent ?? this.mrzContent,
      mrzDocumentNumber: mrzDocumentNumber ?? this.mrzDocumentNumber,
      mrzNationality: mrzNationality ?? this.mrzNationality,
      mrzBirthDate: mrzBirthDate ?? this.mrzBirthDate,
      mrzExpiryDate: mrzExpiryDate ?? this.mrzExpiryDate,
      mrzSex: mrzSex ?? this.mrzSex,
      mrzName: mrzName ?? this.mrzName,
      
      // Metadatos del procesamiento
      tipo: tipo ?? this.tipo,
      lado: lado ?? this.lado,
      photoPath: photoPath ?? this.photoPath,
      signaturePath: signaturePath ?? this.signaturePath,
      qrContent: qrContent ?? this.qrContent,
      qrImagePath: qrImagePath ?? this.qrImagePath,
      barcodeContent: barcodeContent ?? this.barcodeContent,
      barcodeImagePath: barcodeImagePath ?? this.barcodeImagePath,
      mrzImagePath: mrzImagePath ?? this.mrzImagePath,
      signatureHuellaImagePath: signatureHuellaImagePath ?? this.signatureHuellaImagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Datos del lado frontal - Comunes para T2 y T3
      'nombre': nombre,
      'domicilio': domicilio,
      'claveElector': claveElector,
      'curp': curp,
      'anoRegistro': anoRegistro,
      'fechaNacimiento': fechaNacimiento,
      'sexo': sexo,
      'seccion': seccion,
      'vigencia': vigencia,
      
      // Datos del lado frontal - Específicos para T2
      'apellidoPaterno': apellidoPaterno,
      'apellidoMaterno': apellidoMaterno,
      'estado': estado,
      'municipio': municipio,
      'localidad': localidad,
      'emision': emision,
      
      // Datos del MRZ (lado reverso)
      'mrzContent': mrzContent,
      'mrzDocumentNumber': mrzDocumentNumber,
      'mrzNationality': mrzNationality,
      'mrzBirthDate': mrzBirthDate,
      'mrzExpiryDate': mrzExpiryDate,
      'mrzSex': mrzSex,
      'mrzName': mrzName,
      
      // Metadatos del procesamiento
      'tipo': tipo,
      'lado': lado,
      'photoPath': photoPath,
      'signaturePath': signaturePath,
      'qrContent': qrContent,
      'qrImagePath': qrImagePath,
      'barcodeContent': barcodeContent,
      'barcodeImagePath': barcodeImagePath,
      'mrzImagePath': mrzImagePath,
      'signatureHuellaImagePath': signatureHuellaImagePath,
    };
  }

  factory CredencialIneModel.fromJson(Map<String, dynamic> json) {
    return CredencialIneModel(
      // Datos del lado frontal - Comunes para T2 y T3
      nombre: json['nombre'] ?? '',
      domicilio: json['domicilio'] ?? '',
      claveElector: json['claveElector'] ?? '',
      curp: json['curp'] ?? '',
      anoRegistro: json['anoRegistro'] ?? '',
      fechaNacimiento: json['fechaNacimiento'] ?? '',
      sexo: json['sexo'] ?? '',
      seccion: json['seccion'] ?? '',
      vigencia: json['vigencia'] ?? '',
      
      // Datos del lado frontal - Específicos para T2
      apellidoPaterno: json['apellidoPaterno'] ?? '',
      apellidoMaterno: json['apellidoMaterno'] ?? '',
      estado: json['estado'] ?? '',
      municipio: json['municipio'] ?? '',
      localidad: json['localidad'] ?? '',
      emision: json['emision'] ?? '',
      
      // Datos del MRZ (lado reverso)
      mrzContent: json['mrzContent'] ?? '',
      mrzDocumentNumber: json['mrzDocumentNumber'] ?? '',
      mrzNationality: json['mrzNationality'] ?? '',
      mrzBirthDate: json['mrzBirthDate'] ?? '',
      mrzExpiryDate: json['mrzExpiryDate'] ?? '',
      mrzSex: json['mrzSex'] ?? '',
      mrzName: json['mrzName'] ?? '',
      
      // Metadatos del procesamiento
      tipo: json['tipo'] ?? '',
      lado: json['lado'] ?? '',
      photoPath: json['photoPath'] ?? '',
      signaturePath: json['signaturePath'] ?? '',
      qrContent: json['qrContent'] ?? '',
      qrImagePath: json['qrImagePath'] ?? '',
      barcodeContent: json['barcodeContent'] ?? '',
      barcodeImagePath: json['barcodeImagePath'] ?? '',
      mrzImagePath: json['mrzImagePath'] ?? '',
      signatureHuellaImagePath: json['signatureHuellaImagePath'] ?? '',
    );
  }

  factory CredencialIneModel.empty() {
    return const CredencialIneModel(
      // Datos del lado frontal - Comunes para T2 y T3
      nombre: '',
      domicilio: '',
      claveElector: '',
      curp: '',
      anoRegistro: '',
      fechaNacimiento: '',
      sexo: '',
      seccion: '',
      vigencia: '',
      
      // Datos del lado frontal - Específicos para T2
      apellidoPaterno: '',
      apellidoMaterno: '',
      estado: '',
      municipio: '',
      localidad: '',
      emision: '',
      
      // Datos del MRZ (lado reverso)
      mrzContent: '',
      mrzDocumentNumber: '',
      mrzNationality: '',
      mrzBirthDate: '',
      mrzExpiryDate: '',
      mrzSex: '',
      mrzName: '',
      
      // Metadatos del procesamiento
      tipo: '',
      lado: '',
      photoPath: '',
      signaturePath: '',
      qrContent: '',
      qrImagePath: '',
      barcodeContent: '',
      barcodeImagePath: '',
      mrzImagePath: '',
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
        // Datos del lado frontal - Comunes para T2 y T3
        other.nombre == nombre &&
        other.domicilio == domicilio &&
        other.claveElector == claveElector &&
        other.curp == curp &&
        other.anoRegistro == anoRegistro &&
        other.fechaNacimiento == fechaNacimiento &&
        other.sexo == sexo &&
        other.seccion == seccion &&
        other.vigencia == vigencia &&
        
        // Datos del lado frontal - Específicos para T2
        other.apellidoPaterno == apellidoPaterno &&
        other.apellidoMaterno == apellidoMaterno &&
        other.estado == estado &&
        other.municipio == municipio &&
        other.localidad == localidad &&
        other.emision == emision &&
        
        // Datos del MRZ (lado reverso)
        other.mrzContent == mrzContent &&
        other.mrzDocumentNumber == mrzDocumentNumber &&
        other.mrzNationality == mrzNationality &&
        other.mrzBirthDate == mrzBirthDate &&
        other.mrzExpiryDate == mrzExpiryDate &&
        other.mrzSex == mrzSex &&
        other.mrzName == mrzName &&
        
        // Metadatos del procesamiento
        other.tipo == tipo &&
        other.lado == lado &&
        other.photoPath == photoPath &&
        other.signaturePath == signaturePath &&
        other.qrContent == qrContent &&
        other.qrImagePath == qrImagePath &&
        other.barcodeContent == barcodeContent &&
        other.barcodeImagePath == barcodeImagePath &&
        other.mrzImagePath == mrzImagePath &&
        other.signatureHuellaImagePath == signatureHuellaImagePath;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      // Datos del lado frontal - Comunes para T2 y T3
      nombre,
      domicilio,
      claveElector,
      curp,
      anoRegistro,
      fechaNacimiento,
      sexo,
      seccion,
      vigencia,
      
      // Datos del lado frontal - Específicos para T2
      apellidoPaterno,
      apellidoMaterno,
      estado,
      municipio,
      localidad,
      emision,
      
      // Datos del MRZ (lado reverso)
      mrzContent,
      mrzDocumentNumber,
      mrzNationality,
      mrzBirthDate,
      mrzExpiryDate,
      mrzSex,
      mrzName,
      
      // Metadatos del procesamiento
      tipo,
      lado,
      photoPath,
      signaturePath,
      qrContent,
      qrImagePath,
      barcodeContent,
      barcodeImagePath,
      mrzImagePath,
      signatureHuellaImagePath,
    ]);
  }
}