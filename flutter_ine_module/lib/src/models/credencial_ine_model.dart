import 'package:json_annotation/json_annotation.dart';

part 'credencial_ine_model.g.dart';

@JsonSerializable()
class CredencialIneModel {
  final String? nombre;
  final String? apellidoPaterno;
  final String? apellidoMaterno;
  final String? domicilio;
  final String? claveElector;
  final String? curp;
  final String? anioRegistro;
  final String? anioEmision;
  final String? vigencia;
  final String? seccion;
  final String? localidad;
  final String? municipio;
  final String? estado;
  final String? emision;
  final String? tipoCredencial;
  final String? ladoCredencial;
  final String? fechaNacimiento;
  final String? sexo;
  final String? ocr;
  final String? cic;
  final String? numeroEmisionVertical;
  final String? numeroEmisionHorizontal;
  final String? codigoQr;
  final String? codigoBarras;
  final String? mrz;
  final String? signatureHuellaPath;
  final String? fotoPath;
  final String? credentialPath;
  final String? processedImagePath;
  final DateTime? fechaProcesamiento;
  final Map<String, dynamic>? diagnostico;
  final Map<String, dynamic>? validaciones;
  final Map<String, dynamic>? metadatos;

  const CredencialIneModel({
    this.nombre,
    this.apellidoPaterno,
    this.apellidoMaterno,
    this.domicilio,
    this.claveElector,
    this.curp,
    this.anioRegistro,
    this.anioEmision,
    this.vigencia,
    this.seccion,
    this.localidad,
    this.municipio,
    this.estado,
    this.emision,
    this.tipoCredencial,
    this.ladoCredencial,
    this.fechaNacimiento,
    this.sexo,
    this.ocr,
    this.cic,
    this.numeroEmisionVertical,
    this.numeroEmisionHorizontal,
    this.codigoQr,
    this.codigoBarras,
    this.mrz,
    this.signatureHuellaPath,
    this.fotoPath,
    this.credentialPath,
    this.processedImagePath,
    this.fechaProcesamiento,
    this.diagnostico,
    this.validaciones,
    this.metadatos,
  });

  factory CredencialIneModel.fromJson(Map<String, dynamic> json) =>
      _$CredencialIneModelFromJson(json);

  Map<String, dynamic> toJson() => _$CredencialIneModelToJson(this);

  CredencialIneModel copyWith({
    String? nombre,
    String? apellidoPaterno,
    String? apellidoMaterno,
    String? domicilio,
    String? claveElector,
    String? curp,
    String? anioRegistro,
    String? anioEmision,
    String? vigencia,
    String? seccion,
    String? localidad,
    String? municipio,
    String? estado,
    String? emision,
    String? tipoCredencial,
    String? ladoCredencial,
    String? fechaNacimiento,
    String? sexo,
    String? ocr,
    String? cic,
    String? numeroEmisionVertical,
    String? numeroEmisionHorizontal,
    String? codigoQr,
    String? codigoBarras,
    String? mrz,
    String? signatureHuellaPath,
    String? fotoPath,
    String? credentialPath,
    String? processedImagePath,
    DateTime? fechaProcesamiento,
    Map<String, dynamic>? diagnostico,
    Map<String, dynamic>? validaciones,
    Map<String, dynamic>? metadatos,
  }) {
    return CredencialIneModel(
      nombre: nombre ?? this.nombre,
      apellidoPaterno: apellidoPaterno ?? this.apellidoPaterno,
      apellidoMaterno: apellidoMaterno ?? this.apellidoMaterno,
      domicilio: domicilio ?? this.domicilio,
      claveElector: claveElector ?? this.claveElector,
      curp: curp ?? this.curp,
      anioRegistro: anioRegistro ?? this.anioRegistro,
      anioEmision: anioEmision ?? this.anioEmision,
      vigencia: vigencia ?? this.vigencia,
      seccion: seccion ?? this.seccion,
      localidad: localidad ?? this.localidad,
      municipio: municipio ?? this.municipio,
      estado: estado ?? this.estado,
      emision: emision ?? this.emision,
      tipoCredencial: tipoCredencial ?? this.tipoCredencial,
      ladoCredencial: ladoCredencial ?? this.ladoCredencial,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      sexo: sexo ?? this.sexo,
      ocr: ocr ?? this.ocr,
      cic: cic ?? this.cic,
      numeroEmisionVertical: numeroEmisionVertical ?? this.numeroEmisionVertical,
      numeroEmisionHorizontal: numeroEmisionHorizontal ?? this.numeroEmisionHorizontal,
      codigoQr: codigoQr ?? this.codigoQr,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      mrz: mrz ?? this.mrz,
      signatureHuellaPath: signatureHuellaPath ?? this.signatureHuellaPath,
      fotoPath: fotoPath ?? this.fotoPath,
      credentialPath: credentialPath ?? this.credentialPath,
      processedImagePath: processedImagePath ?? this.processedImagePath,
      fechaProcesamiento: fechaProcesamiento ?? this.fechaProcesamiento,
      diagnostico: diagnostico ?? this.diagnostico,
      validaciones: validaciones ?? this.validaciones,
      metadatos: metadatos ?? this.metadatos,
    );
  }

  @override
  String toString() {
    return 'CredencialIneModel(nombre: $nombre, apellidoPaterno: $apellidoPaterno, claveElector: $claveElector, tipoCredencial: $tipoCredencial)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CredencialIneModel &&
        other.claveElector == claveElector &&
        other.curp == curp;
  }

  @override
  int get hashCode => claveElector.hashCode ^ curp.hashCode;
}