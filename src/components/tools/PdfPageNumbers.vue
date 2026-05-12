<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Números de Página</h1>
      <p>Añade números a las páginas de tu PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">🔢</span>
          <span class="upload-text">Carga tu PDF o usa el botón de abajo</span>
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="controls">
          <h2>Configurar números de página</h2>
          
          <div class="info-box">
            <p>Total de páginas: <strong>{{ totalPages }}</strong></p>
          </div>

          <div class="form-group">
            <label for="start-number">Número inicial:</label>
            <input id="start-number" v-model.number="startNumber" type="number" min="0" class="input" />
          </div>

          <div class="form-group">
            <label for="position">Posición:</label>
            <select id="position" v-model="position" class="select-input">
              <option value="bottom-center">Abajo Centro</option>
              <option value="bottom-left">Abajo Izquierda</option>
              <option value="bottom-right">Abajo Derecha</option>
              <option value="top-center">Arriba Centro</option>
              <option value="top-left">Arriba Izquierda</option>
              <option value="top-right">Arriba Derecha</option>
            </select>
          </div>

          <div class="form-group">
            <label for="font-size">Tamaño de fuente:</label>
            <input id="font-size" v-model.number="fontSize" type="number" min="8" max="48" class="input" />
          </div>

          <div class="form-group">
            <label for="format">Formato:</label>
            <select id="format" v-model="format" class="select-input">
              <option value="number">Solo número (1, 2, 3...)</option>
              <option value="dash">Con guiones (-1-, -2-...)</option>
              <option value="paren">Entre paréntesis ((1), (2)...)</option>
            </select>
          </div>

          <div class="form-group">
            <label>
              <input type="checkbox" v-model="skipFirstPage" />
              No numerar la primera página
            </label>
          </div>

          <div class="actions">
            <button @click="addPageNumbers" :disabled="loading" class="btn-primary">
              {{ loading ? 'Añadiendo...' : (fileLoaded ? '➕ Añadir números' : '📁 Seleccionar PDF') }}
            </button>
            <button @click="reset" class="btn-secondary">Nuevo PDF</button>
          </div>
        </div>

        <div class="preview">
          <h3>Vista previa</h3>
          <div class="preview-box">
            <div class="preview-page">
              <div class="page-content">Contenido de página</div>
              <div :class="['page-number', `position-${position}`]">
                {{ formatNumber(1) }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Añadiendo números de página...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import * as pdfjsLib from 'pdfjs-dist'
import { ref } from 'vue'

pdfjsLib.GlobalWorkerOptions.workerSrc =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.worker.min.js'

const pdfFile = ref(null)
const fileLoaded = ref(false)
const totalPages = ref(0)
const loading = ref(false)
const message = ref(null)
const startNumber = ref(1)
const position = ref('bottom-center')
const fontSize = ref(12)
const format = ref('number')
const skipFirstPage = ref(false)

const handleFile = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  loading.value = true
  message.value = null
  pdfFile.value = file

  try {
    const arrayBuffer = await file.arrayBuffer()
    const typedArray = new Uint8Array(arrayBuffer)
    const pdf = await pdfjsLib.getDocument(typedArray).promise
    totalPages.value = pdf.numPages
    fileLoaded.value = true
  } catch (error) {
    message.value = { type: 'error', text: 'Error al cargar: ' + error.message }
  } finally {
    loading.value = false
  }
}

const formatNumber = (num) => {
  switch (format.value) {
    case 'dash':
      return `-${num}-`
    case 'paren':
      return `(${num})`
    default:
      return num.toString()
  }
}

const getPositionCoordinates = (pageWidth, pageHeight, pageNum) => {
  const padding = 20
  let x, y
  const pageNumberText = formatNumber(pageNum)

  switch (position.value) {
    case 'bottom-center':
      x = pageWidth / 2
      y = padding
      break
    case 'bottom-left':
      x = padding
      y = padding
      break
    case 'bottom-right':
      x = pageWidth - padding - pageNumberText.length * 5
      y = padding
      break
    case 'top-center':
      x = pageWidth / 2
      y = pageHeight - padding - fontSize.value
      break
    case 'top-left':
      x = padding
      y = pageHeight - padding - fontSize.value
      break
    case 'top-right':
      x = pageWidth - padding - pageNumberText.length * 5
      y = pageHeight - padding - fontSize.value
      break
  }

  return { x, y }
}

const addPageNumbers = async () => {
  if (!pdfFile.value) return

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('pdf-lib')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    const pages = pdfDoc.getPages()

    pages.forEach((page, index) => {
      const pageNumber = index + startNumber.value
      
      if (skipFirstPage.value && index === 0) {
        return
      }

      const { width, height } = page.getSize()
      const { x, y } = getPositionCoordinates(width, height, pageNumber)
      const pageNumberText = formatNumber(pageNumber)

      page.drawText(pageNumberText, {
        x,
        y,
        size: fontSize.value,
        color: { r: 0, g: 0, b: 0 }
      })
    })

    const pdfBytes = await pdfDoc.save()
    downloadPdf(pdfBytes, 'con_numeros.pdf')
    message.value = { type: 'success', text: '✓ Números de página añadidos y descargado' }
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
  totalPages.value = 0
  message.value = null
  startNumber.value = 1
  position.value = 'bottom-center'
  fontSize.value = 12
  format.value = 'number'
  skipFirstPage.value = false
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
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
}

.input, .select-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
}

.form-group input[type="checkbox"] {
  width: 18px;
  height: 18px;
  margin-right: 8px;
  cursor: pointer;
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
}

.preview h3 {
  margin-top: 0;
  color: #333;
}

.preview-box {
  background: white;
  border: 2px solid #ddd;
  border-radius: 5px;
  padding: 20px;
  min-height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.preview-page {
  width: 100%;
  height: 200px;
  border: 1px solid #667eea;
  border-radius: 3px;
  position: relative;
  background: #fafafa;
}

.page-content {
  padding: 20px;
  color: #999;
  text-align: center;
}

.page-number {
  position: absolute;
  font-size: 12px;
  font-weight: bold;
  color: #333;
}

.position-bottom-center {
  bottom: 10px;
  left: 50%;
  transform: translateX(-50%);
}

.position-bottom-left {
  bottom: 10px;
  left: 10px;
}

.position-bottom-right {
  bottom: 10px;
  right: 10px;
}

.position-top-center {
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
}

.position-top-left {
  top: 10px;
  left: 10px;
}

.position-top-right {
  top: 10px;
  right: 10px;
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
