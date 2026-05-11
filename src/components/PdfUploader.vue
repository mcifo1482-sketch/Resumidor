<template>
  <div class="app">
    <header class="header">
      <h1>Resumidor de PDFs</h1>
      <p>Sube un PDF, extrae el texto y genera un resumen inteligente.</p>
    </header>

    <main class="main">
      <div class="upload-section">
        <label for="file-input" class="file-label">
          <span>Seleccionar archivo PDF</span>
          <input id="file-input" type="file" @change="handleFile" accept=".pdf" />
        </label>
        <p v-if="loading" class="loading">Procesando PDF...</p>
      </div>

      <div v-if="text" class="text-section">
        <h2>Texto extraído</h2>
        <textarea v-model="text" readonly class="text-area"></textarea>
      </div>

      <div v-if="text" class="summary-controls">
        <label for="num-sentences">Número de frases en el resumen:</label>
        <input id="num-sentences" type="number" v-model.number="numSentences" min="1" max="10" class="num-input" />
        <button @click="summarizeText" :disabled="loading" class="btn-primary">Generar resumen</button>
      </div>

      <div v-if="summary" class="summary-section">
        <h2>Resumen</h2>
        <p class="summary-text">{{ summary }}</p>
        <button @click="downloadSummary" class="btn-secondary">Descargar resumen</button>
      </div>
    </main>
  </div>
</template>

<script setup>
import * as pdfjsLib from 'pdfjs-dist'
import { ref } from 'vue'

const text = ref('')
const summary = ref('')
const loading = ref(false)
const numSentences = ref(5)

pdfjsLib.GlobalWorkerOptions.workerSrc =
  'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.0.379/pdf.worker.min.js'

const handleFile = async (event) => {
  const file = event.target.files[0]

  if (!file) return

  loading.value = true
  text.value = ''
  summary.value = ''

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

      text.value = fullText
    } catch (error) {
      alert('Error al procesar el PDF: ' + error.message)
    } finally {
      loading.value = false
    }
  }

  reader.readAsArrayBuffer(file)
}

const summarizeText = () => {
  if (!text.value) return

  const sentences = text.value.split(/[.!?]+/).filter(s => s.trim().length > 0)
  const words = text.value.toLowerCase().split(/\W+/).filter(w => w.length > 0)

  // Calculate word frequencies
  const wordFreq = {}
  words.forEach(word => {
    wordFreq[word] = (wordFreq[word] || 0) + 1
  })

  // Score sentences
  const sentenceScores = sentences.map(sentence => {
    const sentenceWords = sentence.toLowerCase().split(/\W+/).filter(w => w.length > 0)
    let score = 0
    sentenceWords.forEach(word => {
      score += wordFreq[word] || 0
    })
    return { sentence: sentence.trim(), score }
  })

  // Sort by score descending
  sentenceScores.sort((a, b) => b.score - a.score)

  // Take top sentences
  const topSentences = sentenceScores.slice(0, numSentences.value).map(s => s.sentence)

  summary.value = topSentences.join('. ') + '.'
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
</script>

<style scoped>
.app {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  color: #333;
}

.header {
  text-align: center;
  padding: 40px 20px;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  color: white;
}

.header h1 {
  margin: 0;
  font-size: 2.5rem;
  font-weight: bold;
}

.header p {
  margin: 10px 0 0;
  font-size: 1.2rem;
  opacity: 0.9;
}

.main {
  max-width: 900px;
  margin: 0 auto;
  padding: 20px;
}

.upload-section {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
  text-align: center;
}

.file-label {
  display: inline-block;
  padding: 15px 30px;
  background: #667eea;
  color: white;
  border-radius: 5px;
  cursor: pointer;
  transition: background 0.3s;
  font-size: 1rem;
}

.file-label:hover {
  background: #5a6fd8;
}

.file-label input {
  display: none;
}

.loading {
  margin-top: 20px;
  color: #667eea;
  font-weight: bold;
}

.text-section, .summary-section {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

.text-section h2, .summary-section h2 {
  margin-top: 0;
  color: #333;
}

.text-area {
  width: 100%;
  height: 300px;
  padding: 15px;
  border: 1px solid #ddd;
  border-radius: 5px;
  font-family: inherit;
  resize: vertical;
}

.summary-controls {
  background: white;
  border-radius: 10px;
  padding: 30px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 15px;
}

.summary-controls label {
  font-weight: bold;
}

.num-input {
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 5px;
  width: 80px;
}

.btn-primary, .btn-secondary {
  padding: 12px 24px;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 1rem;
  transition: background 0.3s;
}

.btn-primary {
  background: #667eea;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #5a6fd8;
}

.btn-primary:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.btn-secondary {
  background: #28a745;
  color: white;
}

.btn-secondary:hover {
  background: #218838;
}

.summary-text {
  line-height: 1.6;
  white-space: pre-wrap;
}

@media (max-width: 768px) {
  .header h1 {
    font-size: 2rem;
  }

  .main {
    padding: 10px;
  }

  .upload-section, .text-section, .summary-section, .summary-controls {
    padding: 20px;
  }

  .summary-controls {
    flex-direction: column;
    align-items: stretch;
  }

  .num-input {
    width: 100%;
  }
}
</style>