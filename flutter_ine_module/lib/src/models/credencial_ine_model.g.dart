// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credencial_ine_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CredencialIneModel _$CredencialIneModelFromJson(Map<String, dynamic> json) =>
    CredencialIneModel(
      nombre: json['nombre'] as String?,
      apellidoPaterno: json['apellidoPaterno'] as String?,
      apellidoMaterno: json['apellidoMaterno'] as String?,
      domicilio: json['domicilio'] as String?,
      claveElector: json['claveElector'] as String?,
      curp: json['curp'] as String?,
      anioRegistro: json['anioRegistro'] as String?,
      anioEmision: json['anioEmision'] as String?,
      vigencia: json['vigencia'] as String?,
      seccion: json['seccion'] as String?,
      localidad: json['localidad'] as String?,
      municipio: json['municipio'] as String?,
      estado: json['estado'] as String?,
      emision: json['emision'] as String?,
      tipoCredencial: json['tipoCredencial'] as String?,
      ladoCredencial: json['ladoCredencial'] as String?,
      fechaNacimiento: json['fechaNacimiento'] as String?,
      sexo: json['sexo'] as String?,
      ocr: json['ocr'] as String?,
      cic: json['cic'] as String?,
      numeroEmisionVertical: json['numeroEmisionVertical'] as String?,
      numeroEmisionHorizontal: json['numeroEmisionHorizontal'] as String?,
      codigoQr: json['codigoQr'] as String?,
      codigoBarras: json['codigoBarras'] as String?,
      mrz: json['mrz'] as String?,
      signatureHuellaPath: json['signatureHuellaPath'] as String?,
      fotoPath: json['fotoPath'] as String?,
      credentialPath: json['credentialPath'] as String?,
      processedImagePath: json['processedImagePath'] as String?,
      fechaProcesamiento: json['fechaProcesamiento'] == null
          ? null
          : DateTime.parse(json['fechaProcesamiento'] as String),
      diagnostico: json['diagnostico'] as Map<String, dynamic>?,
      validaciones: json['validaciones'] as Map<String, dynamic>?,
      metadatos: json['metadatos'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$CredencialIneModelToJson(CredencialIneModel instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'apellidoPaterno': instance.apellidoPaterno,
      'apellidoMaterno': instance.apellidoMaterno,
      'domicilio': instance.domicilio,
      'claveElector': instance.claveElector,
      'curp': instance.curp,
      'anioRegistro': instance.anioRegistro,
      'anioEmision': instance.anioEmision,
      'vigencia': instance.vigencia,
      'seccion': instance.seccion,
      'localidad': instance.localidad,
      'municipio': instance.municipio,
      'estado': instance.estado,
      'emision': instance.emision,
      'tipoCredencial': instance.tipoCredencial,
      'ladoCredencial': instance.ladoCredencial,
      'fechaNacimiento': instance.fechaNacimiento,
      'sexo': instance.sexo,
      'ocr': instance.ocr,
      'cic': instance.cic,
      'numeroEmisionVertical': instance.numeroEmisionVertical,
      'numeroEmisionHorizontal': instance.numeroEmisionHorizontal,
      'codigoQr': instance.codigoQr,
      'codigoBarras': instance.codigoBarras,
      'mrz': instance.mrz,
      'signatureHuellaPath': instance.signatureHuellaPath,
      'fotoPath': instance.fotoPath,
      'credentialPath': instance.credentialPath,
      'processedImagePath': instance.processedImagePath,
      'fechaProcesamiento': instance.fechaProcesamiento?.toIso8601String(),
      'diagnostico': instance.diagnostico,
      'validaciones': instance.validaciones,
      'metadatos': instance.metadatos,
    };
