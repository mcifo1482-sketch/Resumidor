<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Retallar PDF</h1>
      <p>Recorta los márgenes de tus páginas</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload" @dragover.prevent @drop.prevent="handleDrop">
          <span class="upload-icon">📐</span>
          <span class="upload-text">Carga tu PDF o usa el botón de abajo</span>
          <input id="file-input" ref="fileInput" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="controls">
          <h2>Configurar recorte</h2>
          
          <div class="info-box">
            <p>Total de páginas: <strong>{{ totalPages }}</strong></p>
          </div>

          <div class="form-group">
            <label for="crop-mode">Tipo de recorte:</label>
            <select id="crop-mode" v-model="cropMode" class="select-input">
              <option value="all">Todas las páginas</option>
              <option value="specific">Página específica</option>
            </select>
          </div>

          <div v-if="cropMode === 'specific'" class="form-group">
            <label for="page-select">Selecciona página:</label>
            <select id="page-select" v-model.number="selectedPage" class="select-input">
              <option v-for="page in totalPages" :key="page" :value="page">
                Página {{ page }}
              </option>
            </select>
          </div>

          <h3>Márgenes a recortar (píxeles)</h3>
          
          <div class="margin-grid">
            <div class="margin-item">
              <label for="margin-top">Arriba:</label>
              <input id="margin-top" v-model.number="margins.top" type="number" min="0" class="margin-input" />
            </div>
            <div class="margin-item">
              <label for="margin-bottom">Abajo:</label>
              <input id="margin-bottom" v-model.number="margins.bottom" type="number" min="0" class="margin-input" />
            </div>
            <div class="margin-item">
              <label for="margin-left">Izquierda:</label>
              <input id="margin-left" v-model.number="margins.left" type="number" min="0" class="margin-input" />
            </div>
            <div class="margin-item">
              <label for="margin-right">Derecha:</label>
              <input id="margin-right" v-model.number="margins.right" type="number" min="0" class="margin-input" />
            </div>
          </div>

          <button @click="resetMargins" class="btn-reset">Restablecer</button>

          <div class="actions">
            <button @click="cropPdf" :disabled="loading" class="btn-primary">
              {{ loading ? 'Retallando...' : (fileLoaded ? '✂️ Retallar' : '📁 Seleccionar PDF') }}
            </button>
            <button @click="reset" class="btn-secondary">Nuevo PDF</button>
          </div>
        </div>

        <div class="preview">
          <h3>Vista previa de recorte</h3>
          <div class="preview-box">
            <div class="content-area" :style="previewStyle">
              <div class="margin" :style="{ top: margins.top + 'px', bottom: margins.bottom + 'px', left: margins.left + 'px', right: margins.right + 'px' }"></div>
              <span>Contenido</span>
            </div>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Retallando PDF...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import * as pdfjsLib from 'pdfjs-dist/legacy/build/pdf'
import { ref, computed } from 'vue'
import { pdfWorkerSrc } from '../../utils/pdfWorker.js'

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorkerSrc

const fileInput = ref(null)
const pdfFile = ref(null)
const fileLoaded = ref(false)
const totalPages = ref(0)
const loading = ref(false)
const message = ref(null)
const cropMode = ref('all')
const selectedPage = ref(1)
const margins = ref({ top: 0, bottom: 0, left: 0, right: 0 })

const previewStyle = computed(() => ({
  borderTop: margins.value.top + 'px solid #ddd',
  borderBottom: margins.value.bottom + 'px solid #ddd',
  borderLeft: margins.value.left + 'px solid #ddd',
  borderRight: margins.value.right + 'px solid #ddd'
}))

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

const handleDrop = (event) => {
  const file = event.dataTransfer.files[0]
  if (!file) return
  const syntheticEvent = { target: { files: [file] } }
  handleFile(syntheticEvent)
}

const cropPdf = async () => {
  // Si no hay archivo cargado, abrir el selector
  if (!pdfFile.value) {
    fileInput.value?.click()
    return
  }

  if (
    margins.value.left + margins.value.right >= 1000 ||
    margins.value.top + margins.value.bottom >= 1000
  ) {
    message.value = { type: 'error', text: 'Márgenes demasiado grandes' }
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('pdf-lib')

    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const existingPdf = await PDFDocument.load(arrayBuffer)
    const total = existingPdf.getPageCount()
    const pageIndex = selectedPage.value - 1

    const validateSelectedPage = () => {
      if (pageIndex < 0 || pageIndex >= total) {
        message.value = { type: 'error', text: 'Selecciona una página válida para recortar.' }
        return false
      }
      return true
    }

    const getCropSize = (page) => {
      const { width, height } = page.getSize()
      return {
        width,
        height,
        cropWidth: Math.max(1, width - margins.value.left - margins.value.right),
        cropHeight: Math.max(1, height - margins.value.top - margins.value.bottom)
      }
    }

    const newPdf = await PDFDocument.create()
    const pages = existingPdf.getPages()

    if (cropMode.value === 'specific') {
      if (!validateSelectedPage()) return

      const copiedPages = await newPdf.copyPages(existingPdf, pages.map((_, index) => index))
      copiedPages.forEach((page) => newPdf.addPage(page))

      const originalPage = pages[pageIndex]
      const { width, height, cropWidth, cropHeight } = getCropSize(originalPage)
      const [embeddedPage] = await newPdf.embedPages([originalPage])
      const croppedPage = newPdf.addPage([cropWidth, cropHeight])

      croppedPage.drawPage(embeddedPage, {
        x: -margins.value.left,
        y: -margins.value.bottom,
        width,
        height
      })

      newPdf.removePage(pageIndex)
      newPdf.insertPage(pageIndex, croppedPage)
    } else {
      for (const page of pages) {
        const { width, height, cropWidth, cropHeight } = getCropSize(page)
        const [embeddedPage] = await newPdf.embedPages([page])
        const croppedPage = newPdf.addPage([cropWidth, cropHeight])

        croppedPage.drawPage(embeddedPage, {
          x: -margins.value.left,
          y: -margins.value.bottom,
          width,
          height
        })
      }
    }

    const pdfBytes = await newPdf.save()
    downloadPdf(pdfBytes, 'retallado.pdf')
    message.value = { type: 'success', text: '✓ PDF retallado y descargado' }
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

const resetMargins = () => {
  margins.value = { top: 0, bottom: 0, left: 0, right: 0 }
}

const reset = () => {
  pdfFile.value = null
  fileLoaded.value = false
  totalPages.value = 0
  message.value = null
  cropMode.value = 'all'
  selectedPage.value = 1
  resetMargins()
  if (fileInput.value) fileInput.value.value = ''
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

.controls h2, .controls h3 {
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

.select-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
}

.margin-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-bottom: 15px;
}

.margin-item {
  display: flex;
  flex-direction: column;
}

.margin-item label {
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
  font-size: 0.9rem;
}

.margin-input {
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 5px;
}

.btn-reset {
  width: 100%;
  padding: 10px;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  margin-bottom: 20px;
}

.btn-reset:hover {
  background: #5a6268;
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
  height: 300px;
  border: 2px solid #ddd;
  border-radius: 5px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: white;
}

.content-area {
  width: 90%;
  height: 90%;
  border: 2px solid #667eea;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #666;
  position: relative;
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
