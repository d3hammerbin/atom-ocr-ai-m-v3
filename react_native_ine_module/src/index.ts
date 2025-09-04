import { NativeModules, Platform, NativeEventEmitter } from 'react-native';

const LINKING_ERROR =
  `El paquete 'react-native-ine-processor' no parece estar vinculado. Asegúrate de que:\n\n` +
  Platform.select({ ios: "- Tienes Cocoapods instalado\n", default: '' }) +
  '- Reiniciaste el Metro bundler\n' +
  '- Ejecutaste `npx react-native run-android` o `npx react-native run-ios`\n' +
  '- Limpiaste y reconstruiste la aplicación\n';

// @ts-expect-error
const isTurboModuleEnabled = global.__turboModuleProxy != null;

const IneProcessorModule = isTurboModuleEnabled
  ? require('./NativeIneProcessor').default
  : NativeModules.IneProcessor;

const IneProcessor = IneProcessorModule
  ? IneProcessorModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

// Event Emitter para escuchar eventos del procesamiento
const eventEmitter = new NativeEventEmitter(IneProcessor);

/**
 * Tipos de credencial INE soportados
 */
export enum CredentialType {
  T2 = 't2',
  T3 = 't3',
}

/**
 * Lado del documento para extracción de MRZ
 */
export enum DocumentSide {
  FRONT = 'front',
  BACK = 'back',
}

/**
 * Estados de procesamiento
 */
export enum ProcessingStatus {
  PENDING = 'pending',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled',
}

/**
 * Códigos de error del procesamiento
 */
export enum ErrorCode {
  UNKNOWN = 0,
  FILE_NOT_FOUND = 1,
  INVALID_IMAGE = 2,
  PROCESSING_FAILED = 3,
  SERVICE_UNAVAILABLE = 4,
  PERMISSION_DENIED = 5,
  TIMEOUT = 6,
}

/**
 * Resultado del procesamiento de credencial INE
 * Incluye datos completos del lado frontal (T2/T3) y datos MRZ del reverso
 */
export interface MrzResult {
  // Datos del lado frontal (comunes para T2 y T3)
  nombre?: string;
  domicilio?: string;
  claveElector?: string;
  curp?: string;
  fechaNacimiento?: string;
  sexo?: string;
  seccion?: string;
  vigencia?: string;
  anoRegistro?: string;
  
  // Datos específicos de T2 (pueden estar vacíos en T3)
  estado?: string;
  municipio?: string;
  localidad?: string;
  emision?: string;
  
  // Datos MRZ (lado reverso)
  mrzContent?: string;
  mrzDocumentNumber?: string;
  mrzNationality?: string;
  mrzBirthDate?: string;
  mrzExpiryDate?: string;
  mrzSex?: string;
  mrzName?: string;
  
  // Metadatos del procesamiento
  documentSide?: string;
  credentialType?: string;
  acceptable?: boolean;
  processingTimeMs?: number;
  errorMessage?: string;
}

/**
 * Configuración de procesamiento de credencial INE
 */
export interface ProcessingConfig {
  // Configuración de calidad de imagen
  minImageWidth?: number;
  minImageHeight?: number;
  maxImageSize?: number;
  
  // Configuración de timeout
  timeoutMs?: number;
}

/**
 * Información de progreso del procesamiento
 */
export interface ProcessingProgress {
  taskId: string;
  progress: number; // 0-100
  status: string;
  timestamp: number;
}

/**
 * Información del servicio
 */
export interface ServiceInfo {
  version: string;
  isAvailable: boolean;
  supportedTypes: CredentialType[];
  capabilities: string[];
}

/**
 * Listeners de eventos
 */
export interface ProcessingEventListeners {
  onProgress?: (progress: ProcessingProgress) => void;
  onComplete?: (taskId: string, result: MrzResult) => void;
  onError?: (taskId: string, errorCode: ErrorCode, errorMessage: string) => void;
  onCancelled?: (taskId: string) => void;
}

/**
 * Clase principal del procesador de credenciales INE
 */
class IneCredentialProcessor {
  private eventListeners: Map<string, ProcessingEventListeners> = new Map();
  private eventSubscriptions: any[] = [];

  constructor() {
    this.setupEventListeners();
  }

