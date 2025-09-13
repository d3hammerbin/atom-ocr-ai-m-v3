import 'package:native_exif/native_exif.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'gps_location_service.dart';
import 'logger_service.dart';

/// Servicio para manipular metadatos EXIF de imágenes
class ExifService {
  static const String _copyright = "D3 Catalyst";
  static const String _software = "AtomOCR AI";
  static const String _make = "AtomOCR";
  static const String _model = "Credential Scanner";

  /// Agrega metadatos completos de procesamiento a una imagen
  /// Incluye información de la aplicación, geolocalización y copyright
  static Future<bool> addProcessingMetadata({
    required String imagePath,
    required String credentialType,
    Position? gpsPosition,
    String? processingDate,
  }) async {
    try {
      await Log.i('ExifService', 'Agregando metadatos EXIF a imagen: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        await Log.e('ExifService', 'El archivo de imagen no existe: $imagePath');
        return false;
      }

      final exif = await Exif.fromPath(imagePath);
      
      // Información de la aplicación
      await exif.writeAttribute("Software", _software);
      await exif.writeAttribute("Make", _make);
      await exif.writeAttribute("Model", _model);
      await exif.writeAttribute("Copyright", _copyright);
      
      // Información del procesamiento
      final processDate = processingDate ?? DateTime.now().toIso8601String();
      await exif.writeAttribute("DateTime", processDate);
      await exif.writeAttribute("DateTimeOriginal", processDate);
      await exif.writeAttribute("DateTimeDigitized", processDate);
      await exif.writeAttribute("ImageDescription", "Processed $credentialType by $_software");
      
      // Agregar información GPS solo si se proporciona explícitamente
      if (gpsPosition != null) {
        await _addGpsMetadata(exif, gpsPosition);
      }
      // Nota: GPS se obtiene únicamente al guardar la credencial para optimizar recursos
      
      // Información técnica adicional
      await exif.writeAttribute("Artist", _copyright);
      await exif.writeAttribute("ProcessingSoftware", _software);
      
      await exif.close();
      
      await Log.i('ExifService', 'Metadatos EXIF agregados exitosamente');
      return true;
      
    } catch (e) {
      await Log.e('ExifService', 'Error agregando metadatos EXIF', e);
      return false;
    }
  }

  /// Agrega solo metadatos GPS a una imagen
  static Future<bool> addGpsMetadata({
    required String imagePath,
    required Position gpsPosition,
  }) async {
    try {
      await Log.i('ExifService', 'Agregando metadatos GPS a imagen: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        await Log.e('ExifService', 'El archivo de imagen no existe: $imagePath');
        return false;
      }

      final exif = await Exif.fromPath(imagePath);
      await _addGpsMetadata(exif, gpsPosition);
      await exif.close();
      
      await Log.i('ExifService', 'Metadatos GPS agregados exitosamente');
      return true;
      
    } catch (e) {
      await Log.e('ExifService', 'Error agregando metadatos GPS', e);
      return false;
    }
  }

  /// Remueve todos los metadatos EXIF por privacidad
  static Future<bool> stripAllMetadata(String imagePath) async {
    try {
      await Log.i('ExifService', 'Removiendo todos los metadatos EXIF de: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        await Log.e('ExifService', 'El archivo de imagen no existe: $imagePath');
        return false;
      }

      final exif = await Exif.fromPath(imagePath);
      
      // Lista de campos comunes a remover
      final fieldsToRemove = [
        "GPSLatitude", "GPSLongitude", "GPSAltitude", "GPSTimeStamp",
        "GPSLatitudeRef", "GPSLongitudeRef", "GPSAltitudeRef",
        "DateTime", "DateTimeOriginal", "DateTimeDigitized",
        "Make", "Model", "Software", "Artist",
        "Copyright", "ImageDescription", "ProcessingSoftware"
      ];
      
      for (String field in fieldsToRemove) {
        await exif.writeAttribute(field, "");
      }
      
      await exif.close();
      
      await Log.i('ExifService', 'Metadatos EXIF removidos exitosamente');
      return true;
      
    } catch (e) {
      await Log.e('ExifService', 'Error removiendo metadatos EXIF', e);
      return false;
    }
  }

