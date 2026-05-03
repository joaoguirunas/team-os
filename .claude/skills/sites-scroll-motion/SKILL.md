---
name: sites-scroll-motion
description: Scroll cinematográfico, parallax, animações avançadas e cenas 3D para websites — do CSS puro ao Three.js WebGPU. Extraído de duas fontes de produção reais.
---

# Sites Scroll Motion

Dois sistemas de referência que informam esta skill:
- **Fonte A:** `/agentes` page (Next.js + React Three Fiber + Framer Motion)
- **Fonte B:** Verdana Digital Oasis (HTML vanilla + Three.js WebGPU + TSL + GPU Compute)

---

## Seção 1 — Árvore de Decisão

**Leia isto primeiro.** Determine a técnica antes de escrever uma linha de código.

```
Objetivo de movimento
    │
    ├── Revelar elemento ao entrar na viewport
    │     ├── Simples → IntersectionObserver + CSS classes (zero deps)  [→ Seção 2]
    │     └── Física/spring → Framer Motion whileInView
    │
    ├── Transformar valor com scroll (opacity, x, y, scale)
    │     ├── 1 elemento → Framer Motion useScroll + useTransform       [→ Seção 5]
    │     └── Múltiplos com timeline → useScroll + useTransform multi-keyframe
    │
    ├── Parallax de fundo
    │     ├── Suave sem interação → CSS background-attachment: fixed
    │     └── Com mouse → dual-ref pattern (targetRef + smoothedRef via rAF) [→ Seção 4]
    │
    ├── Seção com efeito sticky + scroll-driven
    │     └── min-h-[150vh] + sticky child + Framer Motion useScroll    [→ Seção 5]
    │
    ├── CSS nativo de scroll snapping
    │     └── scroll-snap-type y proximity + scroll-snap-align start    [→ Seção 3]
    │
    ├── Câmera 3D com scroll (cena decorativa)
    │     ├── React project → React Three Fiber + CameraRig keyframe pattern [→ Seção 6]
    │     └── Vanilla HTML → Three.js WebGL + importmap + lerpCam()
    │
    ├── Cena 3D com objetos interativos (mouse, física)
    │     ├── Simples (planetas, starfield) → Three.js WebGL + useFrame [→ Seção 8]
    │     └── Complexo (>10k instâncias, simulação) → Three.js WebGPU + TSL + GPU Compute [→ Seção 9]
    │
    └── Post-processing (bokeh, glow, bloom)
          ├── React → @react-three/postprocessing (Bloom, DepthOfField)
          └── Vanilla → Three.js PostProcessing + TSL dof node          [→ Seção 9]
```

---

## Seção 2 — IntersectionObserver + CSS Reveal (Zero deps)

**Quando usar:** reveal simples de elementos ao entrar na viewport. Não requer Framer Motion (~40kb).

```js
const revealObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const el = entry.target;
      const delay = el.dataset.delay || '0';
      el.classList.add('revealed', `delay-${delay}`);
      revealObserver.unobserve(el); // não re-dispara
    }
  });
}, {
  threshold: 0.1,
  rootMargin: '0px 0px -18% 0px' // dispara antes de atingir a viewport
});

document.querySelectorAll('[data-reveal]').forEach(el => revealObserver.observe(el));
```

```css
[data-reveal] {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.7s ease, transform 0.7s ease;
}

[data-reveal].revealed {
  opacity: 1;
  transform: translateY(0);
}

.delay-1 { transition-delay: 0.1s; }
.delay-2 { transition-delay: 0.25s; }
.delay-3 { transition-delay: 0.4s; }
```

```html
<h1 data-reveal data-delay="1">Título</h1>
<p data-reveal data-delay="2">Subtítulo</p>
```

**vs Framer Motion:** use Framer quando precisar de física/spring, stagger dinâmico, ou já tiver Framer no projeto.

---

## Seção 3 — CSS Scroll Snap Nativo

```css
html {
  scroll-snap-type: y proximity; /* proximity: só snapa se perto do ponto */
}

.section {
  scroll-snap-align: start;
  min-height: 100vh;
}
```

- `mandatory` — força snap sempre (experiência mais abrupta, boa para onboarding)
- `proximity` — só snapa se o usuário parar perto do snap point (mais natural)

