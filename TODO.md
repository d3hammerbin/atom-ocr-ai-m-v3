# TODO - Lista de Tareas Pendientes

## Validaciones y Mejoras

### Validaciones de Datos
- [ ] Agregar validaciones granulares para CURP
  - Validar formato específico (18 caracteres)
  - Validar fecha de nacimiento dentro del CURP
  - Validar entidad federativa
  - Validar dígito verificador

- [ ] Agregar validaciones granulares para clave de elector
  - Validar formato específico (18 caracteres alfanuméricos)
  - Validar estructura según normativa INE
  - Validar dígito verificador
  - Validar coherencia con otros datos de la credencial

## Notas
- Las validaciones deben implementarse en el servicio de procesamiento de credenciales
- Considerar casos especiales y excepciones en los formatos
- Documentar los criterios de validación utilizados