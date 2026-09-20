export const W = 620;
export const H = 100;
export const ECG_BASE = 50;
export const PLETH_BASE = 88;

export const gauss = (p: number, c: number, w: number) =>
  Math.exp(-(((p - c) / w) ** 2));

export const pqrst = (p: number) =>
  0.13 * gauss(p, 0.14, 0.035) -
  0.08 * gauss(p, 0.245, 0.008) +
  gauss(p, 0.266, 0.009) -
  0.24 * gauss(p, 0.29, 0.013) +
  0.3 * gauss(p, 0.405, 0.055);

export const plethWave = (p: number) =>
  0.92 * gauss(p, 0.18, 0.085) +
  0.34 * gauss(p, 0.4, 0.075) +
  0.1 * gauss(p, 0.6, 0.12);

export const seam = (points: string[]) =>
  points
    .concat(
      points.slice(1).map((point) => {
        const [x, y] = point.split(',');
        return `${(parseFloat(x) + W).toFixed(1)},${y}`;
      }),
    )
    .join(' ');

export const flatTrace = (base: number, amp: number) => {
  const points: string[] = [];
  for (let x = 0; x <= W; x += 3) {
    const y = base - amp * Math.sin(x / 41) - amp * 0.5 * Math.sin(x / 11 + 1);
    points.push(`${x},${y.toFixed(2)}`);
  }
  return seam(points);
};

export const beatTrace = (
  fn: (p: number) => number,
  base: number,
  amp: number,
  beats: number,
) => {
  const points: string[] = [];
  const period = W / beats;
  for (let x = 0; x <= W; x += 1.3) {
    const y = base - amp * fn((x % period) / period);
    points.push(`${x.toFixed(1)},${y.toFixed(2)}`);
  }
  return seam(points);
};

export const noiseTrace = (base: number, spread: number) => {
  const points: string[] = [];
  for (let x = 0; x <= W; x += 2) {
    points.push(`${x},${(base + (Math.random() - 0.5) * spread).toFixed(1)}`);
  }
  return seam(points);
};
