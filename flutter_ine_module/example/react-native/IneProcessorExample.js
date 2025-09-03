import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Alert,
  ScrollView,
  Image,
  ActivityIndicator,
  PermissionsAndroid,
  Platform,
} from 'react-native';
import { NativeModules } from 'react-native';
import { launchImageLibrary, launchCamera } from 'react-native-image-picker';

const { IneProcessorModule } = NativeModules;

const IneProcessorExample = () => {
  const [isProcessing, setIsProcessing] = useState(false);
  const [result, setResult] = useState(null);
  const [selectedImage, setSelectedImage] = useState(null);
  const [hasPermissions, setHasPermissions] = useState(false);

  useEffect(() => {
    requestPermissions();
  }, []);

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

        setHasPermissions(allPermissionsGranted);

        if (!allPermissionsGranted) {
          Alert.alert(
            'Permisos Requeridos',
            'Esta aplicación necesita permisos de cámara y almacenamiento para funcionar correctamente.'
          );
        }
      } catch (err) {
        console.warn('Error requesting permissions:', err);
        setHasPermissions(false);
      }
    } else {
      setHasPermissions(true);
    }
  };

  const selectImageFromGallery = () => {
    const options = {
      mediaType: 'photo',
      quality: 0.8,
      includeBase64: false,
    };

    launchImageLibrary(options, (response) => {
      if (response.didCancel || response.error) {
        return;
      }

      if (response.assets && response.assets[0]) {
        setSelectedImage(response.assets[0]);
        setResult(null);
      }
    });
  };

  const takePhoto = () => {
    const options = {
      mediaType: 'photo',
      quality: 0.8,
      includeBase64: false,
    };

    launchCamera(options, (response) => {
      if (response.didCancel || response.error) {
        return;
      }

      if (response.assets && response.assets[0]) {
        setSelectedImage(response.assets[0]);
        setResult(null);
      }
    });
  };

  const processIneDocument = async () => {
    if (!selectedImage) {
      Alert.alert('Error', 'Por favor selecciona una imagen primero');
      return;
    }

    if (!hasPermissions) {
      Alert.alert('Error', 'Permisos de cámara y almacenamiento requeridos');
      return;
    }

    setIsProcessing(true);
    setResult(null);

    try {
      console.log('Procesando imagen:', selectedImage.uri);
      
      const processingResult = await IneProcessorModule.processIneDocument(
        selectedImage.uri
      );

      console.log('Resultado del procesamiento:', processingResult);
      setResult(processingResult);

      if (processingResult.success) {
        Alert.alert(
          'Procesamiento Exitoso',
          'El documento INE ha sido procesado correctamente'
        );
      } else {
        Alert.alert(
          'Error de Procesamiento',
          processingResult.message || 'No se pudo procesar el documento'
        );
      }
    } catch (error) {
      console.error('Error procesando INE:', error);
      
      let errorMessage = 'Error desconocido';
      
      switch (error.code) {
        case 'FILE_NOT_FOUND':
          errorMessage = 'Archivo de imagen no encontrado';
          break;
        case 'INVALID_IMAGE_FORMAT':
          errorMessage = 'Formato de imagen no válido';
          break;
        case 'PROCESSING_ERROR':
          errorMessage = 'Error durante el procesamiento';
          break;
        case 'PERMISSION_DENIED':
          errorMessage = 'Permisos denegados';
          break;
        default:
          errorMessage = error.message || 'Error procesando el documento';
      }

      Alert.alert('Error', errorMessage);
      setResult({ success: false, error: errorMessage });
    } finally {
      setIsProcessing(false);
    }
  };

  const renderResult = () => {
    if (!result) return null;

    return (
      <View style={styles.resultContainer}>
        <Text style={styles.resultTitle}>Resultado del Procesamiento</Text>
        
        <View style={styles.resultItem}>
          <Text style={styles.resultLabel}>Estado:</Text>
          <Text style={[styles.resultValue, { color: result.success ? '#4CAF50' : '#F44336' }]}>
            {result.success ? 'Exitoso' : 'Error'}
          </Text>
        </View>

        {result.extractedText && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Texto Extraído:</Text>
            <Text style={styles.resultValue}>{result.extractedText}</Text>
          </View>
        )}

        {result.facesDetected && result.facesDetected.length > 0 && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Rostros Detectados:</Text>
            <Text style={styles.resultValue}>{result.facesDetected.length}</Text>
            {result.facesDetected.map((face, index) => (
              <Text key={index} style={styles.faceInfo}>
                Rostro {index + 1}: Confianza {(face.confidence * 100).toFixed(1)}%
              </Text>
            ))}
          </View>
        )}

        {result.barcodesDetected && result.barcodesDetected.length > 0 && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Códigos Detectados:</Text>
            <Text style={styles.resultValue}>{result.barcodesDetected.length}</Text>
            {result.barcodesDetected.map((barcode, index) => (
              <View key={index} style={styles.barcodeInfo}>
                <Text style={styles.barcodeFormat}>Formato: {barcode.format}</Text>
                <Text style={styles.barcodeValue}>Valor: {barcode.value}</Text>
              </View>
            ))}
          </View>
        )}

        {result.processedImagePath && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Imagen Procesada:</Text>
            <Text style={styles.resultValue}>{result.processedImagePath}</Text>
          </View>
        )}

        {result.timestamp && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Timestamp:</Text>
            <Text style={styles.resultValue}>{new Date(result.timestamp).toLocaleString()}</Text>
          </View>
        )}

        {result.error && (
          <View style={styles.resultItem}>
            <Text style={styles.resultLabel}>Error:</Text>
            <Text style={[styles.resultValue, { color: '#F44336' }]}>{result.error}</Text>
          </View>
        )}
      </View>
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>INE Processor Example</Text>
        <Text style={styles.subtitle}>Procesamiento de Documentos INE</Text>
      </View>

      <View style={styles.imageSection}>
        {selectedImage ? (
          <View style={styles.imageContainer}>
            <Image source={{ uri: selectedImage.uri }} style={styles.selectedImage} />
            <Text style={styles.imageInfo}>
              {selectedImage.fileName || 'Imagen seleccionada'}
            </Text>
          </View>
        ) : (
          <View style={styles.placeholderContainer}>
            <Text style={styles.placeholderText}>No hay imagen seleccionada</Text>
          </View>
        )}
      </View>

      <View style={styles.buttonContainer}>
        <TouchableOpacity
          style={[styles.button, styles.galleryButton]}
          onPress={selectImageFromGallery}
          disabled={isProcessing}
        >
          <Text style={styles.buttonText}>Seleccionar de Galería</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.button, styles.cameraButton]}
          onPress={takePhoto}
          disabled={isProcessing}
        >
          <Text style={styles.buttonText}>Tomar Foto</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[
            styles.button,
            styles.processButton,
            (!selectedImage || isProcessing) && styles.disabledButton
          ]}
          onPress={processIneDocument}
          disabled={!selectedImage || isProcessing}
        >
          {isProcessing ? (
            <ActivityIndicator color="#FFFFFF" size="small" />
          ) : (
            <Text style={styles.buttonText}>Procesar INE</Text>
          )}
        </TouchableOpacity>
      </View>

      {renderResult()}

      <View style={styles.infoSection}>
        <Text style={styles.infoTitle}>Información</Text>
        <Text style={styles.infoText}>
          Este ejemplo demuestra cómo integrar el módulo INE Processor en una aplicación React Native.
        </Text>
        <Text style={styles.infoText}>
          • Selecciona una imagen de la galería o toma una foto
        </Text>
        <Text style={styles.infoText}>
          • Presiona "Procesar INE" para analizar el documento
        </Text>
        <Text style={styles.infoText}>
          • Revisa los resultados del procesamiento
        </Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  header: {
    backgroundColor: '#2196F3',
    padding: 20,
    alignItems: 'center',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFFFFF',
    marginBottom: 5,
  },
  subtitle: {
    fontSize: 16,
    color: '#E3F2FD',
  },
  imageSection: {
    margin: 20,
    alignItems: 'center',
  },
  imageContainer: {
    alignItems: 'center',
  },
  selectedImage: {
    width: 300,
    height: 200,
    borderRadius: 10,
    resizeMode: 'contain',
  },
  imageInfo: {
    marginTop: 10,
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
  },
  placeholderContainer: {
    width: 300,
    height: 200,
    backgroundColor: '#E0E0E0',
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 2,
    borderColor: '#BDBDBD',
    borderStyle: 'dashed',
  },
  placeholderText: {
    fontSize: 16,
    color: '#757575',
  },
  buttonContainer: {
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  button: {
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
    marginBottom: 10,
  },
  galleryButton: {
    backgroundColor: '#4CAF50',
  },
  cameraButton: {
    backgroundColor: '#FF9800',
  },
  processButton: {
    backgroundColor: '#2196F3',
  },
  disabledButton: {
    backgroundColor: '#BDBDBD',
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: 'bold',
  },
  resultContainer: {
    margin: 20,
    padding: 15,
    backgroundColor: '#FFFFFF',
    borderRadius: 10,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  resultTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
  },
  resultItem: {
    marginBottom: 10,
  },
  resultLabel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#666',
    marginBottom: 5,
  },
  resultValue: {
    fontSize: 14,
    color: '#333',
  },
  faceInfo: {
    fontSize: 12,
    color: '#666',
    marginLeft: 10,
    marginTop: 2,
  },
  barcodeInfo: {
    marginLeft: 10,
    marginTop: 5,
    padding: 8,
    backgroundColor: '#F5F5F5',
    borderRadius: 5,
  },
  barcodeFormat: {
    fontSize: 12,
    fontWeight: 'bold',
    color: '#666',
  },
  barcodeValue: {
    fontSize: 12,
    color: '#333',
    marginTop: 2,
  },
  infoSection: {
    margin: 20,
    padding: 15,
    backgroundColor: '#E8F5E8',
    borderRadius: 10,
    borderLeftWidth: 4,
    borderLeftColor: '#4CAF50',
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#2E7D32',
    marginBottom: 10,
  },
  infoText: {
    fontSize: 14,
    color: '#388E3C',
    marginBottom: 5,
    lineHeight: 20,
  },
});

export default IneProcessorExample;