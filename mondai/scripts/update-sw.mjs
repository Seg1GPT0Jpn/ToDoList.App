// sw.js の PRECACHE（オフライン用に最初に保存するファイルの一覧）を、実際のファイルから作り直す。
// 使い方: node scripts/update-sw.mjs　（js・css・内蔵問題・アイコンを足したり消したりしたら実行）
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

/** オフラインで使うために最初に保存するファイル（sw.js からの相対パス） */
export function precacheList() {
  const walk = (dir) => fs.readdirSync(path.join(root, dir), { withFileTypes: true })
    .flatMap(e => e.isDirectory() ? walk(path.join(dir, e.name)) : [path.join(dir, e.name)]);
  const files = ['js', 'css', 'builtin', 'icons'].flatMap(walk)
    .filter(f => /\.(js|css|json|png|svg)$/.test(f))
    .map(f => f.split(path.sep).join('/'));
  return ['./', 'index.html', 'manifest.webmanifest', ...files.sort()];
}

export function render(src, list) {
  const block = 'const PRECACHE = [\n' + list.map(f => `  ${JSON.stringify(f)},`).join('\n') + '\n];';
  return src.replace(/const PRECACHE = \[[\s\S]*?\];/, block);
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const p = path.join(root, 'sw.js');
  const src = fs.readFileSync(p, 'utf8');
  const out = render(src, precacheList());
  fs.writeFileSync(p, out);
  console.log(out === src ? 'sw.js は最新です' : 'sw.js の一覧を更新しました', `（${precacheList().length} ファイル）`);
}