**Combinação com scroll-driven:** usar scroll snap não impede Framer Motion `useScroll`. As seções continuam emitindo `scrollYProgress` normalmente.

**Progress bar de scroll (bônus):**
```js
// Vanilla: atualizar width a cada frame
progressBar.style.width = `${(scrollY / (document.body.scrollHeight - innerHeight)) * 100}%`;
```

---

## Seção 4 — Dual-ref Scroll (Sem re-render)

**Regra:** nunca usar `useState` para posição de scroll em animações de alta frequência. Refs não causam re-render.

### React — `useScrollProgress` hook

```ts
// hooks/use-scroll-progress.ts
export function useScrollProgress() {
  const progressRef = useRef(0);  // valor suavizado (atual)
  const targetRef = useRef(0);    // valor bruto (alvo)

  useEffect(() => {
    const onScroll = () => {
      const el = document.documentElement;
      targetRef.current = el.scrollTop / (el.scrollHeight - el.clientHeight);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useFrame((_, delta) => {
    // Suaviza o scroll (lerp frame-rate independent)
    progressRef.current += (targetRef.current - progressRef.current) * Math.min(1, delta * 5);
  });

  return progressRef;
}
```

### Vanilla — `_scrollDirty` pattern

```js
let currentScrollT = 0, targetScrollT = 0;
let _scrollDirty = false;

window.addEventListener('scroll', () => { _scrollDirty = true; }, { passive: true });

function animate(dt) {
  // Lê scroll uma vez por frame, não no evento (evita layout thrashing)
  if (_scrollDirty) {
    targetScrollT = window.scrollY / (document.body.scrollHeight - window.innerHeight);
    _scrollDirty = false;
  }
  currentScrollT += (targetScrollT - currentScrollT) * Math.min(1, dt * 6);
}
```

**Por que `_scrollDirty`:** `getBoundingClientRect()` e `scrollY` causam layout thrashing se chamados dentro do loop `requestAnimationFrame`. Marcar dirty no evento e ler uma vez por frame é seguro.

### Mouse parallax dual-ref (React)

```tsx
const targetRef = useRef({ x: 0, y: 0 });
const smoothedRef = useRef({ x: 0, y: 0 });

useEffect(() => {
  const onMove = (e: MouseEvent) => {
    targetRef.current = {
      x: (e.clientX / window.innerWidth - 0.5) * 2,
      y: (e.clientY / window.innerHeight - 0.5) * 2,
    };
  };
  window.addEventListener('mousemove', onMove, { passive: true });
  return () => window.removeEventListener('mousemove', onMove);
}, []);

useFrame((_, delta) => {
  smoothedRef.current.x += (targetRef.current.x - smoothedRef.current.x) * Math.min(1, delta * 3);
  smoothedRef.current.y += (targetRef.current.y - smoothedRef.current.y) * Math.min(1, delta * 3);
  // Aplicar em mesh.position, material.uniforms, etc.
});
```

---

## Seção 5 — Framer Motion Scroll Avançado

### useScroll básico (elemento)

```tsx
const ref = useRef(null);
const { scrollYProgress } = useScroll({
  target: ref,
  offset: ['start end', 'end start'], // [quando o topo do elemento toca o fim da viewport, ...]
});
const opacity = useTransform(scrollYProgress, [0, 0.3, 0.7, 1], [0, 1, 1, 0]);
```

### useTransform com multi-keyframe

```tsx
// Input e output podem ter N breakpoints (não apenas 2)
const x = useTransform(
  scrollYProgress,
  [0,   0.2,  0.5,  0.8,  1],   // pontos de entrada
  [100, 0,    -20,  0,    -100]  // valores correspondentes
);
```

### Padrão sticky + scroll-driven

```tsx
// Container alto cria espaço de scroll; filho sticky permanece na tela
<div ref={ref} className="relative min-h-[150vh]">
  <div className="sticky top-[20vh] h-[60vh]">
    <motion.div style={{ opacity, scale, y }}>
      {/* conteúdo que anima enquanto o usuário scrolla */}
    </motion.div>
  </div>
</div>
```

### Coordenar múltiplos elementos (stagger via offset)

