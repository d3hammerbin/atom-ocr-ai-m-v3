import '../../core/services/ine_credential_processor_service.dart';

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
  final String tipo; // "t2" o "t3" (T1 deshabilitado)
  final String lado; // "frontal" o "reverso" - Solo para t2 y t3
  final String estado; // Solo para t2
  final String municipio; // Solo para t2
  final String localidad; // Solo para t2
  final String photoPath; // Ruta de la imagen del rostro extraída
  final String signaturePath; // Ruta de la imagen de la firma extraída (solo T3)
  final String qrContent; // Contenido del código QR (solo T2 trasero)
  final String qrImagePath; // Ruta de la imagen del código QR extraído (solo T2 trasero)
  final String barcodeContent; // Contenido del código de barras (solo T2)
  final String barcodeImagePath; // Ruta de la imagen del código de barras extraído (solo T2)
  final String mrzContent; // Contenido completo del código MRZ (3 líneas x 30 caracteres, solo T2)
  final String mrzImagePath; // Ruta de la imagen del código MRZ extraído (solo T2)
  final String mrzDocumentNumber; // Número de documento extraído del MRZ (solo T2)
  final String mrzNationality; // Nacionalidad extraída del MRZ (solo T2)
  final String mrzBirthDate; // Fecha de nacimiento extraída del MRZ (solo T2)
  final String mrzExpiryDate; // Fecha de expiración extraída del MRZ (solo T2)
  final String mrzSex; // Sexo extraído del MRZ (solo T2)
  final String signatureHuellaImagePath; // Ruta de la imagen combinada firma-huella (solo T2 reverso)

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
      lado = '',
      estado = '',
      municipio = '',
      localidad = '',
      photoPath = '',
      signaturePath = '',
      qrContent = '',
      qrImagePath = '',
      barcodeContent = '',
      barcodeImagePath = '',
      mrzContent = '',
      mrzImagePath = '',
      mrzDocumentNumber = '',
      mrzNationality = '',
      mrzBirthDate = '',
      mrzExpiryDate = '',
      mrzSex = '',
      signatureHuellaImagePath = '';

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

  /// Convierte la instancia a un Map
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

  /// Verifica si la credencial tiene datos válidos
  bool get isValid {
    return nombre.isNotEmpty && curp.isNotEmpty && fechaNacimiento.isNotEmpty;
  }

  /// Verifica si la credencial está completamente llena
  bool get isComplete {
    // Solo validar credenciales procesables (t2 y t3)
    if (tipo != 't2' && tipo != 't3') {
      return false; // Solo se procesan credenciales T2 y T3
    }
    
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
    
    // Para credenciales t2, también verificar campos específicos
    if (tipo == 't2') {
      return baseFieldsComplete &&
             estado.isNotEmpty &&
             municipio.isNotEmpty &&
             localidad.isNotEmpty;
    }
    
    // Para credenciales t3, solo campos base
    return baseFieldsComplete;
  }

  /// Verifica si la credencial cumple con los requisitos mínimos para ser aceptable
  /// Utiliza la configuración de campos requeridos del servicio de procesamiento
  bool get isAcceptable {
    // Importar el servicio para usar la validación
    return IneCredentialProcessorService.isCredentialAcceptable(this);
  }

  @override
  String toString() {
    return 'CredencialIneModel(nombre: $nombre, domicilio: $domicilio, claveElector: $claveElector, curp: $curp, fechaNacimiento: $fechaNacimiento, sexo: $sexo, anoRegistro: $anoRegistro, seccion: $seccion, vigencia: $vigencia, tipo: $tipo, lado: $lado, estado: $estado, municipio: $municipio, localidad: $localidad)';
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
      lado,
      estado,
      municipio,
      localidad,
      photoPath,
      signaturePath,
      qrContent,
      qrImagePath,
      Object.hash(
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
      ),
    );
  }
}