  /**
   * Configura los listeners de eventos nativos
   */
  private setupEventListeners(): void {
    // Listener para progreso
    const progressSubscription = eventEmitter.addListener(
      'IneProcessor_Progress',
      (data: ProcessingProgress) => {
        const listeners = this.eventListeners.get(data.taskId);
        if (listeners?.onProgress) {
          listeners.onProgress(data);
        }
      }
    );

    // Listener para completado
    const completeSubscription = eventEmitter.addListener(
      'IneProcessor_Complete',
      (data: { taskId: string; result: MrzResult }) => {
        const listeners = this.eventListeners.get(data.taskId);
        if (listeners?.onComplete) {
          listeners.onComplete(data.taskId, data.result);
        }
        // Limpiar listeners después de completar
        this.eventListeners.delete(data.taskId);
      }
    );

    // Listener para errores
    const errorSubscription = eventEmitter.addListener(
      'IneProcessor_Error',
      (data: { taskId: string; errorCode: ErrorCode; errorMessage: string }) => {
        const listeners = this.eventListeners.get(data.taskId);
        if (listeners?.onError) {
          listeners.onError(data.taskId, data.errorCode, data.errorMessage);
        }
        // Limpiar listeners después de error
        this.eventListeners.delete(data.taskId);
      }
    );

    // Listener para cancelaciones
    const cancelSubscription = eventEmitter.addListener(
      'IneProcessor_Cancelled',
      (data: { taskId: string }) => {
        const listeners = this.eventListeners.get(data.taskId);
        if (listeners?.onCancelled) {
          listeners.onCancelled(data.taskId);
        }
        // Limpiar listeners después de cancelar
        this.eventListeners.delete(data.taskId);
      }
    );

    this.eventSubscriptions = [
      progressSubscription,
      completeSubscription,
      errorSubscription,
      cancelSubscription,
    ];
  }

  /**
   * Extrae MRZ de forma asíncrona del lado especificado del documento
   */
  async processCredentialAsync(
    imagePath: string,
    documentSide: DocumentSide,
    config?: ProcessingConfig,
    listeners?: ProcessingEventListeners
  ): Promise<string> {
    const taskId = await IneProcessor.processCredentialAsync(
      imagePath,
      documentSide,
      config || {}
    );

    if (listeners) {
      this.eventListeners.set(taskId, listeners);
    }

    return taskId;
  }

  /**
   * Extrae MRZ de forma síncrona del lado especificado del documento
   */
  async processCredential(
    imagePath: string,
    documentSide: DocumentSide,
    config?: ProcessingConfig
  ): Promise<MrzResult> {
    return await IneProcessor.processCredential(imagePath, documentSide, config || {});
  }

  /**
   * Verifica si una imagen contiene un MRZ válido en el lado especificado
   */
  async isValidCredential(imagePath: string, documentSide: DocumentSide): Promise<boolean> {
    return await IneProcessor.isValidCredential(imagePath, documentSide);
  }

  /**
   * Cancela una tarea de procesamiento
   */
  async cancelTask(taskId: string): Promise<boolean> {
    const result = await IneProcessor.cancelTask(taskId);
    // Limpiar listeners si se cancela
    this.eventListeners.delete(taskId);
    return result;
  }

  /**
   * Obtiene el estado de una tarea
   */
  async getTaskStatus(taskId: string): Promise<ProcessingStatus> {
    return await IneProcessor.getTaskStatus(taskId);
  }

  /**
   * Obtiene información del servicio
   */
  async getServiceInfo(): Promise<ServiceInfo> {
    return await IneProcessor.getServiceInfo();
  }

  /**
   * Verifica si el servicio está disponible
   */
  async isServiceAvailable(): Promise<boolean> {
    try {
      const info = await this.getServiceInfo();
      return info.isAvailable;
    } catch {
      return false;
    }
  }

  /**
   * Limpia todos los listeners de eventos
   */
  cleanup(): void {
    this.eventListeners.clear();
    this.eventSubscriptions.forEach(subscription => {
      if (subscription?.remove) {
        subscription.remove();
      }
    });
    this.eventSubscriptions = [];
  }
}

// Instancia singleton del procesador
const processorInstance = new IneCredentialProcessor();

// Exportar la instancia y tipos
export default processorInstance;
export {
  IneCredentialProcessor,
  type ProcessingConfig,
  type ProcessingProgress,
  type ProcessingEventListeners,
  type ServiceInfo,
  type MrzResult,
};

// Funciones de conveniencia para extracción de MRZ
export const processCredential = (
  imagePath: string,
  documentSide: DocumentSide,
  config?: ProcessingConfig
): Promise<MrzResult> => {
  return processorInstance.processCredential(imagePath, documentSide, config);
};

export const processCredentialAsync = (
  imagePath: string,
  documentSide: DocumentSide,
  config?: ProcessingConfig,
  listeners?: ProcessingEventListeners
): Promise<string> => {
  return processorInstance.processCredentialAsync(imagePath, documentSide, config, listeners);
};

export const isValidCredential = (imagePath: string, documentSide: DocumentSide): Promise<boolean> => {
  return processorInstance.isValidCredential(imagePath, documentSide);
};

export const cancelTask = (taskId: string): Promise<boolean> => {
  return processorInstance.cancelTask(taskId);
};

export const getTaskStatus = (taskId: string): Promise<ProcessingStatus> => {
  return processorInstance.getTaskStatus(taskId);
};

export const getServiceInfo = (): Promise<ServiceInfo> => {
  return processorInstance.getServiceInfo();
};

export const isServiceAvailable = (): Promise<boolean> => {
  return processorInstance.isServiceAvailable();
};