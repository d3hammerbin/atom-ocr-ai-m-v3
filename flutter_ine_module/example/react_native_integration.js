/**
 * Ejemplo de integración del módulo Flutter INE Processor con React Native
 * 
 * Este archivo muestra cómo integrar y usar el módulo Flutter INE Processor
 * en una aplicación React Native para procesar credenciales INE.
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  Image,
  Alert,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { NativeModules, PermissionsAndroid, Platform } from 'react-native';
import { launchImageLibrary, launchCamera } from 'react-native-image-picker';

const { IneProcessor } = NativeModules;

const IneProcessorExample = () => {
  const [selectedImage, setSelectedImage] = useState(null);
  const [processingResult, setProcessingResult] = useState(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [moduleStatus, setModuleStatus] = useState(null);

  useEffect(() => {
    checkModuleStatus();
    requestPermissions();
  }, []);

  // Verificar el estado del módulo
  const checkModuleStatus = async () => {
    try {
      const status = await IneProcessor.getStatus();
      setModuleStatus(status);
      console.log('Estado del módulo INE:', status);
    } catch (error) {
      console.error('Error verificando estado del módulo:', error);
    }
  };

  // Solicitar permisos necesarios
  const requestPermissions = async () => {
    if (Platform.OS === 'android') {
      try {
        const granted = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.CAMERA,
          PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
        ]);

        const allPermissionsGranted = Object.values(granted).every(
          permission => permission === PermissionsAndroid.RESULTS.GRANTED
        );

        if (!allPermissionsGranted) {
          Alert.alert(
            'Permisos requeridos',
            'La aplicación necesita permisos de cámara y almacenamiento para funcionar correctamente.'
          );
        }
      } catch (error) {
        console.error('Error solicitando permisos:', error);
      }
    }
  };

  // Seleccionar imagen desde la galería
  const selectImageFromGallery = () => {
    const options = {
      mediaType: 'photo',
      quality: 1,
      includeBase64: false,
    };

    launchImageLibrary(options, (response) => {
      if (response.didCancel || response.error) {
        return;
      }

      if (response.assets && response.assets[0]) {
        setSelectedImage(response.assets[0]);
        setProcessingResult(null);
      }
    });
  };

  // Tomar foto con la cámara
  const takePhotoWithCamera = () => {
    const options = {
      mediaType: 'photo',
      quality: 1,
      includeBase64: false,
    };

    launchCamera(options, (response) => {
      if (response.didCancel || response.error) {
        return;
      }

      if (response.assets && response.assets[0]) {
        setSelectedImage(response.assets[0]);
        setProcessingResult(null);
      }
    });
  };

  // Procesar la credencial INE
  const processCredential = async () => {
    if (!selectedImage) {
      Alert.alert('Error', 'Por favor selecciona una imagen primero');
      return;
    }

    setIsProcessing(true);
    setProcessingResult(null);

    try {
      // Configurar opciones de procesamiento
      const processingOptions = {
        extractSignature: true,
        extractPhoto: true,
        enableOcr: true,
        detectQrCodes: true,
        detectBarcodes: true,
        validateData: true,
        outputDirectory: null, // Usar directorio por defecto
      };

      // Procesar la credencial
      const result = await IneProcessor.processCredential(
        selectedImage.uri,
        processingOptions
      );

      setProcessingResult(result);

      if (result.success) {
        Alert.alert(
          'Procesamiento exitoso',
          'La credencial INE ha sido procesada correctamente'
        );
      } else {
        Alert.alert(
          'Error en el procesamiento',
          result.message || 'No se pudo procesar la credencial'
        );
      }
    } catch (error) {
      console.error('Error procesando credencial:', error);
      Alert.alert(
        'Error',
        'Ocurrió un error al procesar la credencial: ' + error.message
      );
    } finally {
      setIsProcessing(false);
    }
  };

  // Obtener el último resultado
  const getLastResult = async () => {
    try {
      const lastResult = await IneProcessor.getLastResult();
      if (lastResult) {
        setProcessingResult(lastResult);
        Alert.alert('Último resultado', 'Se ha cargado el último resultado de procesamiento');
      } else {
        Alert.alert('Sin resultados', 'No hay resultados previos disponibles');
      }
    } catch (error) {
      console.error('Error obteniendo último resultado:', error);
      Alert.alert('Error', 'No se pudo obtener el último resultado');
    }
  };

  // Renderizar los datos extraídos
  const renderExtractedData = () => {
    if (!processingResult || !processingResult.success || !processingResult.data) {
      return null;
    }

    const data = processingResult.data;

    return (
      <View style={styles.resultContainer}>
        <Text style={styles.resultTitle}>Datos Extraídos:</Text>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Nombre:</Text>
          <Text style={styles.dataValue}>{data.nombre || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Apellido Paterno:</Text>
          <Text style={styles.dataValue}>{data.apellidoPaterno || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Apellido Materno:</Text>
          <Text style={styles.dataValue}>{data.apellidoMaterno || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>CURP:</Text>
          <Text style={styles.dataValue}>{data.curp || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Clave de Elector:</Text>
          <Text style={styles.dataValue}>{data.claveElector || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Fecha de Nacimiento:</Text>
          <Text style={styles.dataValue}>{data.fechaNacimiento || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Domicilio:</Text>
          <Text style={styles.dataValue}>{data.domicilio || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Sección:</Text>
          <Text style={styles.dataValue}>{data.seccion || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Sexo:</Text>
          <Text style={styles.dataValue}>{data.sexo || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Tipo de Credencial:</Text>
          <Text style={styles.dataValue}>{data.tipoCredencial || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Fecha de Emisión:</Text>
          <Text style={styles.dataValue}>{data.fechaEmision || 'N/A'}</Text>
        </View>
        
        <View style={styles.dataRow}>
          <Text style={styles.dataLabel}>Fecha de Vigencia:</Text>
          <Text style={styles.dataValue}>{data.fechaVigencia || 'N/A'}</Text>
        </View>

        {processingResult.metadata && (
          <View style={styles.metadataContainer}>
            <Text style={styles.resultTitle}>Metadatos:</Text>
            <Text style={styles.metadataText}>
              {JSON.stringify(processingResult.metadata, null, 2)}
            </Text>
          </View>
        )}
      </View>
    );
  };

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>Procesador de Credenciales INE</Text>
      
      {/* Estado del módulo */}
      {moduleStatus && (
        <View style={styles.statusContainer}>
          <Text style={styles.statusTitle}>Estado del Módulo:</Text>
          <Text style={styles.statusText}>
            {JSON.stringify(moduleStatus, null, 2)}
          </Text>
        </View>
      )}

      {/* Botones de selección de imagen */}
      <View style={styles.buttonContainer}>
        <TouchableOpacity
          style={styles.button}
          onPress={selectImageFromGallery}
        >
          <Text style={styles.buttonText}>Seleccionar de Galería</Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={styles.button}
          onPress={takePhotoWithCamera}
        >
          <Text style={styles.buttonText}>Tomar Foto</Text>
        </TouchableOpacity>
      </View>

      {/* Imagen seleccionada */}
      {selectedImage && (
        <View style={styles.imageContainer}>
          <Text style={styles.imageTitle}>Imagen Seleccionada:</Text>
          <Image source={{ uri: selectedImage.uri }} style={styles.image} />
        </View>
      )}

      {/* Botones de procesamiento */}
      <View style={styles.buttonContainer}>
        <TouchableOpacity
          style={[styles.button, styles.processButton]}
          onPress={processCredential}
          disabled={!selectedImage || isProcessing}
        >
          {isProcessing ? (
            <ActivityIndicator color="white" />
          ) : (
            <Text style={styles.buttonText}>Procesar Credencial</Text>
          )}
        </TouchableOpacity>
        
        <TouchableOpacity
          style={styles.button}
          onPress={getLastResult}
        >
          <Text style={styles.buttonText}>Último Resultado</Text>
        </TouchableOpacity>
      </View>

      {/* Resultado del procesamiento */}
      {processingResult && (
        <View style={styles.resultSection}>
          <Text style={styles.resultTitle}>
            Resultado: {processingResult.success ? 'Exitoso' : 'Error'}
          </Text>
          
          {processingResult.message && (
            <Text style={styles.messageText}>
              Mensaje: {processingResult.message}
            </Text>
          )}
          
          {renderExtractedData()}
        </View>
      )}
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 20,
    backgroundColor: '#f5f5f5',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginBottom: 20,
    color: '#333',
  },
  statusContainer: {
    backgroundColor: '#e8f4f8',
    padding: 15,
    borderRadius: 8,
    marginBottom: 20,
  },
  statusTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 5,
    color: '#2c5aa0',
  },
  statusText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: '#666',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 20,
  },
  button: {
    backgroundColor: '#007AFF',
    padding: 15,
    borderRadius: 8,
    flex: 0.48,
    alignItems: 'center',
  },
  processButton: {
    backgroundColor: '#34C759',
  },
  buttonText: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
  },
  imageContainer: {
    marginBottom: 20,
    alignItems: 'center',
  },
  imageTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
    color: '#333',
  },
  image: {
    width: 300,
    height: 200,
    borderRadius: 8,
    resizeMode: 'contain',
  },
  resultSection: {
    marginTop: 20,
  },
  resultContainer: {
    backgroundColor: 'white',
    padding: 15,
    borderRadius: 8,
    marginTop: 10,
  },
  resultTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  messageText: {
    fontSize: 14,
    marginBottom: 15,
    color: '#666',
    fontStyle: 'italic',
  },
  dataRow: {
    flexDirection: 'row',
    marginBottom: 8,
    paddingVertical: 4,
  },
  dataLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    flex: 1,
    color: '#333',
  },
  dataValue: {
    fontSize: 14,
    flex: 2,
    color: '#666',
  },
  metadataContainer: {
    marginTop: 15,
    padding: 10,
    backgroundColor: '#f8f8f8',
    borderRadius: 5,
  },
  metadataText: {
    fontSize: 12,
    fontFamily: 'monospace',
    color: '#666',
  },
});

export default IneProcessorExample;