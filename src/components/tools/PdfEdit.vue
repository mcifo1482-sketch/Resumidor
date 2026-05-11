<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Editar PDF</h1>
      <p>Añade texto, rectángulos y anotaciones a tu PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload">
          <span class="upload-icon">✏️</span>
          <span class="upload-text">Carga tu PDF para editar</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div v-if="fileLoaded" class="processing">
        <div class="editor-controls">
          <h2>Opciones de edición</h2>
          
          <div class="control-group">
            <label for="tool">Herramienta:</label>
            <select id="tool" v-model="selectedTool" class="select-input">
              <option value="text">Texto</option>
              <option value="rectangle">Rectángulo</option>
              <option value="highlight">Resaltado</option>
            </select>
          </div>

          <div v-if="selectedTool === 'text'" class="control-group">
            <label for="text-input">Texto a añadir:</label>
            <input id="text-input" v-model="textInput" type="text" placeholder="Escribe el texto" class="text-input" />
            
            <label for="font-size">Tamaño de fuente:</label>
            <input id="font-size" v-model.number="fontSize" type="number" min="8" max="72" class="number-input" />
            
            <label for="color">Color:</label>
            <input id="color" v-model="textColor" type="color" class="color-input" />
          </div>

          <div v-if="selectedTool === 'rectangle'" class="control-group">
            <label for="rect-color">Color del rectángulo:</label>
            <input id="rect-color" v-model="rectColor" type="color" class="color-input" />
          </div>

          <div class="info-box">
            <p>Total de páginas: <strong>{{ totalPages }}</strong></p>
            <label for="page-num">Selecciona página:</label>
            <select id="page-num" v-model.number="selectedPage" class="select-input">
              <option v-for="page in totalPages" :key="page" :value="page">
                Página {{ page }}
              </option>
            </select>
          </div>

          <div class="actions">
            <button @click="applyEdits" :disabled="loading" class="btn-primary">
              {{ loading ? 'Procesando...' : '💾 Guardar cambios' }}
            </button>
            <button @click="reset" class="btn-secondary">Nuevo PDF</button>
          </div>
        </div>

        <div class="preview-section">
          <p class="note">Los cambios se aplicarán al descargar. Herramienta de previsualización en desarrollo.</p>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Editando PDF...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const pdfFile = ref(null)
const fileLoaded = ref(false)
const totalPages = ref(0)
const loading = ref(false)
const message = ref(null)
const selectedPage = ref(1)
const selectedTool = ref('text')
const textInput = ref('')
const fontSize = ref(12)
const textColor = ref('#000000')
const rectColor = ref('#FF0000')

const handleFile = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  loading.value = true
  message.value = null
  pdfFile.value = file

  try {
    const { PDFDocument } = await import('pdf-lib')
    
    const arrayBuffer = await file.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    totalPages.value = pdfDoc.getPageCount()
    fileLoaded.value = true
  } catch (error) {
    message.value = { type: 'error', text: 'Error al cargar el PDF: ' + error.message }
  } finally {
    loading.value = false
  }
}

const applyEdits = async () => {
  if (!pdfFile.value || !textInput.value) {
    message.value = { type: 'error', text: 'Por favor carga un PDF y completa los campos' }
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument, rgb, degrees } = await import('pdf-lib')
    
    const arrayBuffer = await pdfFile.value.arrayBuffer()
    const pdfDoc = await PDFDocument.load(arrayBuffer)
    const pages = pdfDoc.getPages()
    const page = pages[selectedPage.value - 1]

    if (selectedTool.value === 'text') {
      // Convertir color hex a RGB
      const r = parseInt(textColor.value.substr(1, 2), 16) / 255
      const g = parseInt(textColor.value.substr(3, 2), 16) / 255
      const b = parseInt(textColor.value.substr(5, 2), 16) / 255

      page.drawText(textInput.value, {
        x: 50,
        y: page.getHeight() - 50,
        size: fontSize.value,
        color: rgb(r, g, b)
      })
    } else if (selectedTool.value === 'rectangle') {
      const r = parseInt(rectColor.value.substr(1, 2), 16) / 255
      const g = parseInt(rectColor.value.substr(3, 2), 16) / 255
      const b = parseInt(rectColor.value.substr(5, 2), 16) / 255

      page.drawRectangle({
        x: 50,
        y: page.getHeight() - 150,
        width: 200,
        height: 100,
        borderColor: rgb(r, g, b),
        borderWidth: 2
      })
    } else if (selectedTool.value === 'highlight') {
      const r = parseInt(textColor.value.substr(1, 2), 16) / 255
      const g = parseInt(textColor.value.substr(3, 2), 16) / 255
      const b = parseInt(textColor.value.substr(5, 2), 16) / 255

      page.drawRectangle({
        x: 50,
        y: page.getHeight() - 100,
        width: 300,
        height: 20,
        color: rgb(r, g, b),
        opacity: 0.3
      })
    }

    const pdfBytes = await pdfDoc.save()
    downloadPdf(pdfBytes, 'editado.pdf')
    message.value = { type: 'success', text: '✓ PDF editado y descargado' }
  } catch (error) {
    message.value = { type: 'error', text: 'Error al editar: ' + error.message }
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
  selectedPage.value = 1
  selectedTool.value = 'text'
  textInput.value = ''
  fontSize.value = 12
  textColor.value = '#000000'
  rectColor.value = '#FF0000'
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
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 30px;
}

.editor-controls {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
}

.editor-controls h2 {
  color: #333;
  margin-top: 0;
  margin-bottom: 20px;
}

.control-group {
  margin-bottom: 15px;
}

.control-group label {
  display: block;
  font-weight: bold;
  color: #333;
  margin-bottom: 5px;
}

.select-input,
.text-input,
.number-input,
.color-input {
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

.info-box {
  background: #f0f4ff;
  border-left: 4px solid #667eea;
  padding: 15px;
  border-radius: 5px;
  margin: 20px 0;
}

.info-box p {
  color: #333;
  margin-bottom: 10px;
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
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  flex: 1;
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
  flex: 1;
}

.btn-secondary:hover {
  background: #5a6268;
}

.preview-section {
  background: #f5f7fa;
  border: 2px dashed #ddd;
  border-radius: 5px;
  padding: 20px;
  text-align: center;
}

.note {
  color: #666;
  font-style: italic;
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
