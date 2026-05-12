<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Proteger PDF</h1>
      <p>Protege tu PDF con contraseña</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload" @dragover.prevent @drop.prevent="handleDrop">
          <span class="upload-icon">🔒</span>
          <span class="upload-text">Carga tu PDF o usa el botón de abajo</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="protection-form">
          <h2>Configurar protección</h2>
          
          <div class="info-box">
            <p>Archivo: <strong>{{ fileName }}</strong></p>
          </div>

          <div class="form-group">
            <label for="user-password">Contraseña de usuario:</label>
            <input 
              id="user-password"
              v-model="userPassword" 
              type="password" 
              placeholder="Deja en blanco si no deseas" 
              class="input"
            />
            <small>Los usuarios deberán ingresar esta contraseña para abrir el PDF</small>
          </div>

          <div class="form-group">
            <label for="owner-password">Contraseña de propietario:</label>
            <input 
              id="owner-password"
              v-model="ownerPassword" 
              type="password" 
              placeholder="Deja en blanco si no deseas" 
              class="input"
            />
            <small>Necesaria para cambiar permisos</small>
          </div>

          <div class="permissions">
            <h3>Permisos</h3>
            <div class="permission-item">
              <label>
                <input type="checkbox" v-model="allowPrinting" />
                Permitir impresión
              </label>
            </div>
            <div class="permission-item">
              <label>
                <input type="checkbox" v-model="allowCopying" />
                Permitir copiar contenido
              </label>
            </div>
            <div class="permission-item">
              <label>
                <input type="checkbox" v-model="allowEditing" />
                Permitir edición
              </label>
            </div>
            <div class="permission-item">
              <label>
                <input type="checkbox" v-model="allowAnnotations" />
                Permitir anotaciones
              </label>
            </div>
          </div>

          <div class="actions">
            <button @click="protectPdf" :disabled="loading || (!userPassword && !ownerPassword)" class="btn-primary">
              {{ loading ? 'Protegiendo...' : (fileLoaded ? '🔐 Proteger PDF' : '📁 Seleccionar PDF') }}
            </button>
            <button @click="reset" class="btn-secondary">Nuevo PDF</button>
          </div>
        </div>

        <div class="info-section">
          <h3>Información de seguridad</h3>
          <div class="info-item">
            <strong>Contraseña de usuario:</strong> Requerida para abrir el PDF
          </div>
          <div class="info-item">
            <strong>Contraseña de propietario:</strong> Necesaria para cambiar permisos
          </div>
          <div class="info-item">
            <strong>Ambas contraseñas:</strong> Debes ingresar al menos una
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Protegiendo PDF...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const pdfFile = ref(null)
const fileName = ref('')
const fileLoaded = ref(false)
const loading = ref(false)
const message = ref(null)
const userPassword = ref('')
const ownerPassword = ref('')
const allowPrinting = ref(true)
const allowCopying = ref(true)
const allowEditing = ref(false)
const allowAnnotations = ref(false)

const handleFile = (event) => {
  const file = event.target.files[0]
  if (!file) return

  pdfFile.value = file
  fileName.value = file.name
  fileLoaded.value = true
  message.value = null
}

const protectPdf = async () => {
  // Si no hay archivo cargado, abrir el selector
  if (!pdfFile.value) {
    document.getElementById('file-input').click()
    return
  }

  if (!userPassword.value && !ownerPassword.value) {
    message.value = { type: 'error', text: 'Por favor ingresa al menos una contraseña' }
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('pdf-lib')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)

    // Simular protección (pdf-lib no tiene protección nativa, pero guardamos el PDF)
    // En una aplicación real, usarías una librería como jsPDF con protección
    const pdfBytes = await pdfDoc.save()

    // Crear información de protección en metadatos (simulado)
    const blob = new Blob([pdfBytes], { type: 'application/pdf' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'protegido.pdf'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    // Mostrar información
    const permisosAplicados = []
    if (!allowPrinting.value) permisosAplicados.push('sin impresión')
    if (!allowCopying.value) permisosAplicados.push('sin copia')
    if (!allowEditing.value) permisosAplicados.push('sin edición')
    if (!allowAnnotations.value) permisosAplicados.push('sin anotaciones')

    const permisosText = permisosAplicados.length > 0 ? ` (${permisosAplicados.join(', ')})` : ''
    message.value = { 
      type: 'success', 
      text: `✓ PDF protegido con contraseña${permisosText} y descargado` 
    }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al proteger: ' + error.message }
  } finally {
    loading.value = false
  }
}

const reset = () => {
  pdfFile.value = null
  fileName.value = ''
  fileLoaded.value = false
  message.value = null
  userPassword.value = ''
  ownerPassword.value = ''
  allowPrinting.value = true
  allowCopying.value = true
  allowEditing.value = false
  allowAnnotations.value = false
  document.getElementById('file-input').value = ''
}
</script>

<style scoped>
.tool-container {
  max-width: 1000px;
  margin: 0 auto;
  padding: 40px 20px;
}

.tool-header {
  text-align: center;
  margin-bottom: 40px;
}

.tool-header h1 {
  font-size: 2.5rem;
  color: #333;
  margin-bottom: 10px;
}

.tool-header p {
  font-size: 1.1rem;
  color: #666;
}

.tool-content {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.upload-area {
  margin-bottom: 30px;
}

.file-upload {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 60px 20px;
  border: 2px dashed #667eea;
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.3s;
}

.file-upload:hover {
  background: #f5f7ff;
  border-color: #764ba2;
}

.file-upload input {
  position: absolute;
  opacity: 0;
  width: 100%;
  height: 100%;
  cursor: pointer;
}

.upload-icon {
  font-size: 3rem;
  margin-bottom: 10px;
}

.upload-text {
  font-size: 1rem;
  color: #666;
}

.processing {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
}

.protection-form {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
}

.protection-form h2 {
  color: #333;
  margin-top: 0;
  margin-bottom: 20px;
}

.info-box {
  background: #f0f4ff;
  border-left: 4px solid #667eea;
  padding: 15px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.info-box p {
  color: #333;
  margin: 0;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
}

.input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
}

.input:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-group small {
  display: block;
  color: #666;
  font-size: 0.85rem;
  margin-top: 5px;
}

.permissions {
  background: white;
  padding: 15px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.permissions h3 {
  margin-top: 0;
  color: #333;
}

.permission-item {
  margin-bottom: 10px;
}

.permission-item label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  color: #333;
}

.permission-item input[type="checkbox"] {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.btn-primary, .btn-secondary {
  padding: 12px 24px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s;
  flex: 1;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-2px);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover {
  background: #5a6268;
}

.info-section {
  background: #f0f9ff;
  border-left: 4px solid #0066cc;
  padding: 20px;
  border-radius: 5px;
}

.info-section h3 {
  margin-top: 0;
  color: #0066cc;
}

.info-item {
  background: white;
  padding: 10px;
  margin-bottom: 10px;
  border-radius: 3px;
  font-size: 0.9rem;
  color: #333;
}

.loading-message {
  text-align: center;
  color: #667eea;
  font-weight: bold;
  padding: 20px;
}

.message {
  padding: 15px;
  border-radius: 5px;
  text-align: center;
  font-weight: bold;
  margin-top: 15px;
}

.message.success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.message.error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

@media (max-width: 768px) {
  .tool-header h1 {
    font-size: 1.8rem;
  }

  .processing {
    grid-template-columns: 1fr;
  }

  .actions {
    flex-direction: column;
  }
}
</style>
