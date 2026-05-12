<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>PDF a Imagen</h1>
      <p>Convierte páginas de tu PDF a imágenes JPG</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">🖼️</span>
          <span class="upload-text">Carga tu PDF o usa el botón de abajo</span>
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="info-box">
          <div class="info-item">
            <span class="label">Total de páginas:</span>
            <span class="value">{{ totalPages }}</span>
          </div>
        </div>

        <div class="conversion-options">
          <h2>Opciones de conversión</h2>
          
          <div class="option-group">
            <label>¿Qué páginas convertir?</label>
            <div class="option">
              <label>
                <input type="radio" v-model="selectionMode" value="all" />
                Todas las páginas
              </label>
            </div>
            <div class="option">
              <label>
                <input type="radio" v-model="selectionMode" value="range" />
                Rango específico
              </label>
              <div v-if="selectionMode === 'range'" class="option-content">
                <input v-model.number="rangeStart" type="number" min="1" :max="totalPages" />
                <span>a</span>
                <input v-model.number="rangeEnd" type="number" min="1" :max="totalPages" />
              </div>
            </div>
          </div>

          <div class="option-group">
            <label for="quality">Calidad de la imagen:</label>
            <select id="quality" v-model="imageQuality" class="select-input">
              <option value="low">Baja (más pequeña)</option>
              <option value="medium">Media</option>
              <option value="high">Alta (más grande)</option>
            </select>
          </div>

          <div class="option-group">
            <label for="scale">Escala de resolución:</label>
            <select id="scale" v-model.number="scale" class="select-input">
              <option value="1">100%</option>
              <option value="1.5">150%</option>
              <option value="2">200%</option>
            </select>
          </div>
        </div>

        <div class="actions">
          <button @click="convertToImage" :disabled="loading" class="btn-primary">
            {{ loading ? 'Convirtiendo...' : (fileLoaded ? '✨ Convertir a Imagen' : '📁 Seleccionar PDF') }}
          </button>
          <button @click="reset" class="btn-secondary">Nuevo PDF</button>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Convirtiendo PDF a imágenes...</p>
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
const selectionMode = ref('all')
const rangeStart = ref(1)
const rangeEnd = ref(1)
const imageQuality = ref('high')
const scale = ref(2)

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
    rangeEnd.value = totalPages.value
  } catch (error) {
    message.value = { type: 'error', text: 'Error al cargar el PDF: ' + error.message }
  } finally {
    loading.value = false
  }
}

const convertToImage = async () => {
  // Si no hay PDF cargado, abrir el selector
  if (!pdfFile.value) {
    document.getElementById('file-input').click()
    return
  }

  loading.value = true
  message.value = null

  try {
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const typedArray = new Uint8Array(arrayBuffer)
    const pdf = await pdfjsLib.getDocument(typedArray).promise

    let pagesToConvert = []
    if (selectionMode.value === 'all') {
      pagesToConvert = Array.from({ length: totalPages.value }, (_, i) => i + 1)
    } else {
      const start = Math.max(1, rangeStart.value)
      const end = Math.min(totalPages.value, rangeEnd.value)
      pagesToConvert = Array.from({ length: end - start + 1 }, (_, i) => start + i)
    }

    // Determinar escala del canvas
    const canvasScale = scale.value
    let downloadCount = 0

    for (const pageNum of pagesToConvert) {
      const page = await pdf.getPage(pageNum)
      const viewport = page.getViewport({ scale: canvasScale })

      const canvas = document.createElement('canvas')
      const context = canvas.getContext('2d')
      canvas.height = viewport.height
      canvas.width = viewport.width

      const renderContext = {
        canvasContext: context,
        viewport: viewport
      }

      await page.render(renderContext).promise

      // Convertir a JPEG
      canvas.toBlob(
        (blob) => {
          const url = URL.createObjectURL(blob)
          const a = document.createElement('a')
          a.href = url
          a.download = `pagina_${pageNum}.jpg`
          document.body.appendChild(a)
          a.click()
          document.body.removeChild(a)
          URL.revokeObjectURL(url)
          downloadCount++

          if (downloadCount === pagesToConvert.length) {
            message.value = {
              type: 'success',
              text: `✓ ${downloadCount} imagen(es) convertida(s) y descargada(s)`
            }
            loading.value = false
          }
        },
        'image/jpeg',
        imageQuality.value === 'low' ? 0.6 : imageQuality.value === 'medium' ? 0.8 : 0.95
      )
    }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al convertir: ' + error.message }
    loading.value = false
  }
}

const reset = () => {
  pdfFile.value = null
  fileLoaded.value = false
  totalPages.value = 0
  message.value = null
  selectionMode.value = 'all'
  rangeStart.value = 1
  rangeEnd.value = 1
  imageQuality.value = 'high'
  scale.value = 2
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
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.info-box {
  background: #f0f4ff;
  border-left: 4px solid #667eea;
  padding: 20px;
  border-radius: 5px;
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

.conversion-options {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
}

.conversion-options h2 {
  color: #333;
  margin-top: 0;
  margin-bottom: 15px;
}

.option-group {
  margin-bottom: 20px;
}

.option-group label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.option {
  margin-left: 20px;
  margin-bottom: 10px;
}

.option label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: normal;
  cursor: pointer;
}

.option input[type="radio"] {
  cursor: pointer;
  width: 16px;
  height: 16px;
}

.option-content {
  margin-top: 10px;
  margin-left: 30px;
  display: flex;
  gap: 10px;
  align-items: center;
  flex-wrap: wrap;
}

.option-content input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 5px;
  width: 120px;
}

.select-input {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-size: 1rem;
  min-width: 200px;
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

  .option-content {
    flex-direction: column;
    margin-left: 0;
  }

  .option-content input {
    width: 100%;
  }

  .select-input {
    min-width: auto;
    width: 100%;
  }

  .actions {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }
}
</style>
