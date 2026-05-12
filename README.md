# PDF Tools - Plataforma Completa de Herramientas PDF

Una plataforma web completa similar a iLovePDF con 12 herramientas poderosas para manipular documentos PDF. Construida con Vue.js 3 y Vite.

## 🚀 Características

### Herramientas Disponibles
- **📝 Resumir PDF**: Genera resúmenes inteligentes de documentos PDF
- **🔗 Unir PDF**: Combina múltiples PDFs en un solo documento
- **✂️ Dividir PDF**: Separa PDFs por páginas o rangos
- **🗜️ Comprimir PDF**: Reduce el tamaño de archivos PDF
- **🔄 Rotar PDF**: Gira páginas PDF en cualquier ángulo
- **🖼️ PDF a Imagen**: Convierte páginas PDF a imágenes JPG
- **✏️ Editar PDF**: Añade texto, rectángulos y resaltados
- **🔒 Proteger PDF**: Aplica protección con contraseña
- **💧 Marca de Agua**: Añade marcas de agua diagonales
- **✂️ Recortar PDF**: Ajusta márgenes de las páginas
- **🖼️ Imagen a PDF**: Convierte imágenes a documentos PDF
- **🔢 Numerar Páginas**: Añade números de página automáticos

## 🛠️ Tecnologías Utilizadas

- **Vue.js 3**: Framework progresivo para interfaces de usuario
- **Vite**: Herramienta de construcción rápida y moderna
- **PDF-lib**: Librería para manipulación de PDFs
- **PDF.js**: Motor de renderizado de PDFs en el navegador
- **CSS Grid & Flexbox**: Diseño responsivo y moderno

## 📋 Requisitos Previos

- Node.js (versión 16 o superior)
- npm o yarn

## 🚀 Cómo Levantar la Página

### 1. Instalar Dependencias

```bash
npm install
```

### 2. Ejecutar el Servidor de Desarrollo

```bash
npm run dev
```

### 3. Abrir en el Navegador

Una vez ejecutado el comando anterior, abre tu navegador y ve a:
```
http://localhost:5173
```

Si el puerto 5173 está ocupado, Vite automáticamente usará el siguiente puerto disponible (generalmente 5174).

### 4. Construir para Producción

```bash
npm run build
```

Los archivos compilados estarán en la carpeta `dist/`.

## 📖 Cómo Usar

1. **Accede a la plataforma**: Abre `http://localhost:5173` en tu navegador
2. **Selecciona una herramienta**: Haz clic en cualquiera de las 12 herramientas disponibles
3. **Sube tu archivo**: Arrastra y suelta o haz clic en el área punteada para seleccionar archivos
4. **Configura opciones**: Ajusta los parámetros según la herramienta seleccionada
5. **Procesa**: Haz clic en el botón principal para procesar tu archivo
6. **Descarga**: El archivo procesado se descargará automáticamente

## 🎯 Funcionalidades Especiales

- **Interfaz responsiva**: Funciona perfectamente en desktop y móvil
- **Procesamiento en el navegador**: No se envían archivos a servidores externos
- **Feedback visual**: Indicadores de carga y mensajes de estado
- **Manejo de errores**: Validación de archivos y manejo de errores graceful
- **Descargas automáticas**: Los archivos procesados se descargan inmediatamente

## 📁 Estructura del Proyecto

```
src/
├── components/
│   ├── tools/          # Componentes de herramientas PDF (12 archivos)
│   ├── App.vue         # Componente principal
│   ├── PdfHome.vue     # Página de inicio con grid de herramientas
│   └── ...
├── main.js             # Punto de entrada de la aplicación
└── style.css           # Estilos globales
```

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 🙋‍♂️ Soporte

Si encuentras algún problema o tienes sugerencias, por favor abre un issue en este repositorio.

---

¡Disfruta manipulando tus PDFs con esta poderosa plataforma! 🎉