  /// Remueve solo metadatos GPS por privacidad
  static Future<bool> stripGpsMetadata(String imagePath) async {
    try {
      await Log.i('ExifService', 'Removiendo metadatos GPS de: $imagePath');
      
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        await Log.e('ExifService', 'El archivo de imagen no existe: $imagePath');
        return false;
      }

      final exif = await Exif.fromPath(imagePath);
      
      // Remover solo campos GPS
      final gpsFields = [
        "GPSLatitude", "GPSLongitude", "GPSAltitude", "GPSTimeStamp",
        "GPSLatitudeRef", "GPSLongitudeRef", "GPSAltitudeRef"
      ];
      
      for (String field in gpsFields) {
        await exif.writeAttribute(field, "");
      }
      
      await exif.close();
      
      await Log.i('ExifService', 'Metadatos GPS removidos exitosamente');
      return true;
      
    } catch (e) {
      await Log.e('ExifService', 'Error removiendo metadatos GPS', e);
      return false;
    }
  }

  /// Lee los metadatos EXIF de una imagen
  static Future<Map<String, dynamic>?> readMetadata(String imagePath) async {
    try {
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        await Log.e('ExifService', 'El archivo de imagen no existe: $imagePath');
        return null;
      }

      final exif = await Exif.fromPath(imagePath);
      final attributes = await exif.getAttributes();
      await exif.close();
      
      return attributes;
      
    } catch (e) {
      await Log.e('ExifService', 'Error leyendo metadatos EXIF', e);
      return null;
    }
  }

  /// Método privado para agregar metadatos GPS
  static Future<void> _addGpsMetadata(Exif exif, Position position) async {
    try {
      // Convertir coordenadas a formato EXIF
      final latRef = position.latitude >= 0 ? "N" : "S";
      final lonRef = position.longitude >= 0 ? "E" : "W";
      
      // Convertir a grados, minutos, segundos
      final latDMS = _convertToDMS(position.latitude.abs());
      final lonDMS = _convertToDMS(position.longitude.abs());
      
      await exif.writeAttribute("GPSLatitude", latDMS);
      await exif.writeAttribute("GPSLatitudeRef", latRef);
      await exif.writeAttribute("GPSLongitude", lonDMS);
      await exif.writeAttribute("GPSLongitudeRef", lonRef);
      
      // Agregar altitud si está disponible
      if (position.altitude != 0.0) {
        await exif.writeAttribute("GPSAltitude", position.altitude.abs().toString());
        await exif.writeAttribute("GPSAltitudeRef", position.altitude >= 0 ? "0" : "1");
      }
      
      // Agregar timestamp GPS
      final timestamp = position.timestamp ?? DateTime.now();
      final gpsTime = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
      await exif.writeAttribute("GPSTimeStamp", gpsTime);
      
      await Log.i('ExifService', 
        'Metadatos GPS agregados - Lat: ${position.latitude}, Lng: ${position.longitude}, Alt: ${position.altitude}m');
      
    } catch (e) {
      await Log.e('ExifService', 'Error agregando metadatos GPS específicos', e);
    }
  }

  /// Obtiene la posición GPS actual
  static Future<Position?> _getCurrentGpsPosition() async {
    try {
      final gpsService = GpsLocationService.instance;
      return await gpsService.getCurrentPosition();
    } catch (e) {
      await Log.w('ExifService', 'No se pudo obtener posición GPS actual: ${e.toString()}');
      return null;
    }
  }

  /// Convierte coordenadas decimales a formato DMS (Grados, Minutos, Segundos)
  static String _convertToDMS(double coordinate) {
    final degrees = coordinate.floor();
    final minutesFloat = (coordinate - degrees) * 60;
    final minutes = minutesFloat.floor();
    final seconds = (minutesFloat - minutes) * 60;
    
    return "$degrees/1,$minutes/1,${seconds.toStringAsFixed(2).replaceAll('.', '')}/100";
  }
}