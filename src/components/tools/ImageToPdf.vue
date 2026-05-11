<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Imagen a PDF</h1>
      <p>Convierte tus imágenes JPG/PNG a PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label class="file-upload">
          <span class="upload-icon">📸</span>
          <span class="upload-text">Carga tus imágenes (JPG, PNG)</span>
          <input type="file" @change="handleFiles" accept=".jpg,.jpeg,.png" multiple />
        </label>
      </div>

      <div v-if="images.length > 0" class="images-list">
        <h2>Imágenes seleccionadas</h2>
        <div class="draggable-list">
          <div
            v-for="(image, index) in images"
            :key="index"
            class="image-item"
            draggable="true"
            @dragstart="dragStart = index"
            @dragover.prevent
            @drop="dragEnd(index)"
          >
            <span class="drag-handle">≡</span>
            <img :src="image.preview" :alt="image.name" class="thumbnail" />
            <span class="image-name">{{ image.name }}</span>
            <button @click="removeImage(index)" class="btn-remove">✕</button>
          </div>
        </div>

        <div class="options">
          <h3>Opciones de conversión</h3>
          <div class="option-group">
            <label for="page-size">Tamaño de página:</label>
            <select id="page-size" v-model="pageSize" class="select-input">
              <option value="A4">A4</option>
              <option value="Letter">Letter</option>
              <option value="A3">A3</option>
            </select>
          </div>

          <div class="option-group">
            <label for="orientation">Orientación:</label>
            <select id="orientation" v-model="orientation" class="select-input">
              <option value="portrait">Vertical</option>
              <option value="landscape">Horizontal</option>
            </select>
          </div>

          <div class="option-group">
            <label>
              <input type="checkbox" v-model="fitToPage" />
              Ajustar imagen a página
            </label>
          </div>
        </div>

        <div class="actions">
          <button @click="convertToPdf" :disabled="loading" class="btn-primary">
            {{ loading ? 'Convirtiendo...' : '📄 Convertir a PDF' }}
          </button>
          <button @click="clearImages" class="btn-secondary">Limpiar</button>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Convirtiendo imágenes a PDF...</p>
      <p v-if="message" :class="['message', message.type]">{{ message.text }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const images = ref([])
const loading = ref(false)
const message = ref(null)
const dragStart = ref(null)
const pageSize = ref('A4')
const orientation = ref('portrait')
const fitToPage = ref(true)

const handleFiles = (event) => {
  const newFiles = Array.from(event.target.files)
  newFiles.forEach(file => {
    const reader = new FileReader()
    reader.onload = (e) => {
      images.value.push({
        name: file.name,
        preview: e.target.result,
        file: file
      })
    }
    reader.readAsDataURL(file)
  })
  event.target.value = ''
}

const removeImage = (index) => {
  images.value.splice(index, 1)
}

const clearImages = () => {
  images.value = []
  message.value = null
}

const dragEnd = (index) => {
  if (dragStart.value !== null && dragStart.value !== index) {
    const temp = images.value[dragStart.value]
    images.value[dragStart.value] = images.value[index]
    images.value[index] = temp
  }
  dragStart.value = null
}

const convertToPdf = async () => {
  if (images.value.length === 0) {
    message.value = { type: 'error', text: 'Por favor selecciona al menos una imagen' }
    return
  }

  loading.value = true
  message.value = null

  try {
    const { PDFDocument } = await import('pdf-lib')
    
    const pdfDoc = await PDFDocument.create()

    const pageSizes = {
      A4: { width: 595, height: 842 },
      Letter: { width: 612, height: 792 },
      A3: { width: 842, height: 1190 }
    }

    const currentSize = pageSizes[pageSize.value]
    const width = orientation.value === 'portrait' ? currentSize.width : currentSize.height
    const height = orientation.value === 'portrait' ? currentSize.height : currentSize.width

    for (const image of images.value) {
      const imgData = await fetch(image.preview).then(r => r.arrayBuffer())
      const mimeType = image.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg'
      
      let embeddedImage
      if (mimeType === 'image/png') {
        embeddedImage = await pdfDoc.embedPng(imgData)
      } else {
        embeddedImage = await pdfDoc.embedJpg(imgData)
      }

      const page = pdfDoc.addPage([width, height])
      
      if (fitToPage.value) {
        const imgDims = embeddedImage.scale(1)
        const scaleFactor = Math.min(
          (width - 20) / imgDims.width,
          (height - 20) / imgDims.height
        )
        page.drawImage(embeddedImage, {
          x: (width - imgDims.width * scaleFactor) / 2,
          y: (height - imgDims.height * scaleFactor) / 2,
          width: imgDims.width * scaleFactor,
          height: imgDims.height * scaleFactor
        })
      } else {
        page.drawImage(embeddedImage, {
          x: 10,
          y: 10,
          width: width - 20,
          height: height - 20
        })
      }
    }

    const pdfBytes = await pdfDoc.save()
    downloadPdf(pdfBytes, 'imagenes.pdf')
    message.value = { type: 'success', text: `✓ ${images.value.length} imagen(es) convertida(s) a PDF` }
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

.images-list {
  margin-top: 30px;
}

.images-list h2 {
  color: #333;
  margin-bottom: 15px;
}

.draggable-list {
  background: #f5f7fa;
  border-radius: 5px;
  padding: 10px;
  margin-bottom: 20px;
}

.image-item {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 10px;
  background: white;
  border: 1px solid #ddd;
  border-radius: 5px;
  margin-bottom: 8px;
  cursor: move;
}

.drag-handle {
  color: #999;
  font-weight: bold;
}

.thumbnail {
  width: 50px;
  height: 50px;
  object-fit: cover;
  border-radius: 3px;
}

.image-name {
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
}

.btn-remove:hover {
  background: #c82333;
}

.options {
  background: #f5f7fa;
  padding: 20px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.options h3 {
  color: #333;
  margin-top: 0;
}

.option-group {
  margin-bottom: 15px;
}

.option-group label {
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

  .image-item {
    flex-wrap: wrap;
  }

  .actions {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }
}
</style>
