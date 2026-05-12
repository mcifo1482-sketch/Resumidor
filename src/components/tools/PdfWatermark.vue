<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Marca de Agua</h1>
      <p>Añade una marca de agua a todas tus páginas</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload" @dragover.prevent @drop.prevent="handleDrop">
          <span class="upload-icon">💧</span>
          <span class="upload-text">Carga tu PDF o usa el botón de abajo</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="controls">
          <h2>Configurar marca de agua</h2>
          
          <div class="form-group">
            <label for="watermark-text">Texto de marca de agua:</label>
            <input id="watermark-text" v-model="watermarkText" type="text" placeholder="ej: CONFIDENCIAL" class="input" />
          </div>

          <div class="form-group">
            <label for="watermark-color">Color:</label>
            <input id="watermark-color" v-model="watermarkColor" type="color" class="color-input" />
          </div>

          <div class="form-group">
            <label for="watermark-opacity">Opacidad:</label>
            <input id="watermark-opacity" v-model.number="watermarkOpacity" type="range" min="0.1" max="1" step="0.1" class="range-input" />
            <span class="opacity-value">{{ (watermarkOpacity * 100).toFixed(0) }}%</span>
          </div>

          <div class="form-group">
            <label for="watermark-size">Tamaño:</label>
            <select id="watermark-size" v-model.number="watermarkSize" class="select-input">
              <option value="30">Pequeño</option>
              <option value="50">Mediano</option>
              <option value="80">Grande</option>
            </select>
          </div>

          <div class="actions">
            <button @click="applyWatermark" :disabled="loading || !watermarkText" class="btn-primary">
              {{ loading ? 'Aplicando...' : (fileLoaded ? '💦 Aplicar marca' : '📁 Seleccionar PDF') }}
            </button>
            <button @click="reset" class="btn-secondary">Nuevo PDF</button>
          </div>
        </div>

        <div class="preview">
          <h3>Vista previa</h3>
          <div class="preview-box" :style="{ color: watermarkColor, opacity: watermarkOpacity }">
            <span :style="{ fontSize: watermarkSize + 'px' }">{{ watermarkText }}</span>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Aplicando marca de agua...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const pdfFile = ref(null)
const fileLoaded = ref(false)
const loading = ref(false)
const message = ref(null)
const watermarkText = ref('CONFIDENCIAL')
const watermarkColor = ref('#999999')
const watermarkOpacity = ref(0.3)
const watermarkSize = ref(50)

const handleFile = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  pdfFile.value = file
  fileLoaded.value = true
  message.value = null
}

const applyWatermark = async () => {
  if (!pdfFile.value || !watermarkText.value) {
    message.value = { type: 'error', text: 'Por favor completa todos los campos' }
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument, rgb, degrees } = await import('pdf-lib')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    const pages = pdfDoc.getPages()

    const r = parseInt(watermarkColor.value.substr(1, 2), 16) / 255
    const g = parseInt(watermarkColor.value.substr(3, 2), 16) / 255
    const b = parseInt(watermarkColor.value.substr(5, 2), 16) / 255

    pages.forEach(page => {
      const { width, height } = page.getSize()
      
      page.drawText(watermarkText.value, {
        x: width / 2 - (watermarkText.value.length * watermarkSize.value) / 4,
        y: height / 2,
        size: watermarkSize.value,
        color: rgb(r, g, b),
        opacity: watermarkOpacity.value,
        rotate: degrees(45)
      })
    })

    const pdfBytes = await pdfDoc.save()
    downloadPdf(pdfBytes, 'con_marca_agua.pdf')
    message.value = { type: 'success', text: '✓ Marca de agua aplicada y descargada' }
  } catch (error) {
    message.value = { type: 'error', text: 'Error: ' + error.message }
  } finally {
    loading.value = false
  }
}

const downloadPdf = (pdfBytes, filename) => {
  const blob = new Blob([pdfBytes], { type: 'application/pdf' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

const reset = () => {
  pdfFile.value = null
  fileLoaded.value = false
  message.value = null
  watermarkText.value = 'CONFIDENCIAL'
  watermarkColor.value = '#999999'
  watermarkOpacity.value = 0.3
  watermarkSize.value = 50
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

.controls {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
}

.controls h2 {
  margin-top: 0;
  color: #333;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
}

.input, .select-input, .color-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
}

.color-input {
  height: 40px;
  cursor: pointer;
}

.range-input {
  width: 100%;
}

.opacity-value {
  margin-left: 10px;
  color: #667eea;
  font-weight: bold;
}

.actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  margin-top: 20px;
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

.preview {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
  text-align: center;
}

.preview h3 {
  margin-top: 0;
  color: #333;
}

.preview-box {
  height: 300px;
  border: 2px dashed #ddd;
  border-radius: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  transform: rotate(-45deg);
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
  .processing {
    grid-template-columns: 1fr;
  }

  .actions {
    flex-direction: column;
  }
}
</style>
