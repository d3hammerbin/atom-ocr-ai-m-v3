# Script para crear el paquete ZIP del módulo React Native INE
# Ejecutar desde la raíz del proyecto: .\create-ine-package.ps1

Write-Host "🚀 Creando paquete React Native INE..." -ForegroundColor Green

# Crear directorio temporal para el paquete
$packageDir = "react-native-ine-processor"
$zipName = "react-native-ine-processor.zip"

# Limpiar directorio anterior si existe
if (Test-Path $packageDir) {
    Write-Host "🧹 Limpiando directorio anterior..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $packageDir
}

# Crear estructura de directorios
Write-Host "📁 Creando estructura de directorios..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\src" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\android" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\android_service" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\flutter_engine" -Force | Out-Null
New-Item -ItemType Directory -Path "$packageDir\examples" -Force | Out-Null

# Copiar archivos del módulo React Native
Write-Host "📦 Copiando módulo React Native..." -ForegroundColor Cyan
if (Test-Path "react_native_ine_module\src") {
    Copy-Item -Recurse "react_native_ine_module\src\*" "$packageDir\src\"
}
if (Test-Path "react_native_ine_module\android") {
    Copy-Item -Recurse "react_native_ine_module\android\*" "$packageDir\android\"
}

# Copiar servicio Android
Write-Host "🤖 Copiando servicio Android..." -ForegroundColor Cyan
if (Test-Path "android_ine_service") {
    Copy-Item -Recurse "android_ine_service\*" "$packageDir\android_service\"
}

# Copiar motor Flutter
Write-Host "🐦 Copiando motor Flutter..." -ForegroundColor Cyan
if (Test-Path "flutter_ine_service") {
    Copy-Item -Recurse "flutter_ine_service\*" "$packageDir\flutter_engine\"
}

# Copiar ejemplos
Write-Host "📋 Copiando ejemplos..." -ForegroundColor Cyan
if (Test-Path "examples") {
    Copy-Item -Recurse "examples\*" "$packageDir\examples\"
}

# Copiar package.json específico
Write-Host "📄 Configurando package.json..." -ForegroundColor Cyan
if (Test-Path "react-native-ine-processor-package.json") {
    Copy-Item "react-native-ine-processor-package.json" "$packageDir\package.json"
} else {
    Write-Warning "⚠️  Archivo package.json específico no encontrado"
}

# Copiar manual de instalación como README
Write-Host "📖 Copiando documentación..." -ForegroundColor Cyan
if (Test-Path "MANUAL_INSTALACION_LOCAL.md") {
    Copy-Item "MANUAL_INSTALACION_LOCAL.md" "$packageDir\README.md"
} else {
    Write-Warning "⚠️  Manual de instalación no encontrado"
}

# Crear archivo .gitignore para el paquete
Write-Host "🚫 Creando .gitignore..." -ForegroundColor Cyan
@"
node_modules/
lib/
*.log
.DS_Store
Thumbs.db
"@ | Out-File -FilePath "$packageDir\.gitignore" -Encoding UTF8

# Crear archivo de licencia
Write-Host "⚖️  Creando LICENSE..." -ForegroundColor Cyan
@"
MIT License

Copyright (c) 2024 React Native INE Processor

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@ | Out-File -FilePath "$packageDir\LICENSE" -Encoding UTF8

# Verificar archivos copiados
Write-Host "🔍 Verificando archivos copiados..." -ForegroundColor Cyan
$fileCount = (Get-ChildItem -Recurse $packageDir | Measure-Object).Count
Write-Host "   Total de archivos: $fileCount" -ForegroundColor White

# Mostrar estructura del paquete
Write-Host "📂 Estructura del paquete:" -ForegroundColor Cyan
Get-ChildItem $packageDir -Recurse -Directory | ForEach-Object {
    $relativePath = $_.FullName.Replace((Get-Location).Path + "\$packageDir\", "")
    Write-Host "   📁 $relativePath" -ForegroundColor Gray
}

# Crear ZIP
Write-Host "🗜️  Creando archivo ZIP..." -ForegroundColor Green
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}

try {
    Compress-Archive -Path $packageDir -DestinationPath $zipName -CompressionLevel Optimal
    $zipSize = [math]::Round((Get-Item $zipName).Length / 1MB, 2)
    Write-Host "✅ Paquete creado exitosamente: $zipName ($zipSize MB)" -ForegroundColor Green
} catch {
    Write-Error "❌ Error creando ZIP: $($_.Exception.Message)"
    exit 1
}

# Limpiar directorio temporal
Write-Host "🧹 Limpiando archivos temporales..." -ForegroundColor Yellow
Remove-Item -Recurse -Force $packageDir

# Mostrar instrucciones finales
Write-Host ""
Write-Host "🎉 ¡Paquete React Native INE creado exitosamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📦 Archivo: $zipName" -ForegroundColor White
Write-Host "📏 Tamaño: $zipSize MB" -ForegroundColor White
Write-Host ""
Write-Host "📋 Instrucciones de uso:" -ForegroundColor Cyan
Write-Host "   1. Copia el archivo $zipName a tu nuevo proyecto React Native" -ForegroundColor White
Write-Host "   2. Extrae el ZIP en la raíz del proyecto" -ForegroundColor White
Write-Host "   3. Sigue las instrucciones del README.md incluido" -ForegroundColor White
Write-Host "   4. Ejecuta: npm install ./react-native-ine-processor" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Para más información, consulta el README.md dentro del paquete" -ForegroundColor Yellow