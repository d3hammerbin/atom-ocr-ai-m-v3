// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcessingResult _$ProcessingResultFromJson(Map<String, dynamic> json) =>
    ProcessingResult(
      success: json['success'] as bool,
      message: json['message'] as String?,
      errorCode: json['errorCode'] as String?,
      data: json['data'] == null
          ? null
          : CredencialIneModel.fromJson(json['data'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ProcessingResultToJson(ProcessingResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'errorCode': instance.errorCode,
      'data': instance.data,
      'metadata': instance.metadata,
      'timestamp': instance.timestamp.toIso8601String(),
    };

ProcessingOptions _$ProcessingOptionsFromJson(Map<String, dynamic> json) =>
    ProcessingOptions(
      extractSignature: json['extractSignature'] as bool? ?? true,
      extractPhoto: json['extractPhoto'] as bool? ?? true,
      performOCR: json['performOCR'] as bool? ?? true,
      detectQRCodes: json['detectQRCodes'] as bool? ?? true,
      detectBarcodes: json['detectBarcodes'] as bool? ?? true,
      validateData: json['validateData'] as bool? ?? true,
      outputDirectory: json['outputDirectory'] as String?,
      customOptions: json['customOptions'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ProcessingOptionsToJson(ProcessingOptions instance) =>
    <String, dynamic>{
      'extractSignature': instance.extractSignature,
      'extractPhoto': instance.extractPhoto,
      'performOCR': instance.performOCR,
      'detectQRCodes': instance.detectQRCodes,
      'detectBarcodes': instance.detectBarcodes,
      'validateData': instance.validateData,
      'outputDirectory': instance.outputDirectory,
      'customOptions': instance.customOptions,
    };