```tsx
// Header entra antes, cards entram depois — usar offsets diferentes
const { scrollYProgress: headerProgress } = useScroll({ target: ref, offset: ['start 0.8', 'start 0.4'] });
const { scrollYProgress: cardsProgress }  = useScroll({ target: ref, offset: ['start 0.6', 'start 0.1'] });

const headerY  = useTransform(headerProgress, [0, 1], [40, 0]);
const cardsY   = useTransform(cardsProgress,  [0, 1], [60, 0]);
```

### Spring vs easing

```tsx
// Spring (físico, natural para UI interativa)
<motion.div whileHover={{ scale: 1.05 }} transition={{ type: 'spring', stiffness: 300, damping: 20 }} />

// Easing (determinístico, previsível para scroll-driven)
<motion.div style={{ opacity }} /> // useTransform já usa linear por padrão
```

---

## Seção 6 — Keyframe Camera Path

Padrão para animar câmera 3D (ou qualquer valor) em sincronia com scroll, usando um array de keyframes.

### Formato do array

```ts
// [scrollT, posX, posY, posZ, lookX, lookY, lookZ]
const CAMERA_PATH: [number, ...number[]][] = [
  [0.00,   0,  2,  8,    0, 0, 0],  // início
  [0.25,   3,  3,  6,    0, 1, 0],  // seção 2
  [0.50,  -2,  4,  4,    0, 2, 0],  // seção 3
  [0.75,   0,  5,  2,    0, 3, 0],  // seção 4
  [1.00,   0,  6,  0,    0, 4, 0],  // final
];
```

### `lerpCam()` reutilizável

```ts
function smoothstep(t: number) { return t * t * (3 - 2 * t); }

function lerpCam(scrollT: number) {
  // Snap ao primeiro ou último keyframe
  if (scrollT <= CAMERA_PATH[0][0]) return CAMERA_PATH[0];
  if (scrollT >= CAMERA_PATH[CAMERA_PATH.length - 1][0]) return CAMERA_PATH[CAMERA_PATH.length - 1];

  // Encontrar segmento [A, B] que contém scrollT
  let i = 0;
  for (let j = 1; j < CAMERA_PATH.length; j++) {
    if (CAMERA_PATH[j][0] >= scrollT) { i = j - 1; break; }
  }
  const a = CAMERA_PATH[i], b = CAMERA_PATH[i + 1];

  // localT dentro do segmento, suavizado com smoothstep
  const raw = (scrollT - a[0]) / (b[0] - a[0]);
  const ease = smoothstep(raw);

  // Lerp de todos os valores
  return a.map((v, idx) => idx === 0 ? scrollT : v + (b[idx] - v) * ease);
}
```

### Aplicar no useFrame (React Three Fiber)

```tsx
useFrame((state, delta) => {
  progressRef.current += (targetRef.current - progressRef.current) * Math.min(1, delta * 5);
  const [, px, py, pz, lx, ly, lz] = lerpCam(progressRef.current);

  state.camera.position.lerp(new THREE.Vector3(px, py, pz), 0.08);
  state.camera.lookAt(lx, ly, lz);
});
```

### `smoothstep` vs `linear`

- `smoothstep` — ease-in-out cúbico: mais natural para câmera e parallax
- `linear` — útil quando sincronizando com barras de progresso ou valores que o usuário deve controlar precisamente

### Sincronizar keyframes com DOM real

```ts
function syncCameraPathToDOM() {
  // Mapear scrollT ao offset real das sections no DOM
  const sections = document.querySelectorAll('.camera-section');
  const total = document.body.scrollHeight - window.innerHeight;
  sections.forEach((el, i) => {
    const rect = el.getBoundingClientRect();
    CAMERA_PATH[i][0] = (window.scrollY + rect.top) / total;
  });
}
window.addEventListener('resize', syncCameraPathToDOM);
syncCameraPathToDOM();
```

---

## Seção 7 — Per-Stage Parameter Interpolation

**O padrão mais sofisticado desta skill.** Não apenas a câmera muda entre seções — TODOS os parâmetros da cena (fog, cores, vento, densidade) fazem lerp suave entre stages.

### Estrutura

```js
const stageParams = CAMERA_PATH.map((_, i) => ({
  // Atmosfera
  fogNear:       [6.5, 8.0, 7.0, 9.0, 10.0][i],
  fogFar:        [12.0, 15.0, 13.0, 18.0, 20.0][i],
  // Cor base (grama, objetos, etc.)
  baseColorR:    [0.055, 0.12, 0.08, 0.15, 0.05][i],
  baseColorG:    [0.118, 0.20, 0.15, 0.25, 0.10][i],
  baseColorB:    [0.016, 0.04, 0.02, 0.06, 0.01][i],
  // Outros efeitos
  windSpeed:     [1.3, 0.8, 1.8, 0.5, 1.0][i],
  windAmplitude: [0.21, 0.15, 0.28, 0.10, 0.18][i],
}));
```

