<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Unir PDF</h1>
      <p>Combina múltiples PDFs en un solo documento</p>
    </div>

    <div class="tool-content">
      <div class="upload-section">
        <label class="file-upload">
          <span class="upload-icon">➕</span>
          <span class="upload-text">Añade PDFs aquí o usa el botón de abajo</span>
          <input type="file" @change="addFile" accept=".pdf" multiple />
        </label>
      </div>

      <div class="actions">
        <button @click="mergePdfs" :disabled="loading" class="btn-primary">
          {{ loading ? 'Uniendo...' : (files.length > 0 ? '🔗 Unir PDFs' : '📁 Seleccionar PDFs') }}
        </button>
        <button v-if="files.length > 0" @click="clearFiles" class="btn-secondary">Limpiar</button>
      </div>

      <div v-if="files.length > 0" class="files-list">
        <h2>Archivos seleccionados</h2>
        <div class="draggable-list">
          <div
            v-for="(file, index) in files"
            :key="index"
            class="file-item"
            draggable="true"
            @dragstart="dragStart = index"
            @dragover.prevent
            @drop="dragEnd(index)"
          >
            <span class="drag-handle">≡</span>
            <span class="file-name">{{ file.name }}</span>
            <button @click="removeFile(index)" class="btn-remove">✕</button>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Uniendo PDFs...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const files = ref([])
const loading = ref(false)
const message = ref(null)
const dragStart = ref(null)

const addFile = (event) => {
  const newFiles = Array.from(event.target.files)
  files.value.push(...newFiles)
  event.target.value = ''
}

const removeFile = (index) => {
  files.value.splice(index, 1)
}

const clearFiles = () => {
  files.value = []
  message.value = null
}

const dragEnd = (index) => {
  if (dragStart.value !== null && dragStart.value !== index) {
    const temp = files.value[dragStart.value]
    files.value[dragStart.value] = files.value[index]
    files.value[index] = temp
  }
  dragStart.value = null
}

const mergePdfs = async () => {
  // Si no hay archivos seleccionados, abrir el selector
  if (files.value.length === 0) {
    document.querySelector('input[type="file"]').click()
    return
  }

  if (files.value.length < 2) {
    message.value = { type: 'error', text: 'Selecciona al menos 2 PDFs' }
    return
  }

  loading.value = true
  message.value = null

  try {
    // Simular la carga de pdfjsLib para fusionar
    const { PDFDocument } = await import('https://cdn.jsdelivr.net/npm/pdf-lib@1.17.1')
    
    const mergedPdf = await PDFDocument.create()

    for (const file of files.value) {
      const arrayBuffer = await file.arrayBuffer()
      const pdfDoc = await PDFDocument.load(arrayBuffer)
      const pages = await mergedPdf.copyPages(pdfDoc, pdfDoc.getPageIndices())
      pages.forEach(page => mergedPdf.addPage(page))
    }

    const pdfBytes = await mergedPdf.save()
    const blob = new Blob([pdfBytes], { type: 'application/pdf' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = 'merged.pdf'
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    message.value = { type: 'success', text: '✓ PDFs unidos correctamente' }
    files.value = []
  } catch (error) {
    message.value = { type: 'error', text: 'Error al unir PDFs: ' + error.message }
  } finally {
    loading.value = false
  }
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

.upload-section {
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

.files-list {
  margin-top: 30px;
}

.files-list h2 {
  color: #333;
  margin-bottom: 15px;
}

.draggable-list {
  background: #f5f7fa;
  border-radius: 5px;
  padding: 10px;
  margin-bottom: 20px;
}

.file-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  background: white;
  border: 1px solid #ddd;
  border-radius: 5px;
  margin-bottom: 8px;
  cursor: move;
  transition: all 0.3s;
}

.file-item:hover {
  background: #f9f9f9;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
}

.drag-handle {
  color: #999;
  font-weight: bold;
}

.file-name {
  flex: 1;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.btn-remove {
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 3px;
  padding: 5px 10px;
  cursor: pointer;
  transition: background 0.3s;
}

.btn-remove:hover {
  background: #c82333;
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
  margin-top: 15px;
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

  .actions {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }
}
</style>
