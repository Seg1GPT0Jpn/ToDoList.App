import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { precacheList, render } from '../../scripts/update-sw.mjs';

const read = (f) => fs.readFileSync(fileURLToPath(new URL('../../' + f, import.meta.url)), 'utf8');

describe('インストール（PWA）', () => {
  it('sw.js の PRECACHE が実際のファイルと一致する（ずれたら node scripts/update-sw.mjs）', () => {
    const src = read('sw.js');
    expect(render(src, precacheList())).toBe(src);
    for (const f of precacheList()) if (f !== './') expect(fs.existsSync(fileURLToPath(new URL('../../' + f, import.meta.url))), f).toBe(true);
  });

  it('manifest にインストールに必要な項目とアイコンがある', () => {
    const m = JSON.parse(read('manifest.webmanifest'));
    expect(m.name).toBeTruthy();
    expect(m.short_name.length).toBeLessThanOrEqual(12);
    expect(m.display).toBe('standalone');
    expect(m.start_url.startsWith('./')).toBe(true);
    const sizes = m.icons.map(i => i.sizes);
    expect(sizes).toContain('192x192');
    expect(sizes).toContain('512x512');
    expect(m.icons.some(i => i.purpose === 'maskable')).toBe(true);
    for (const i of m.icons) {
      const buf = fs.readFileSync(fileURLToPath(new URL('../../' + i.src, import.meta.url)));
      if (i.type === 'image/png') {
        // PNG の幅・高さが sizes と同じか
        const w = buf.readUInt32BE(16), h = buf.readUInt32BE(20);
        expect(`${w}x${h}`, i.src).toBe(i.sizes);
      }
    }
  });

  it('index.html が manifest・アイコンを読み込む', () => {
    const html = read('index.html');
    expect(html).toContain('rel="manifest" href="manifest.webmanifest"');
    expect(html).toContain('rel="apple-touch-icon"');
    expect(html).toContain('name="theme-color"');
  });
});