### lerpCam com params

```js
function lerpCam(scrollT) {
  // ... (encontrar segmento i, calcular ease) ...

  const pA = stageParams[i], pB = stageParams[i + 1];
  const params = {};
  Object.keys(pA).forEach(k => {
    params[k] = pA[k] + (pB[k] - pA[k]) * ease;
  });

  return { position: [...], lookAt: [...], params };
}
```

### Aplicar uniforms GPU todo frame

```js
function animate() {
  const cam = lerpCam(currentScrollT);

  // Câmera
  camera.position.set(cam.position[0], cam.position[1], cam.position[2]);

  // Uniforms da GPU recebem os valores interpolados
  fogNearU.value       = cam.params.fogNear;
  fogFarU.value        = cam.params.fogFar;
  windSpeedU.value     = cam.params.windSpeed;
  windAmplitudeU.value = cam.params.windAmplitude;
  baseColor.value.setRGB(cam.params.baseColorR, cam.params.baseColorG, cam.params.baseColorB);
}
```

**Resultado visual:** a paleta de cores transita imperceptivelmente durante o scroll — não em jump na troca de seção, mas suavemente ao longo de toda a rolagem.

**Versão React Three Fiber:**

```tsx
const fogNearRef = useRef(6.5);
useFrame(() => {
  const cam = lerpCam(progressRef.current);
  fogNearRef.current = cam.params.fogNear;
  if (materialRef.current) {
    materialRef.current.uniforms.fogNear.value = fogNearRef.current;
  }
});
```

---

## Seção 8 — Three.js / React Three Fiber — Cenas 3D

### Setup mínimo — Canvas fixo atrás do conteúdo

```tsx
// SolarSystemBackground.tsx
import dynamic from 'next/dynamic';

// SSR-safe: Three.js acessa window no import
const Scene = dynamic(() => import('./Scene'), { ssr: false });

export function SolarSystemBackground() {
  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 0,
      pointerEvents: 'none', // scroll passa para o DOM
    }}>
      <Scene />
    </div>
  );
}
```

```tsx
// Scene.tsx
import { Canvas } from '@react-three/fiber';

export default function Scene() {
  return (
    <Canvas
      camera={{ position: [0, 2, 8], fov: 60 }}
      dpr={[1, 2]} // cap em 2x — nunca deixar ilimitado
      gl={{ powerPreference: 'high-performance' }}
    >
      <fog attach="fog" args={['#02020a', 70, 320]} />
      <CameraRig />
      <Starfield />
      <Planet position={[2, 0, -3]} />
    </Canvas>
  );
}
```

### Objeto com rotação e drift (useFrame)

```tsx
function Planet({ position }: { position: [number, number, number] }) {
  const meshRef = useRef<THREE.Mesh>(null);

  useFrame((_, delta) => {
    if (!meshRef.current) return;
    meshRef.current.rotation.y += delta * 0.1;
  });

  return (
    <mesh ref={meshRef} position={position}>
      <sphereGeometry args={[1, 64, 64]} />
      <meshStandardMaterial map={texture} />
    </mesh>
  );
}
```

### Mouse → mundo 3D via Raycasting

```tsx
// Converter posição 2D do mouse para posição 3D no plano y=0
const raycaster = new THREE.Raycaster();
const mouseNDC = new THREE.Vector2();
const groundPlane = new THREE.Plane(new THREE.Vector3(0, 1, 0), 0);
const hitPoint = new THREE.Vector3();

window.addEventListener('mousemove', (e) => {
  mouseNDC.set(
    (e.clientX / window.innerWidth) * 2 - 1,
    -(e.clientY / window.innerHeight) * 2 + 1
  );
  raycaster.setFromCamera(mouseNDC, camera);
  raycaster.ray.intersectPlane(groundPlane, hitPoint);
  // hitPoint.x, hitPoint.z = posição no mundo
}, { passive: true });
```

### Canvas push no footer

Canvas fixo precisa recuar quando o footer aparece:

