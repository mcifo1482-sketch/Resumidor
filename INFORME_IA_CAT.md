## 1. Descripció del projecte
Aquest projecte és una aplicació web que reuneix una col·lecció d’eines per treballar amb fitxers PDF de manera senzilla i ràpida. L’usuari pot fer operacions com unir documents, dividir-los, comprimir, rotar pàgines, afegir numeració, afegir marques d’aigua, convertir imatges i resumir textos dins del navegador.

L’objectiu és facilitar el treball amb PDF sense dependre de serveis externs: tot el processament es fa localment i l’aplicació està pensada per ser intuïtiva i accessible.

## 2. URL del repositori
https://github.com/mcifo1482-sketch/Resumidor.git

## 3. Ús de la IA
Durant el desenvolupament s’ha utilitzat la IA com a assistent per:
- Revisar i analitzar el codi del projecte.
- Proposar solucions a problemes de funcionalitat i millorar la qualitat del flux.
- Escriure o refinar documentació i instruccions per a l’usuari.

L’IA s’ha utilitzat fora del projecte, com una ajuda per fer revisions i suggeriments, no com una dependència del codi final.

## 4. Fluxos de treball
El procés de treball ha estat iteratiu i pragmàtic:
- Es van identificar les eines i funcionalitats de la plataforma.
- Es va dissenyar cada component com una eina independent dins de `src/components/tools/`.
- Cada canvi es va provar localment amb `npm run dev` i es va validar amb compilacions de producció (`npm run build`).
- Es va actualitzar la documentació per mantenir-la coherent amb les funcionalitats que hi ha disponibles.

Això permet tenir un desenvolupament flexible: una eina es pot millorar sense afectar la resta del projecte i la persona que fa servir l’aplicació veu una experiència consistent.

## 5. Explicació del codi
L’estructura principal del projecte és la següent:
- `src/main.js`: punt d’entrada que crea l’aplicació Vue.
- `src/App.vue`: component principal que mostra la interfície general.
- `src/components/PdfHome.vue`: pantalla de selecció d’eines amb accés a cada funció.
- `src/components/tools/`: carpeta amb components individuals per a cada operació sobre PDF.
- `src/utils/pdfWorker.js`: configuració per carregar el worker de `pdfjs-dist` i renderitzar PDFs.

Cada eina té una lògica pròpia en el seu component, però comparteixen un patró comú:
- carregar l’arxiu PDF o imatge
- processar-lo amb una biblioteca com `pdf-lib` o `pdfjs-dist`
- generar el resultat i oferir-lo per descàrrega

Això facilita la mantenibilitat, ja que cada funcionalitat està aïllada però segueix una mateixa forma de treballar.

## 6. Tecnologies utilitzades
- Vue.js 3
- Vite
- pdf-lib
- pdfjs-dist
- JavaScript modern (ES modules)
- CSS
- npm

Aquestes tecnologies permeten una aplicació lleugera, fàcil de desenvolupar i amb un comportament fluït al navegador.

## 7. Reptes i aprenentatges
Durant el desenvolupament s’han identificat alguns reptes comuns:
- Gestionar correctament diferents tipus de PDFs i les operacions sobre pàgines.
- Fer que les eines funcionin de manera coherent sense necessitat de servidor.
- Mantenir una experiència d’usuari clara amb missatges útils.

S’han resolt aquests reptes amb proves locals constants, validació de resultats i adaptació de la lògica per manejar casos reals de documents.

## 8. Limitacions i millores futures
En aquesta versió hi ha alguns límits naturals:
- No hi ha proves automatitzades completes per a totes les eines.
- L’aplicació fa servir processament al client, de manera que PDFs molt grans poden comportar-se més lentament.
- No hi ha una previsualització completa de cada document abans de descarregar-lo.

Millores futures podrien ser:
- afegir tests automàtics
- millor suport per a documents grans
- una previsualització real de cada pàgina
- millorar la usabilitat i els missatges d’ajuda

## 9. Reflexió sobre l'ús de la IA
La IA ha estat útil com a suport de desenvolupament, especialment per:
- suggerir idees i solucions tècniques
- revisar el mateix projecte des d’una perspectiva externa
- estructurar documentació i resums

Tot i això, l’ús de la IA també demana prudència: cal comprovar les propostes manualment, adaptar-les al projecte i no donar per fet que una solució funciona sense proves.

## 10. Instruccions d'instal·lació i ús
1. Clonar el repositori:
```bash
git clone https://github.com/mcifo1482-sketch/Resumidor.git
cd Resumidor
```
2. Instalar dependències:
```bash
npm install
```
3. Executar l'aplicació en mode desenvolupament:
```bash
npm run dev
```
4. Obrir el navegador a:
```bash
http://localhost:5173
```
5. Per a producció:
```bash
npm run build
```

No calen variables d’entorn específiques per executar l’aplicació en local.
