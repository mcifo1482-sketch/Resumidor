<template>
  <div class="tool-container">
    <div class="tool-header">
      <h1>Resumir PDF</h1>
      <p>Genera un resumen inteligente de tu documento PDF</p>
    </div>

    <div class="tool-content">
      <div class="upload-area">
        <label for="file-input" class="file-upload" @dragover.prevent @drop.prevent="handleDrop">
          <span class="upload-icon">📤</span>
          <span class="upload-text">Arrastra tu PDF aquí o usa el botón de abajo</span>
          <input id="file-input" ref="fileInput" type="file" @change="handleFile" accept=".pdf" />
        </label>
      </div>

      <div class="controls">
        <div v-if="text" class="control-group">
          <label for="num-sentences">Número de frases en el resumen:</label>
          <input id="num-sentences" type="number" v-model.number="numSentences" min="1" max="10" />
        </div>
        <button @click="summarizeText" :disabled="loading" class="btn-primary">
          {{ loading ? 'Procesando...' : (fileLoaded ? 'Generar resumen' : '📁 Seleccionar PDF') }}
        </button>
      </div>

      <div v-if="message" :class="['message', message.type]">{{ message.text }}</div>

      <div v-if="text" class="processing">
        <div class="text-section">
          <h2>Texto extraído</h2>
          <textarea v-model="text" readonly class="text-area"></textarea>
        </div>

        <div v-if="summary" class="summary-section">
          <h2>Resumen</h2>
          <p class="summary-text">{{ summary }}</p>
          <div class="summary-actions">
            <button @click="downloadSummary" class="btn-secondary">📥 Descargar resumen</button>
            <button @click="reset" class="btn-secondary">🔄 Nuevo PDF</button>
          </div>
        </div>
      </div>

      <p v-if="loading" class="loading-message">Procesando PDF...</p>
    </div>
  </div>
</template>

<script setup>
import * as pdfjsLib from 'pdfjs-dist'
import { ref } from 'vue'
import { pdfWorkerSrc } from '../../utils/pdfWorker.js'

pdfjsLib.GlobalWorkerOptions.workerSrc = pdfWorkerSrc

const fileInput = ref(null)
const text = ref('')
const summary = ref('')
const loading = ref(false)
const fileLoaded = ref(false)
const message = ref(null)
const numSentences = ref(5)

const stopWords = new Set([
  'de', 'la', 'que', 'el', 'en', 'y', 'a', 'los', 'se', 'del', 'las', 'por', 'un', 'para',
  'con', 'no', 'una', 'su', 'al', 'es', 'lo', 'como', 'más', 'pero', 'sus', 'le', 'ya', 'o',
  'este', 'sí', 'porque', 'esta', 'entre', 'cuando', 'muy', 'sin', 'sobre', 'también', 'me',
  'hasta', 'hay', 'donde', 'quien', 'desde', 'todo', 'nos', 'durante', 'todos', 'uno', 'les',
  'ni', 'contra', 'otros', 'ese', 'eso', 'ante', 'ellos', 'e', 'esto', 'mí', 'antes', 'algunos',
  'qué', 'unos', 'yo', 'otro', 'otras', 'otra', 'él', 'tanto', 'esa', 'estos', 'mucho', 'quienes',
  'nada', 'muchos', 'cual', 'poco', 'ella', 'estar', 'estas', 'algunas', 'algo', 'nosotros', 'mi'
])

const processPdfFile = async (file) => {
  if (!file) return

  loading.value = true
  text.value = ''
  summary.value = ''
  message.value = null

  const reader = new FileReader()

  reader.onload = async function () {
    try {
      const typedArray = new Uint8Array(this.result)
      const pdf = await pdfjsLib.getDocument(typedArray).promise
      let fullText = ''

      for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i)
        const content = await page.getTextContent()
        const strings = content.items.map(item => item.str)
        fullText += strings.join(' ') + '\n'
      }

      text.value = fullText.trim()
      fileLoaded.value = true
      if (!text.value) {
        message.value = { type: 'error', text: 'No se encontró texto legible en el PDF.' }
      } else {
        message.value = { type: 'success', text: 'Texto extraído correctamente. Pulsa Generar resumen.' }
      }
    } catch (error) {
      message.value = { type: 'error', text: 'Error al procesar el PDF: ' + error.message }
    } finally {
      loading.value = false
    }
  }

  reader.readAsArrayBuffer(file)
}