```js
const _siteFooter = document.querySelector('.site-footer'); // cache fora do loop

function animate() {
  if (_siteFooter) {
    const footerTop = _siteFooter.getBoundingClientRect().top;
    if (footerTop < window.innerHeight) {
      renderer.domElement.style.transform = `translateY(-${window.innerHeight - footerTop}px)`;
    } else {
      renderer.domElement.style.transform = '';
    }
  }
}
```

### Atmosfera aditiva (planeta)

```tsx
// Esfera maior, atrás, com blending aditivo = halo luminoso
<mesh>
  <sphereGeometry args={[1.05, 32, 32]} />
  <meshStandardMaterial
    color="#4488ff"
    transparent opacity={0.15}
    side={THREE.BackSide}
    blending={THREE.AdditiveBlending}
    depthWrite={false}
  />
</mesh>
```

---

## Seção 9 — Three.js WebGPU + TSL (Avançado)

> **Quando usar:** compute shaders (simulação na GPU), >10k instâncias com física, materiais sem GLSL.
> Para todos os outros casos, usar WebGL (Seção 8) — melhor compatibilidade de browser.

### Setup WebGPU Renderer

```js
import * as THREE from 'three'; // importar three/webgpu via import map
import { WebGPURenderer } from 'three/webgpu';

const renderer = new WebGPURenderer({ antialias: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.2;

// WebGPU é async
await renderer.init();
document.body.appendChild(renderer.domElement);

// Loop: setAnimationLoop em vez de requestAnimationFrame manual
renderer.setAnimationLoop(animate);
```

### TSL — Materiais sem GLSL

```js
import { Fn, vec3, mix, uv, uniform } from 'three/tsl';

const colorBase = uniform(new THREE.Color('#0e1e04'));
const colorTip  = uniform(new THREE.Color('#c8b840'));

// colorNode é o equivalente TSL de fragmentShader
material.colorNode = Fn(() => {
  return mix(colorBase, colorTip, uv().y);
})();

// Atualizar uniform a qualquer momento (CPU → GPU):
colorBase.value.set('#ff0000');
```

### GPU Compute Shaders

```js
import { Fn, instancedArray, instanceIndex, deltaTime, time, sin, mix } from 'three/tsl';

const BLADE_COUNT = 120_000;

// Buffers na GPU
const bladeData  = instancedArray(BLADE_COUNT, 'vec4'); // posição + rotY
const bendState  = instancedArray(BLADE_COUNT, 'vec4'); // bend atual

// Compute shader: roda NA GPU, uma vez por instância
const computeUpdate = Fn(() => {
  const bend    = bendState.element(instanceIndex);
  const windX   = sin(time.mul(1.3)).mul(0.21);         // vento baseado em tempo
  const lw      = deltaTime.mul(4.0).saturate();          // lerp weight frame-rate independent
  bend.x.assign(mix(bend.x, windX, lw));                  // suaviza o bend
})().compute(BLADE_COUNT);

// Executar a cada frame:
renderer.compute(computeUpdate);
```

### Depth of Field com auto-focus

```js
import { dof } from 'three/addons/tsl/display/DepthOfFieldNode.js';
import { pass, mrt, output, transformedNormalView } from 'three/tsl';

// Multi-render target
const scenePass = pass(scene, camera);
scenePass.setMRT(mrt({ output, normal: transformedNormalView }));

const sceneColor  = scenePass.getTextureNode('output');
const sceneViewZ  = scenePass.getViewZNode();

// Uniforms de DoF
const focusDistU  = uniform(5.0);
const focalLenU   = uniform(35.0);
const bokehScaleU = uniform(3.0);

const dofOutput = dof(sceneColor, sceneViewZ, focusDistU, focalLenU, bokehScaleU);

// Mobile sem DoF (performance)
const isMobile = /Mobi|Android/i.test(navigator.userAgent);
postProcessing.outputNode = isMobile ? sceneColor : dofOutput;

// Auto-focus: suavizar a distância focal todo frame
let autoFocusSmoothed = 5.0;
function updateFocus(dt, mouseFocusDist) {
  autoFocusSmoothed += (mouseFocusDist - autoFocusSmoothed) * Math.min(1, dt * 4);
  focusDistU.value  += (autoFocusSmoothed - focusDistU.value) * Math.min(1, dt * 8);
}
```

