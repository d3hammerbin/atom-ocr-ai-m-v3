Hay algunas modificaciones ya que no es necesario pasar todo el contenido que esta disponible tambien unas funciones como la deteccion de lado, por ejemplo lo primero es que el lado venga desde un parametro para no utilizar la deteccion, por lo cual en el argumento vendria el path de la imagen asi como el lado de la misma frente o reverso, con eso ya no ocupariamos para este servicio la deteccion de lado, tambien omitiriamos la extraccion o obtencion de el codigo de barras, el QR Code y la fima y huella digital, solo entregariamos el MRZ, de la parte frontal omitiriamos la foto del rostro de la  persona y la firma


Rediseñar el servicio para procesar imágenes de documentos con los siguientes cambios:

1. Eliminar la detección automática del lado del documento:
   - Recibir el lado (frente/reverso) como parámetro junto con la ruta de la imagen
   - No utilizar algoritmos de detección de lado

2. Simplificar la salida del procesamiento:
   - Solo entregar el MRZ (Zona de Lectura Mecánica)
   - Omitir la extracción de:
     * Código de barras
     * QR Code
     * Firma manuscrita
     * Huella digital
     * Foto del rostro (para el lado frontal)
     * Firma del documento

3. Mantener únicamente la funcionalidad esencial de lectura del MRZ sin los elementos adicionales previamente implementados.