const handleFile = async (event) => {
  const file = event.target.files ? event.target.files[0] : null
  if (!file) return
  await processPdfFile(file)
}

const handleDrop = async (event) => {
  const file = event.dataTransfer?.files?.[0]
  if (!file) return
  await processPdfFile(file)
}

const openFileDialog = () => {
  fileInput.value?.click()
}

const summarizeText = () => {
  if (!text.value.trim()) {
    openFileDialog()
    return
  }

  const sentences = text.value
    .split(/[.!?]+/)
    .map(sentence => sentence.trim())
    .filter(sentence => sentence.length > 0)

  const words = text.value
    .toLowerCase()
    .split(/\W+/)
    .filter(word => word.length > 0 && !stopWords.has(word))

  const wordFreq = {}
  words.forEach(word => {
    wordFreq[word] = (wordFreq[word] || 0) + 1
  })

  const sentenceScores = sentences.map((sentence, index) => {
    const sentenceWords = sentence
      .toLowerCase()
      .split(/\W+/)
      .filter(word => word.length > 0 && !stopWords.has(word))

    let score = 0
    sentenceWords.forEach(word => {
      score += wordFreq[word] || 0
    })

    return { sentence, score, index }
  })

  sentenceScores.sort((a, b) => b.score - a.score)
  const topSentences = sentenceScores.slice(0, numSentences.value)
  topSentences.sort((a, b) => a.index - b.index)

  summary.value = topSentences.map(item => item.sentence).join('. ') + '.'
  message.value = { type: 'success', text: `Resumen generado con ${topSentences.length} frase(s).` }
}

const downloadSummary = () => {
  if (!summary.value) return
  const blob = new Blob([summary.value], { type: 'text/plain' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'resumen.txt'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

const reset = () => {
  text.value = ''
  summary.value = ''
  fileLoaded.value = false
  numSentences.value = 5
  message.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
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
  gap: 20px;
}

.text-section {
  margin-bottom: 20px;
}

.text-section h2 {
  color: #333;
  margin-bottom: 10px;
}

.text-area {
  width: 100%;
  height: 250px;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-family: 'Courier New', monospace;
  resize: vertical;
}

.controls {
  display: flex;
  gap: 20px;
  flex-wrap: wrap;
  align-items: flex-end;
  padding: 20px;
  background: #f5f7fa;
  border-radius: 5px;
}

.control-group {
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.control-group label {
  font-weight: bold;
  color: #333;
}

.control-group input {
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 5px;
  width: 100px;
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
  background: #28a745;
  color: white;
}

.btn-secondary:hover {
  background: #218838;
}

.summary-section {
  margin-top: 30px;
  padding: 20px;
  background: #f9f9f9;
  border-radius: 5px;
  border-left: 4px solid #667eea;
}

.summary-section h2 {
  color: #333;
  margin-bottom: 15px;
}

.summary-text {
  line-height: 1.8;
  color: #444;
  white-space: pre-wrap;
  word-wrap: break-word;
  margin-bottom: 20px;
}

.summary-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.message {
  padding: 16px;
  border-radius: 8px;
  margin-top: 20px;
  text-align: center;
}

.message.success {
  background: #e6ffed;
  color: #1f7a40;
  border: 1px solid #a4e6b1;
}

.message.error {
  background: #ffe6e6;
  color: #a12f29;
  border: 1px solid #f1a1a1;
}

.loading-message {
  text-align: center;
  color: #667eea;
  font-weight: bold;
  padding: 20px;
}

@media (max-width: 768px) {
  .tool-header h1 {
    font-size: 1.8rem;
  }

  .controls {
    flex-direction: column;
  }

  .btn-primary, .btn-secondary {
    width: 100%;
  }

  .summary-actions {
    flex-direction: column;
  }
}
</style>
