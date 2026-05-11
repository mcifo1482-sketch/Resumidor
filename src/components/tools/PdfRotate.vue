<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Rotar PDF</h1>
      <p>Cambia la orientación de las páginas de tu PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">🔄</span>
          <span class="upload-text">Carga tu PDF para rotar</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="info-box">
          <p>Total de páginas: <strong>{{ totalPages }}</strong></p>
        </div>

        <div class="rotation-options">
          <h2>Selecciona páginas a rotar</h2>
          <div class="option">
            <label>
              <input type="radio" v-model="rotationMode" value="all" />
              Rotar todas las páginas
            </label>
          </div>
          <div class="option">
            <label>
              <input type="radio" v-model="rotationMode" value="range" />
              Rotar rango específico
            </label>
            <div v-if="rotationMode === 'range'" class="option-content">
              <input v-model.number="rangeStart" type="number" min="1" :max="totalPages" placeholder="Página inicio" />
              <span>a</span>
              <input v-model.number="rangeEnd" type="number" min="1" :max="totalPages" placeholder="Página fin" />
            </div>
          </div>

          <div class="rotation-angle">
            <label>Ángulo de rotación:</label>
            <div class="angle-buttons">
              <button
                v-for="angle in [90, 180, 270]"
                :key="angle"
                @click="rotationAngle = angle"
                :class="['angle-btn', { active: rotationAngle === angle }]"
              >
                {{ angle }}°
              </button>
            </div>
          </div>
        </div>

        <div class="actions">
          <button @click="rotatePdf" :disabled="loading" class="btn-primary">
            {{ loading ? 'Rotando...' : '↻ Rotar PDF' }}
          </button>
          <button @click="reset" class="btn-secondary">Nuevo PDF</button>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Rotando PDF...</p>
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
const rotationMode = ref('all')
const rangeStart = ref(1)
const rangeEnd = ref(1)
const rotationAngle = ref(90)

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

const rotatePdf = async () => {
  if (!pdfFile.value) return

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    const pages = pdfDoc.getPages()

    let pagesToRotate = []

    if (rotationMode.value === 'all') {
      pagesToRotate = Array.from({ length: totalPages.value }, (_, i) => i)
    } else {
      const start = Math.max(0, rangeStart.value - 1)
      const end = Math.min(totalPages.value - 1, rangeEnd.value - 1)
      pagesToRotate = Array.from({ length: end - start + 1 }, (_, i) => start + i)
    }

    pagesToRotate.forEach(pageIndex => {
      const page = pages[pageIndex]
      const currentRotation = page.getRotation().angle || 0
      const newRotation = (currentRotation + rotationAngle.value) % 360
      page.setRotation(newRotation)
    })

    const pdfBytes = await pdfDoc.save()
    const blob = new Blob([pdfBytes], { type: 'application/pdf' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'rotado.pdf'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    message.value = { type: 'success', text: `✓ PDF rotado correctamente (${pagesToRotate.length} páginas)` }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al rotar: ' + error.message }
  } finally {
    loading.value = false
  }
}

const reset = () => {
  pdfFile.value = null
  fileLoaded.value = false
  totalPages.value = 0
  message.value = null
  rotationMode.value = 'all'
  rangeStart.value = 1
  rangeEnd.value = 1
  rotationAngle.value = 90
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
  display: none;
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
  padding: 15px;
  border-radius: 5px;
}

.info-box p {
  color: #333;
  font-size: 1.1rem;
  margin: 0;
}

.rotation-options h2 {
  color: #333;
  margin-bottom: 15px;
  margin-top: 0;
}

.rotation-options {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
}

.option {
  margin-bottom: 20px;
}

.option label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: bold;
  color: #333;
}

.option input[type="radio"] {
  cursor: pointer;
  width: 18px;
  height: 18px;
}

.option-content {
  margin-top: 10px;
  padding: 15px;
  background: white;
  border-radius: 5px;
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

.rotation-angle {
  margin-top: 20px;
}

.rotation-angle label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}

.angle-buttons {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.angle-btn {
  padding: 10px 20px;
  border: 2px solid #ddd;
  border-radius: 5px;
  background: white;
  cursor: pointer;
  transition: all 0.3s;
  font-weight: bold;
}

.angle-btn:hover {
  border-color: #667eea;
}

.angle-btn.active {
  background: #667eea;
  color: white;
  border-color: #667eea;
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
  }

  .option-content input {
    width: 100%;
  }

  .angle-buttons {
    flex-direction: column;
  }

  .angle-btn {
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