### Sky gradient via CanvasTexture

```js
function buildSkyTexture(colorZenith = '#0a0a1a', colorHorizon = '#1a0a05') {
  const canvas = document.createElement('canvas');
  canvas.width = 2; canvas.height = 512;
  const ctx = canvas.getContext('2d');
  const grad = ctx.createLinearGradient(0, 0, 0, 512);
  grad.addColorStop(0.0,  colorZenith);
  grad.addColorStop(0.65, colorHorizon);
  grad.addColorStop(1.0,  '#050505');
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, 2, 512);

  const tex = new THREE.CanvasTexture(canvas);
  tex.mapping = THREE.EquirectangularReflectionMapping;
  tex.colorSpace = THREE.SRGBColorSpace;
  return tex;
}

scene.background = buildSkyTexture();
```

### Import map (sem bundler)

Para protótipos e demos HTML sem Next.js/Vite:

```html
<script type="importmap">
{
  "imports": {
    "three":          "https://unpkg.com/three@0.183.0/build/three.webgpu.js",
    "three/webgpu":   "https://unpkg.com/three@0.183.0/build/three.webgpu.js",
    "three/tsl":      "https://unpkg.com/three@0.183.0/build/three.tsl.js",
    "three/addons/":  "https://unpkg.com/three@0.183.0/examples/jsm/"
  }
}
</script>
<script type="module">
  import * as THREE from 'three';
  import { Fn, uniform } from 'three/tsl';
  import { dof } from 'three/addons/tsl/display/DepthOfFieldNode.js';
</script>
```

---

## Seção 10 — Performance Rules (Não-negociáveis)

1. **Scroll listeners sempre `{ passive: true }`** — sem isso, o browser aguarda o callback antes de scrollar
2. **Animações de scroll = refs/rAF, nunca `useState`** — state causa re-render a cada pixel de scroll
3. **`_scrollDirty` flag** — não chamar `scrollY` ou `getBoundingClientRect()` dentro do rAF; marcar dirty no evento e ler uma vez por frame
4. **`will-change: transform` só em elementos realmente animados** — promove ao compositor, mas consome memória GPU
5. **Canvas Three.js decorativo: `pointerEvents: none`** — scroll events devem chegar ao DOM
6. **`dpr={[1, 2]}` ou `renderer.setPixelRatio(Math.min(dpr, 2))`** — nunca deixar ilimitado (telas 3x explodem)
7. **`dynamic({ ssr: false })` para qualquer import de `three` ou que acesse `window`** — hydration error em Next.js
8. **WebGPU: cap de instâncias** — ~120k OK para grama; acima disso dividir em chunks separados
9. **DoF desligado em mobile** — verifique `navigator.userAgent` e use `sceneColor` diretamente
10. **Fog é mais barato que frustum culling** para objetos distantes — `FogExp2` esconde a distância sem custo de render
11. **`renderer.setAnimationLoop()` em vez de loop `rAF` manual no WebGPU** — necessário para o pipeline async do WebGPU funcionar corretamente

---

## Receitas Copy-Paste

| Receita | Técnica | Complexidade |
|---|---|---|
| Fade-in ao entrar na viewport | IntersectionObserver + CSS | ⬤○○ |
| Scroll snap entre sections | CSS nativo | ⬤○○ |
| Progress bar de scroll | `div` width = scrollY / scrollHeight | ⬤○○ |
| Cards que deslizam com scroll | Framer Motion useScroll + useTransform | ⬤⬤○ |
| Seção sticky + scroll-driven | Framer Motion + min-h-[150vh] | ⬤⬤○ |
| Mouse parallax (CSS vars) | `--mx`, `--my` + translate | ⬤⬤○ |
| Câmera 3D com scroll | CameraRig keyframe pattern (R3F) | ⬤⬤⬤ |
| Planetas com atmosfera | Planet.tsx (Three.js R3F) | ⬤⬤⬤ |
| Starfield com mouse | Starfield.tsx (Three.js R3F) | ⬤⬤⬤ |
| Per-stage color palette | stageParams + lerpCam | ⬤⬤⬤ |
| Grama GPU com vento | WebGPU + TSL compute (vanilla) | ⬤⬤⬤ |
| Depth of Field bokeh | PostProcessing + dof node (WebGPU) | ⬤⬤⬤ |
