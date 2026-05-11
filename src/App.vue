
<script setup>
import { ref } from 'vue'
import PdfHome from './components/PdfHome.vue'
import PdfMerge from './components/tools/PdfMerge.vue'
import PdfSplit from './components/tools/PdfSplit.vue'
import PdfCompress from './components/tools/PdfCompress.vue'
import PdfToImage from './components/tools/PdfToImage.vue'
import PdfRotate from './components/tools/PdfRotate.vue'
import PdfSummarizer from './components/tools/PdfSummarizer.vue'
import PdfEdit from './components/tools/PdfEdit.vue'
import PdfProtect from './components/tools/PdfProtect.vue'
import PdfWatermark from './components/tools/PdfWatermark.vue'
import PdfCrop from './components/tools/PdfCrop.vue'
import ImageToPdf from './components/tools/ImageToPdf.vue'
import PdfPageNumbers from './components/tools/PdfPageNumbers.vue'

const currentTool = ref('home')
const tools = {
  home: PdfHome,
  merge: PdfMerge,
  split: PdfSplit,
  compress: PdfCompress,
  toimage: PdfToImage,
  rotate: PdfRotate,
  summarize: PdfSummarizer,
  edit: PdfEdit,
  protect: PdfProtect,
  watermark: PdfWatermark,
  crop: PdfCrop,
  imagetopdf: ImageToPdf,
  pagenumbers: PdfPageNumbers
}
</script>

<template>
  <div class="app">
    <nav class="navbar">
      <div class="nav-container">
        <div class="logo" @click="currentTool = 'home'">
          <span class="logo-icon">📄</span>
          <span class="logo-text">PDF Tools</span>
        </div>
        <button v-if="currentTool !== 'home'" @click="currentTool = 'home'" class="btn-back">
          ← Volver al inicio
        </button>
      </div>
    </nav>

    <component :is="tools[currentTool]" :onSelectTool="(tool) => currentTool = tool" />
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.app {
  min-height: 100vh;
  background: #f5f7fa;
}

.navbar {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 1rem 0;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
  position: sticky;
  top: 0;
  z-index: 100;
}

.nav-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 20px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  display: flex;
  align-items: center;
  gap: 10px;
  color: white;
  font-size: 1.5rem;
  font-weight: bold;
  cursor: pointer;
  transition: opacity 0.3s;
}

.logo:hover {
  opacity: 0.8;
}

.logo-icon {
  font-size: 2rem;
}

.logo-text {
  font-size: 1.3rem;
}

.btn-back {
  padding: 10px 20px;
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-back:hover {
  background: rgba(255, 255, 255, 0.3);
  border-color: rgba(255, 255, 255, 0.5);
}

@media (max-width: 768px) {
  .nav-container {
    flex-direction: column;
    gap: 10px;
  }

  .logo-text {
    font-size: 1.1rem;
  }

  .btn-back {
    width: 100%;
  }
}
</style>