import 'package:json_annotation/json_annotation.dart';
import 'credencial_ine_model.dart';

part 'processing_result.g.dart';

@JsonSerializable()
class ProcessingResult {
  final bool success;
  final String? message;
  final String? errorCode;
  final CredencialIneModel? data;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const ProcessingResult({
    required this.success,
    this.message,
    this.errorCode,
    this.data,
    this.metadata,
    required this.timestamp,
  });

  factory ProcessingResult.success({
    CredencialIneModel? data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ProcessingResult(
      success: true,
      data: data,
      message: message ?? 'Procesamiento exitoso',
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }

  factory ProcessingResult.error({
    required String message,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return ProcessingResult(
      success: false,
      message: message,
      errorCode: errorCode,
      metadata: metadata,
      timestamp: DateTime.now(),
    );
  }

  factory ProcessingResult.fromJson(Map<String, dynamic> json) =>
      _$ProcessingResultFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingResultToJson(this);

  @override
  String toString() {
    return 'ProcessingResult(success: $success, message: $message, errorCode: $errorCode)';
  }
}

@JsonSerializable()
class ProcessingOptions {
  final bool extractSignature;
  final bool extractPhoto;
  final bool performOCR;
  final bool detectQRCodes;
  final bool detectBarcodes;
  final bool validateData;
  final String? outputDirectory;
  final Map<String, dynamic>? customOptions;

  const ProcessingOptions({
    this.extractSignature = true,
    this.extractPhoto = true,
    this.performOCR = true,
    this.detectQRCodes = true,
    this.detectBarcodes = true,
    this.validateData = true,
    this.outputDirectory,
    this.customOptions,
  });

  factory ProcessingOptions.fromJson(Map<String, dynamic> json) =>
      _$ProcessingOptionsFromJson(json);

  Map<String, dynamic> toJson() => _$ProcessingOptionsToJson(this);

  ProcessingOptions copyWith({
    bool? extractSignature,
    bool? extractPhoto,
    bool? performOCR,
    bool? detectQRCodes,
    bool? detectBarcodes,
    bool? validateData,
    String? outputDirectory,
    Map<String, dynamic>? customOptions,
  }) {
    return ProcessingOptions(
      extractSignature: extractSignature ?? this.extractSignature,
      extractPhoto: extractPhoto ?? this.extractPhoto,
      performOCR: performOCR ?? this.performOCR,
      detectQRCodes: detectQRCodes ?? this.detectQRCodes,
      detectBarcodes: detectBarcodes ?? this.detectBarcodes,
      validateData: validateData ?? this.validateData,
      outputDirectory: outputDirectory ?? this.outputDirectory,
      customOptions: customOptions ?? this.customOptions,
    );
  }
}