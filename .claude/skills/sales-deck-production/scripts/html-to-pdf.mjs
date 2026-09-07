#!/usr/bin/env node
// html-to-pdf.mjs — exporta um HTML local para PDF em navegador headless.
// Usa Playwright se disponível; senão Puppeteer. Espera fontes e imagens antes de imprimir.
//
// Usage: node html-to-pdf.mjs <input.html> <output.pdf> [--landscape] [--scale <n>] [--format A4|Letter] [--timeout <ms>]
//
// Sai com código ≠ 0 se alguma fonte declarada não carregar ou alguma imagem falhar —
// um PDF com fallback de fonte não é entregável.

import { existsSync, statSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

const args = process.argv.slice(2);
if (args.length < 2) {
  console.error("Usage: html-to-pdf.mjs <input.html> <output.pdf> [--landscape] [--scale n] [--format A4|Letter] [--timeout ms]");
  process.exit(2);
}
const [inputArg, outputArg, ...rest] = args;
const opt = (name, def) => { const i = rest.indexOf(name); return i >= 0 ? rest[i + 1] : def; };
const landscape = rest.includes("--landscape");
const scale = Number(opt("--scale", "1"));
const format = opt("--format", "A4");
const timeout = Number(opt("--timeout", "60000"));

const input = resolve(inputArg);
const output = resolve(outputArg);
if (!existsSync(input)) { console.error(`ERROR=input_not_found ${input}`); process.exit(2); }

async function loadEngine() {
  try { const pw = await import("playwright"); return { kind: "playwright", mod: pw }; } catch {}
  try { const pp = await import("puppeteer"); return { kind: "puppeteer", mod: pp.default ?? pp }; } catch {}
  console.error("ERROR=no_engine — instale um: `npm i -D playwright && npx playwright install chromium` ou `npm i -D puppeteer`");
  process.exit(3);
}

const READY_SCRIPT = `
(async () => {
  await document.fonts.ready;
  const fontsFailed = [];
  for (const f of document.fonts) { if (f.status === "error") fontsFailed.push(f.family + " " + f.weight + " " + f.style); }
  const imgs = Array.from(document.images);
  await Promise.all(imgs.map(img => img.complete ? Promise.resolve() : new Promise(r => { img.onload = r; img.onerror = r; })));
  const imgsFailed = imgs.filter(i => !i.complete || i.naturalWidth === 0).map(i => i.getAttribute("src"));
  const pages = document.querySelectorAll("section.page, .page").length;
  return { fontsFailed, imgsFailed, pages };
})()`;

const { kind, mod } = await loadEngine();
const url = pathToFileURL(input).href;
let browser;
try {
  let page, readiness;
  if (kind === "playwright") {
    browser = await mod.chromium.launch();
    page = await browser.newPage();
    await page.goto(url, { waitUntil: "networkidle", timeout });
    await page.emulateMedia({ media: "print" });
    readiness = await page.evaluate(READY_SCRIPT);
  } else {
    browser = await mod.launch({ headless: true });
    page = await browser.newPage();
    await page.goto(url, { waitUntil: "networkidle0", timeout });
    await page.emulateMediaType("print");
    readiness = await page.evaluate(READY_SCRIPT);
  }

  if (readiness.fontsFailed.length) {
    console.error(`ERROR=fonts_failed ${JSON.stringify(readiness.fontsFailed)}`);
    process.exit(4);
  }
  if (readiness.imgsFailed.length) {
    console.error(`ERROR=images_failed ${JSON.stringify(readiness.imgsFailed)}`);
    process.exit(5);
  }

  const pdfOpts = { path: output, printBackground: true, preferCSSPageSize: true, landscape, scale, format, margin: { top: "0", right: "0", bottom: "0", left: "0" } };
  await page.pdf(pdfOpts);
  const bytes = statSync(output).size;
  console.log(`PDF=${output}`);
  console.log(`ENGINE=${kind}`);
  console.log(`SECTIONS_IN_HTML=${readiness.pages}`);
  console.log(`SIZE_MB=${(bytes / 1048576).toFixed(2)}`);
  console.log("NEXT=rode scripts/check-pdf.sh para contar páginas reais, fontes e peso");
} catch (err) {
  console.error(`ERROR=export_failed ${err?.message ?? err}`);
  process.exit(1);
} finally {
  if (browser) await browser.close();
}
