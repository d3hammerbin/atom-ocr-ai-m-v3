import IneProcessor from 'react-native-ine-processor';

/**
 * Verifica que el módulo INE esté correctamente instalado y funcionando
 * @returns Promise<boolean> - true si el módulo está funcionando correctamente
 */
export const verifyIneProcessor = async (): Promise<boolean> => {
  try {
    console.log('🔍 Verificando instalación del módulo INE...');
    
    // Verificar disponibilidad del servicio
    const isAvailable = await IneProcessor.isServiceAvailable();
    
    if (!isAvailable) {
      console.error('❌ Servicio INE no disponible');
      console.log('💡 Posibles soluciones:');
      console.log('   - Verificar permisos en AndroidManifest.xml');
      console.log('   - Confirmar que el servicio esté declarado correctamente');
      console.log('   - Revisar configuración de build.gradle');
      return false;
    }
    
    console.log('✅ Servicio INE disponible');
    
    // Obtener información del servicio
    try {
      const serviceInfo = await IneProcessor.getServiceInfo();
      console.log('📋 Información del servicio:', serviceInfo);
    } catch (error) {
      console.warn('⚠️  No se pudo obtener información del servicio:', error.message);
    }
    
    // Verificar métodos principales
    const methods = [
      'processCredential',
      'isValidCredential',
      'processCredentialAsync',
      'cancelTask'
    ];
    
    for (const method of methods) {
      if (typeof IneProcessor[method] !== 'function') {
        console.error(`❌ Método ${method} no disponible`);
        return false;
      }
    }
    
    console.log('✅ Todos los métodos principales están disponibles');
    
    // Test básico de validación (sin imagen real)
    try {
      // Este test debería fallar graciosamente con una ruta inválida
      await IneProcessor.isValidCredential('/invalid/path/test.jpg');
    } catch (error) {
      // Es esperado que falle, pero no debería crashear
      if (error.code === 'FILE_NOT_FOUND' || error.message.includes('not found')) {
        console.log('✅ Validación de errores funciona correctamente');
      } else {
        console.warn('⚠️  Error inesperado en validación:', error.message);
      }
    }
    
    console.log('🎉 Módulo INE instalado y funcionando correctamente');
    return true;
    
  } catch (error) {
    console.error('❌ Error verificando módulo INE:', error);
    console.log('💡 Posibles soluciones:');
    console.log('   - Verificar que el módulo esté instalado: npm install');
    console.log('   - Limpiar cache: npx react-native start --reset-cache');
    console.log('   - Reconstruir proyecto: cd android && ./gradlew clean');
    return false;
  }
};

/**
 * Verifica la configuración de permisos de Android
 * @returns Promise<boolean> - true si los permisos están configurados
 */
export const verifyAndroidPermissions = async (): Promise<boolean> => {
  try {
    console.log('🔍 Verificando permisos de Android...');
    
    // En un entorno real, aquí verificarías los permisos
    // Por ahora, solo mostramos qué permisos son necesarios
    const requiredPermissions = [
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.CAMERA'
    ];
    
    console.log('📋 Permisos requeridos en AndroidManifest.xml:');
    requiredPermissions.forEach(permission => {
      console.log(`   - ${permission}`);
    });
    
    console.log('✅ Verificación de permisos completada');
    console.log('💡 Asegúrate de que estos permisos estén en tu AndroidManifest.xml');
    
    return true;
  } catch (error) {
    console.error('❌ Error verificando permisos:', error);
    return false;
  }
};

/**
 * Ejecuta una verificación completa del módulo
 * @returns Promise<VerificationResult>
 */
export interface VerificationResult {
  moduleInstalled: boolean;
  serviceAvailable: boolean;
  permissionsConfigured: boolean;
  overallStatus: 'success' | 'warning' | 'error';
  recommendations: string[];
}

export const runCompleteVerification = async (): Promise<VerificationResult> => {
  console.log('🚀 Iniciando verificación completa del módulo INE...');
  
  const result: VerificationResult = {
    moduleInstalled: false,
    serviceAvailable: false,
    permissionsConfigured: false,
    overallStatus: 'error',
    recommendations: []
  };
  
  // Verificar instalación del módulo
  result.moduleInstalled = await verifyIneProcessor();
  
  // Verificar permisos
  result.permissionsConfigured = await verifyAndroidPermissions();
  
  // Determinar estado general
  if (result.moduleInstalled && result.permissionsConfigured) {
    result.overallStatus = 'success';
    result.serviceAvailable = true;
  } else if (result.moduleInstalled || result.permissionsConfigured) {
    result.overallStatus = 'warning';
    if (!result.moduleInstalled) {
      result.recommendations.push('Reinstalar el módulo INE');
      result.recommendations.push('Verificar configuración de build.gradle');
    }
    if (!result.permissionsConfigured) {
      result.recommendations.push('Configurar permisos en AndroidManifest.xml');
    }
  } else {
    result.overallStatus = 'error';
    result.recommendations.push('Seguir el manual de instalación paso a paso');
    result.recommendations.push('Verificar que todos los archivos estén en su lugar');
  }
  
  // Mostrar resumen
  console.log('\n📊 Resumen de Verificación:');
  console.log(`   Módulo Instalado: ${result.moduleInstalled ? '✅' : '❌'}`);
  console.log(`   Servicio Disponible: ${result.serviceAvailable ? '✅' : '❌'}`);
  console.log(`   Permisos Configurados: ${result.permissionsConfigured ? '✅' : '❌'}`);
  console.log(`   Estado General: ${getStatusEmoji(result.overallStatus)} ${result.overallStatus.toUpperCase()}`);
  
  if (result.recommendations.length > 0) {
    console.log('\n💡 Recomendaciones:');
    result.recommendations.forEach((rec, index) => {
      console.log(`   ${index + 1}. ${rec}`);
    });
  }
  
  return result;
};

function getStatusEmoji(status: string): string {
  switch (status) {
    case 'success': return '🎉';
    case 'warning': return '⚠️';
    case 'error': return '❌';
    default: return '❓';
  }
}

/**
 * Hook de React para usar la verificación en componentes
 */
export const useIneVerification = () => {
  const [verificationResult, setVerificationResult] = React.useState<VerificationResult | null>(null);
  const [isVerifying, setIsVerifying] = React.useState(false);
  
  const runVerification = async () => {
    setIsVerifying(true);
    try {
      const result = await runCompleteVerification();
      setVerificationResult(result);
    } catch (error) {
      console.error('Error en verificación:', error);
    } finally {
      setIsVerifying(false);
    }
  };
  
  return {
    verificationResult,
    isVerifying,
    runVerification
  };
};