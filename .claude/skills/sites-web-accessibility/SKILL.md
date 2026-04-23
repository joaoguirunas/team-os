---
name: sites-web-accessibility
description: Padrões de acessibilidade web — WCAG 2.1 AA, ARIA, navegação por teclado e testes. Injectado em EROS (sites-ux-alpha) e LUMEN (sites-ux-beta).
---

# Sites Web Accessibility — WCAG 2.1 AA

## Checklist obrigatório

### Percepção
- [ ] Contraste mínimo 4.5:1 (texto normal) e 3:1 (texto grande)
- [ ] Alt text em todas as imagens (`alt=""` para decorativas)
- [ ] Vídeos com legendas
- [ ] Não depender só de cor para transmitir info

### Operação
- [ ] Todos os elementos interactivos acessíveis por teclado
- [ ] Focus visible em todos os elementos interactivos
- [ ] Skip links para conteúdo principal
- [ ] Sem armadilhas de foco (focus traps apenas em modais)

### Compreensão
- [ ] `lang` definido no `<html>`
- [ ] Labels em todos os inputs
- [ ] Mensagens de erro descritivas
- [ ] Sem timeout inesperado

### Robustez
- [ ] HTML semântico correcto
- [ ] ARIA apenas quando HTML nativo não chega

## Padrões ARIA essenciais

```tsx
// Botão que abre modal
<button aria-haspopup="dialog" aria-expanded={isOpen}>Menu</button>

// Modal
<div role="dialog" aria-modal="true" aria-labelledby="modal-title">
  <h2 id="modal-title">Título</h2>
</div>

// Nav
<nav aria-label="Principal">...</nav>

// Imagem decorativa
<img src="..." alt="" aria-hidden="true" />

// Loading state
<div aria-live="polite" aria-busy={isLoading}>...</div>
```

## Focus management

```tsx
// Focus visible custom (substituir outline padrão)
.focus-visible:focus-visible {
  @apply outline-2 outline-offset-2 outline-primary;
}

// Skip link
<a href="#main-content" className="sr-only focus:not-sr-only focus:fixed focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-primary focus:text-white">
  Saltar para conteúdo
</a>
```

## Teste rápido
1. Navegar toda a página só com Tab/Enter/Escape
2. Usar VoiceOver (Mac) ou NVDA (Win) para testar leitura
3. Desactivar CSS e verificar estrutura semântica
