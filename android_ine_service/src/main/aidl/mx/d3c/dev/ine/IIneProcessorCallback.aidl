package mx.d3c.dev.ine;

/**
 * Callback AIDL para recibir resultados del procesamiento de credenciales INE
 * Permite comunicación asíncrona entre el servicio y los clientes
 */
interface IIneProcessorCallback {
    /**
     * Llamado cuando el procesamiento se completa exitosamente
     * @param taskId ID único de la tarea
     * @param result Resultado del procesamiento en formato JSON
     */
    void onProcessingComplete(String taskId, String result);
    
    /**
     * Llamado cuando ocurre un error durante el procesamiento
     * @param taskId ID único de la tarea
     * @param errorCode Código de error
     * @param errorMessage Mensaje descriptivo del error
     */
    void onProcessingError(String taskId, int errorCode, String errorMessage);
    
    /**
     * Llamado para reportar el progreso del procesamiento
     * @param taskId ID único de la tarea
     * @param progress Progreso del 0 al 100
     * @param status Descripción del estado actual
     */
    void onProgressUpdate(String taskId, int progress, String status);
    
    /**
     * Llamado cuando una tarea es cancelada
     * @param taskId ID único de la tarea
     */
    void onProcessingCancelled(String taskId);
}