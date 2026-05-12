#!/bin/bash

# Lista de componentes a modificar (excluyendo los ya hechos)
components=(
    "PdfToImage.vue"
    "PdfEdit.vue"
    "PdfProtect.vue"
    "PdfWatermark.vue"
    "PdfCrop.vue"
    "ImageToPdf.vue"
    "PdfPageNumbers.vue"
)

for component in "${components[@]}"; do
    file="src/components/tools/$component"
    echo "Procesando $component..."
    
    # Cambiar el texto del área de subida
    sed -i 's/Carga tu PDF.*$/Carga tu PDF o usa el botón de abajo/' "$file"
    sed -i 's/Añade PDFs.*$/Añade PDFs o usa el botón de abajo/' "$file"
    sed -i 's/Carga tus imágenes.*$/Carga tus imágenes o usa el botón de abajo/' "$file"
    
    # Para componentes que no tienen fileLoaded, necesitamos encontrar el patrón correcto
    # Primero, encontrar la función principal
    main_function=$(grep -o "const [a-zA-Z]* = async" "$file" | head -1 | sed 's/const \([a-zA-Z]*\) = async.*/\1/')
    
    if [ -n "$main_function" ]; then
        echo "  Función principal encontrada: $main_function"
        
        # Agregar la lógica para abrir el selector si no hay archivo
        sed -i "s/const $main_function = async () => {/const $main_function = async () => {\n  \/\/ Si no hay archivo cargado, abrir el selector\n  if (!fileData.value \&\& !pdfFile.value \&\& !files.value?.length) {\n    document.querySelector('input[type=\"file\"]').click()\n    return\n  }\n/" "$file"
    fi
    
    # Cambiar el texto del botón (esto es más complejo, lo haré manualmente después)
    echo "  Procesado $component"
done

echo "Script completado. Revisa manualmente los textos de los botones."
