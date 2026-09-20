import { createContext } from 'react';

export type Glitch = {
  g: (text: string | number, key: string, letters?: boolean) => string;
  tear: (key: string) => number;
  torn: boolean;
};

export const GARB = '▚▞█▓▒░#%&@!?';
export const BLOCK = 24;

export const GlitchContext = createContext<Glitch>({
  g: (text) => String(text),
  tear: () => 0,
  torn: false,
});

export const hashOf = (key: string, salt: number) => {
  let h = Math.floor(salt * 1e6);
  for (let i = 0; i < key.length; i++) {
    h = (h * 31 + key.charCodeAt(i)) | 0;
  }
  return Math.abs(h);
};

export function moshLayer(
  host: HTMLElement,
  source: HTMLElement,
  rects: { x: number; y: number; w: number; h: number }[],
  dx: number,
  dy: number,
  hue: number,
  life: number,
) {
  const path = rects
    .map((r) => `M${r.x} ${r.y}H${r.x + r.w}V${r.y + r.h}H${r.x}Z`)
    .join(' ');
  const layer = document.createElement('div');
  layer.className = 'moshlayer';
  layer.style.clipPath = `path('${path}')`;
  const inner = document.createElement('div');
  inner.className = 'moshinner';
  inner.style.transform = `translate(${dx}px,${dy}px)`;
  if (hue) {
    inner.style.filter = `hue-rotate(${hue}deg) saturate(1.8)`;
  }
  const clone = source.cloneNode(true) as HTMLElement;
  clone.style.position = 'absolute';
  clone.style.left = `${source.offsetLeft}px`;
  clone.style.top = `${source.offsetTop}px`;
  clone.style.width = `${source.offsetWidth}px`;
  clone.style.height = `${source.offsetHeight}px`;
  clone.style.overflow = 'hidden';
  inner.appendChild(clone);
  layer.appendChild(inner);
  host.appendChild(layer);
  setTimeout(() => {
    layer.style.opacity = '0.5';
  }, life * 0.62);
  setTimeout(() => layer.remove(), life);
}

export function datamosh(
  host: HTMLElement,
  source: HTMLElement,
  severity: number,
) {
  const cols = Math.ceil(host.clientWidth / BLOCK);
  const rows = Math.ceil(host.clientHeight / BLOCK);
  const pick = (n: number) => Math.floor(Math.random() * n);
  for (let v = 0; v < 2 + Math.round(severity * 4); v++) {
    const rects: { x: number; y: number; w: number; h: number }[] = [];
    for (let r = 0; r < 1 + pick(3); r++) {
      const row = pick(rows);
      const start = pick(cols);
      rects.push({
        x: start * BLOCK,
        y: row * BLOCK,
        w: (2 + pick(cols - start + 1)) * BLOCK,
        h: (1 + pick(2)) * BLOCK,
      });
    }
    for (let i = 0; i < 2 + pick(6 * severity); i++) {
      rects.push({
        x: pick(cols) * BLOCK,
        y: pick(rows) * BLOCK,
        w: BLOCK * (1 + pick(2)),
        h: BLOCK,
      });
    }
    const dx = (pick(5) - 2) * BLOCK;
    const dy = (pick(3) - 1) * BLOCK;
    const hue = Math.random() < 0.5 ? pick(300) - 150 : 0;
    const life = 280 + Math.random() * (500 + severity * 700);
    moshLayer(host, source, rects, dx || BLOCK, dy, hue, life);
  }
}
