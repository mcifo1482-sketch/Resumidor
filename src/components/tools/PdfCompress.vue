<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Comprimir PDF</h1>
      <p>Reduce el tamaño de tu PDF manteniendo la calidad</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">📦</span>
          <span class="upload-text">Carga tu PDF para comprimir o usa el botón de abajo</span>
          <input id="file-input" ref="fileInput" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div class="actions">
        <button @click="compressPdf" :disabled="loading" class="btn-primary">
          {{ loading ? 'Comprimiendo...' : (fileLoaded ? '🗜️ Comprimir PDF' : '📁 Seleccionar PDF') }}
        </button>
        <button v-if="fileLoaded" @click="reset" class="btn-secondary">Nuevo PDF</button>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="info-box">
          <div class="info-item">
            <span class="label">Tamaño original:</span>
            <span class="value">{{ formatFileSize(originalSize) }}</span>
          </div>
          <div class="info-item">
            <span class="label">Calidad:</span>
            <select v-model="quality" class="quality-select">
              <option value="low">Baja (más comprimido)</option>
              <option value="medium">Media (balanceado)</option>
              <option value="high">Alta (menos comprimido)</option>
            </select>
          </div>
        </div>

        <div v-if="compressedSize" class="result-box">
          <h3>Resultado</h3>
          <div class="result-grid">
            <div class="result-item">
              <span>Tamaño comprimido:</span>
              <strong>{{ formatFileSize(compressedSize) }}</strong>
            </div>
            <div class="result-item">
              <span>Reducción:</span>
              <strong>{{ compressionPercent }}%</strong>
            </div>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Comprimiendo PDF...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import * as pdfjsLib from 'pdfjs-dist/legacy/build/pdf'
import { pdfWorkerSrc } from '../../utils/pdfWorker.js'

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorkerSrc

const fileInput = ref(null)
const fileData = ref(null)
const fileLoaded = ref(false)
const originalSize = ref(0)
const compressedSize = ref(0)
const loading = ref(false)
const message = ref(null)
const quality = ref('medium')

const compressionPercent = computed(() => {
  if (!compressedSize.value || !originalSize.value) return 0
  return Math.round(((originalSize.value - compressedSize.value) / originalSize.value) * 100)
})

const formatFileSize = (bytes) => {
  if (bytes === 0) return '0 Bytes'
  const k = 1024
  const sizes = ['Bytes', 'KB', 'MB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
}

const handleFile = async (event) => {
  const file = event.target.files?.[0]
  if (!file) return

  fileData.value = file
  originalSize.value = file.size
  fileLoaded.value = true
  compressedSize.value = 0
  message.value = null
}

const openFileDialog = () => {
  fileInput.value?.click()
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

const compressPdf = async () => {
  if (!fileData.value) {
    openFileDialog()
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('pdf-lib')
    const arrayBuffer = await fileData.value.arrayBuffer()
    const typedArray = new Uint8Array(arrayBuffer)
    const pdf = await pdfjsLib.getDocument(typedArray).promise
    const outputPdf = await PDFDocument.create()

    const qualitySettings = {
      low: { scale: 1, jpegQuality: 0.6 },
      medium: { scale: 1.5, jpegQuality: 0.8 },
      high: { scale: 2, jpegQuality: 0.95 }
    }

    const { scale, jpegQuality } = qualitySettings[quality.value] || qualitySettings.medium

    for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
      const page = await pdf.getPage(pageNum)
      const viewport = page.getViewport({ scale })
      const canvas = document.createElement('canvas')
      const context = canvas.getContext('2d')
      canvas.width = Math.floor(viewport.width)
      canvas.height = Math.floor(viewport.height)

      const renderContext = {
        canvasContext: context,
        viewport
      }

      await page.render(renderContext).promise

      const blob = await new Promise((resolve, reject) => {
        canvas.toBlob(
          (blob) => {
            if (blob) resolve(blob)
            else reject(new Error('No se pudo generar la imagen'))
          },
          'image/jpeg',
          jpegQuality
        )
      })

      const imageBytes = await blob.arrayBuffer()
      const jpgImage = await outputPdf.embedJpg(imageBytes)
      const outputPage = outputPdf.addPage([canvas.width, canvas.height])
      outputPage.drawImage(jpgImage, {
        x: 0,
        y: 0,
        width: canvas.width,
        height: canvas.height
      })
    }

    const compressedBytes = await outputPdf.save({ useObjectStreams: true, useCompression: true })
    compressedSize.value = compressedBytes.length
    downloadPdf(compressedBytes, 'comprimido.pdf')
    message.value = {
      type: 'success',
      text: `✓ PDF comprimido y descargado (${formatFileSize(compressedSize.value)})`
    }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al comprimir: ' + error.message }
  } finally {
    loading.value = false
  }
}

const reset = () => {
  fileData.value = null
  fileLoaded.value = false
  originalSize.value = 0
  compressedSize.value = 0
  quality.value = 'medium'
  message.value = null
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
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-box {
  background: #f0f4ff;
  border-left: 4px solid #667eea;
  padding: 20px;
  border-radius: 5px;
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.info-item .label {
  font-weight: bold;
  color: #333;
}

.info-item .value {
  font-size: 1.1rem;
  color: #667eea;
  font-weight: bold;
}

.quality-select {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
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

.result-box {
  background: #d4edda;
  border-left: 4px solid #28a745;
  padding: 20px;
  border-radius: 5px;
}

.result-box h3 {
  margin-top: 0;
  color: #155724;
}

.result-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 15px;
}

.result-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.result-item span {
  font-size: 0.9rem;
  color: #155724;
}

.result-item strong {
  font-size: 1.2rem;
  color: #155724;
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

  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
  }

  .actions {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }
}
</style>
