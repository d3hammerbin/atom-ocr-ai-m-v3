import React, { useState } from 'react';
import {
  View,
  Button,
  Text,
  Alert,
  StyleSheet,
  ScrollView,
  ActivityIndicator,
} from 'react-native';
import { launchImageLibrary } from 'react-native-image-picker';
import IneProcessor, { CredentialResult } from 'react-native-ine-processor';

const IneScanner = () => {
  const [result, setResult] = useState<CredentialResult | null>(null);
  const [processing, setProcessing] = useState(false);

  const selectAndProcessImage = () => {
    launchImageLibrary(
      {
        mediaType: 'photo',
        quality: 0.8,
        maxWidth: 1920,
        maxHeight: 1080,
      },
      async (response) => {
        if (response.assets && response.assets[0]) {
          const imagePath = response.assets[0].uri;

          setProcessing(true);

          try {
            // Verificar si es una credencial válida
            const isValid = await IneProcessor.isValidCredential(imagePath);

            if (!isValid) {
              Alert.alert('Error', 'La imagen no parece ser una credencial INE');
              return;
            }

            // Procesar la credencial
            const processingResult = await IneProcessor.processCredential(
              imagePath,
              {
                strictValidation: true,
                ocrMode: 'accurate',
                validateCurp: true,
                validateClaveElector: true,
                timeoutMs: 30000,
              }
            );

            setResult(processingResult);

            if (processingResult.acceptable) {
              Alert.alert('Éxito', 'Credencial procesada correctamente');
            } else {
              Alert.alert(
                'Advertencia',
                `Credencial procesada con errores: ${processingResult.errorMessage}`
              );
            }
          } catch (error) {
            Alert.alert('Error', `Error procesando credencial: ${error.message}`);
          } finally {
            setProcessing(false);
          }
        }
      }
    );
  };

  const renderResult = () => {
    if (!result) return null;

    return (
      <ScrollView style={styles.resultContainer}>
        <Text style={styles.title}>Resultado del Procesamiento:</Text>
        
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Información General</Text>
          <Text style={styles.dataItem}>Nombre: {result.nombre || 'N/A'}</Text>
          <Text style={styles.dataItem}>CURP: {result.curp || 'N/A'}</Text>
          <Text style={styles.dataItem}>
            Clave de Elector: {result.claveElector || 'N/A'}
          </Text>
          <Text style={styles.dataItem}>
            Fecha de Nacimiento: {result.fechaNacimiento || 'N/A'}
          </Text>
          <Text style={styles.dataItem}>Sexo: {result.sexo || 'N/A'}</Text>
          <Text style={styles.dataItem}>Domicilio: {result.domicilio || 'N/A'}</Text>
        </View>

        {result.tipo === 't2' && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Datos Específicos T2</Text>
            <Text style={styles.dataItem}>
              Apellido Paterno: {result.apellidoPaterno || 'N/A'}
            </Text>
            <Text style={styles.dataItem}>
              Apellido Materno: {result.apellidoMaterno || 'N/A'}
            </Text>
            <Text style={styles.dataItem}>Estado: {result.estado || 'N/A'}</Text>
            <Text style={styles.dataItem}>Municipio: {result.municipio || 'N/A'}</Text>
          </View>
        )}

        {result.mrzContent && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Datos MRZ (Reverso)</Text>
            <Text style={styles.dataItem}>
              Número de Documento: {result.mrzDocumentNumber || 'N/A'}
            </Text>
            <Text style={styles.dataItem}>
              Nacionalidad: {result.mrzNationality || 'N/A'}
            </Text>
            <Text style={styles.dataItem}>
              Fecha de Nacimiento MRZ: {result.mrzBirthDate || 'N/A'}
            </Text>
            <Text style={styles.dataItem}>
              Fecha de Expiración: {result.mrzExpiryDate || 'N/A'}
            </Text>
          </View>
        )}

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Metadatos</Text>
          <Text style={styles.dataItem}>
            Tipo de Credencial: {result.tipo || 'N/A'}
          </Text>
          <Text style={styles.dataItem}>Lado: {result.lado || 'N/A'}</Text>
          <Text style={[styles.dataItem, result.acceptable ? styles.success : styles.error]}>
            Aceptable: {result.acceptable ? 'Sí' : 'No'}
          </Text>
          <Text style={styles.dataItem}>
            Confianza: {result.confidence ? `${result.confidence}%` : 'N/A'}
          </Text>
          {result.errorMessage && (
            <Text style={[styles.dataItem, styles.error]}>
              Error: {result.errorMessage}
            </Text>
          )}
        </View>
      </ScrollView>
    );
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Escáner de Credencial INE</Text>
        <Text style={styles.headerSubtitle}>
          Soporta credenciales T2 y T3, lado frontal y reverso
        </Text>
      </View>

      <View style={styles.buttonContainer}>
        <Button
          title={processing ? 'Procesando...' : 'Seleccionar y Procesar INE'}
          onPress={selectAndProcessImage}
          disabled={processing}
        />
      </View>

      {processing && (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#0066cc" />
          <Text style={styles.loadingText}>Procesando credencial...</Text>
        </View>
      )}

      {renderResult()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#0066cc',
    padding: 20,
    paddingTop: 40,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center',
  },
  headerSubtitle: {
    fontSize: 14,
    color: 'white',
    textAlign: 'center',
    marginTop: 5,
    opacity: 0.9,
  },
  buttonContainer: {
    padding: 20,
  },
  loadingContainer: {
    alignItems: 'center',
    padding: 20,
  },
  loadingText: {
    marginTop: 10,
    fontSize: 16,
    color: '#666',
  },
  resultContainer: {
    flex: 1,
    margin: 20,
    backgroundColor: 'white',
    borderRadius: 8,
    padding: 15,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  title: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 15,
    color: '#333',
    textAlign: 'center',
  },
  section: {
    marginBottom: 20,
    paddingBottom: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
    color: '#0066cc',
  },
  dataItem: {
    fontSize: 14,
    marginBottom: 5,
    color: '#333',
    lineHeight: 20,
  },
  success: {
    color: '#28a745',
    fontWeight: 'bold',
  },
  error: {
    color: '#dc3545',
    fontWeight: 'bold',
  },
});

export default IneScanner;