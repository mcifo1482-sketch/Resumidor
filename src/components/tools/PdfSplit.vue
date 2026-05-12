<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Dividir PDF</h1>
      <p>Extrae páginas específicas de tu PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">✂️</span>
          <span class="upload-text">Carga tu PDF aquí</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="pdfLoaded" class="processing">
        <div class="info-box">
          <p>Total de páginas: <strong>{{ totalPages }}</strong></p>
        </div>

        <div class="page-selection">
          <h2>Selecciona las páginas a extraer</h2>
          <div class="selection-options">
            <div class="option">
              <label>
                <input type="radio" v-model="selectionMode" value="range" />
                Rango de páginas
              </label>
              <div v-if="selectionMode === 'range'" class="option-content">
                <input v-model.number="rangeStart" type="number" min="1" :max="totalPages" placeholder="Página inicio" />
                <span>a</span>
                <input v-model.number="rangeEnd" type="number" min="1" :max="totalPages" placeholder="Página fin" />
              </div>
            </div>

            <div class="option">
              <label>
                <input type="radio" v-model="selectionMode" value="individual" />
                Páginas individuales
              </label>
              <div v-if="selectionMode === 'individual'" class="option-content">
                <input v-model="individualPages" type="text" placeholder="Ej: 1,3,5" />
                <small>Separa los números con comas</small>
              </div>
            </div>

            <div class="option">
              <label>
                <input type="radio" v-model="selectionMode" value="all" />
                Dividir en PDFs individuales
              </label>
            </div>
          </div>
        </div>

        <div class="actions">
          <button @click="splitPdf" :disabled="loading" class="btn-primary">
            {{ loading ? 'Procesando...' : '🔪 Dividir PDF' }}
          </button>
          <button @click="reset" class="btn-secondary">Nuevo PDF</button>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Dividiendo PDF...</p>
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
const pdfLoaded = ref(false)
const totalPages = ref(0)
const loading = ref(false)
const message = ref(null)
const selectionMode = ref('range')
const rangeStart = ref(1)
const rangeEnd = ref(1)
const individualPages = ref('')

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
    pdfLoaded.value = true
    rangeEnd.value = totalPages.value
  } catch (error) {
    message.value = { type: 'error', text: 'Error al cargar el PDF: ' + error.message }
  } finally {
    loading.value = false
  }
}

const splitPdf = async () => {
  if (!pdfFile.value) return

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    const pages = pdfDoc.getPages()

    let pagesToExtract = []

    if (selectionMode.value === 'range') {
      const start = Math.max(1, rangeStart.value)
      const end = Math.min(totalPages.value, rangeEnd.value)
      pagesToExtract = Array.from({ length: end - start + 1 }, (_, i) => start + i - 1)
    } else if (selectionMode.value === 'individual') {
      pagesToExtract = individualPages.value
        .split(',')
        .map(p => parseInt(p.trim()) - 1)
        .filter(p => p >= 0 && p < totalPages.value)
    } else {
      // Dividir en PDFs individuales
      for (let i = 0; i < pages.length; i++) {
        const newPdf = await PDFDocument.create()
        const [page] = await newPdf.copyPages(pdfDoc, [i])
        newPdf.addPage(page)

        const pdfBytes = await newPdf.save()
        downloadPdf(pdfBytes, `pagina_${i + 1}.pdf`)
      }
      message.value = { type: 'success', text: `✓ Se descargaron ${pages.length} PDFs` }
      loading.value = false
      return
    }

    if (pagesToExtract.length === 0) {
      message.value = { type: 'error', text: 'No se seleccionaron páginas válidas' }
      loading.value = false
      return
    }

    const newPdf = await PDFDocument.create()

    // Copiar las páginas seleccionadas al nuevo PDF
    for (const pageIndex of pagesToExtract) {
      const [copiedPage] = await newPdf.copyPages(pdfDoc, [pageIndex])
      newPdf.addPage(copiedPage)
    }

    const pdfBytes = await newPdf.save()
    downloadPdf(pdfBytes, 'dividido.pdf')

    message.value = { type: 'success', text: `✓ PDF dividido correctamente (${pagesToExtract.length} páginas)` }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al dividir: ' + error.message }
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
  pdfLoaded.value = false
  totalPages.value = 0
  message.value = null
  selectionMode.value = 'range'
  rangeStart.value = 1
  rangeEnd.value = 1
  individualPages.value = ''
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
  position: relative;
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
  gap: 25px;
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

.page-selection h2 {
  color: #333;
  margin-bottom: 15px;
}

.selection-options {
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

.option-content small {
  color: #666;
  width: 100%;
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

  .actions {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }
}
</style>
