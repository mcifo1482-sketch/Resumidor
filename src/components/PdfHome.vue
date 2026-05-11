<template>
  <div class="home">
    <header class="hero">
      <h1>Herramientas PDF Gratis</h1>
      <p>La solución completa para trabajar con documentos PDF sin límites</p>
    </header>

    <main class="main-content">
      <section class="tools-section">
        <div class="tools-grid">
          <div
            v-for="tool in tools"
            :key="tool.id"
            class="tool-card"
            @click="$emit('onSelectTool', tool.id)"
          >
            <div class="tool-icon">{{ tool.icon }}</div>
            <h3>{{ tool.name }}</h3>
            <p>{{ tool.description }}</p>
          </div>
        </div>
      </section>

      <section class="features">
        <h2>¿Por qué elegirnos?</h2>
        <div class="features-grid">
          <div class="feature">
            <div class="feature-icon">🔒</div>
            <h3>Seguro</h3>
            <p>Tus archivos se procesan de forma segura y se eliminan automáticamente</p>
          </div>
          <div class="feature">
            <div class="feature-icon">⚡</div>
            <h3>Rápido</h3>
            <p>Procesa tus archivos en cuestión de segundos</p>
          </div>
          <div class="feature">
            <div class="feature-icon">💯</div>
            <h3>Calidad</h3>
            <p>Mantiene la máxima calidad de tus documentos</p>
          </div>
          <div class="feature">
            <div class="feature-icon">📱</div>
            <h3>Sin instalación</h3>
            <p>Funciona en cualquier navegador, sin necesidad de instalar nada</p>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<script setup>
const tools = [
  {
    id: 'summarize',
    name: 'Resumir PDF',
    description: 'Genera resúmenes inteligentes de tus documentos PDF',
    icon: '📝'
  },
  {
    id: 'merge',
    name: 'Unir PDF',
    description: 'Combina múltiples PDFs en un solo documento',
    icon: '🔗'
  },
  {
    id: 'split',
    name: 'Dividir PDF',
    description: 'Extrae páginas específicas de un PDF',
    icon: '✂️'
  },
  {
    id: 'compress',
    name: 'Comprimir PDF',
    description: 'Reduce el tamaño de tus archivos PDF',
    icon: '📦'
  },
  {
    id: 'rotate',
    name: 'Rotar PDF',
    description: 'Cambia la orientación de tus páginas',
    icon: '🔄'
  },
  {
    id: 'toimage',
    name: 'PDF a Imagen',
    description: 'Convierte páginas de PDF a imágenes JPG',
    icon: '🖼️'
  }
]
</script>

<style scoped>
.home {
  min-height: 100vh;
  background: #f5f7fa;
}

.hero {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 80px 20px;
  text-align: center;
}

.hero h1 {
  font-size: 3rem;
  margin-bottom: 20px;
  font-weight: bold;
}

.hero p {
  font-size: 1.3rem;
  opacity: 0.95;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px 20px;
}

.tools-section h2 {
  text-align: center;
  font-size: 2rem;
  margin-bottom: 40px;
  color: #333;
}

.tools-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  margin-bottom: 60px;
}

.tool-card {
  background: white;
  border-radius: 10px;
  padding: 30px;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.tool-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3);
}

.tool-icon {
  font-size: 3rem;
  margin-bottom: 15px;
}

.tool-card h3 {
  font-size: 1.3rem;
  margin-bottom: 10px;
  color: #333;
}

.tool-card p {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.5;
}

.features {
  margin-top: 60px;
}

.features h2 {
  text-align: center;
  font-size: 2rem;
  margin-bottom: 40px;
  color: #333;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.feature {
  background: white;
  border-radius: 10px;
  padding: 30px;
  text-align: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
}

.feature-icon {
  font-size: 2.5rem;
  margin-bottom: 15px;
}

.feature h3 {
  font-size: 1.1rem;
  margin-bottom: 10px;
  color: #333;
}

.feature p {
  color: #666;
  font-size: 0.9rem;
  line-height: 1.5;
}

@media (max-width: 768px) {
  .hero h1 {
    font-size: 2rem;
  }

  .hero p {
    font-size: 1.1rem;
  }

  .tools-grid {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  }

  .main-content {
    padding: 20px 10px;
  }
}
</style>
