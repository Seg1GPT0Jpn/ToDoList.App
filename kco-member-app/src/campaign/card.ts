import QRCode from 'qrcode';
import { normalizeHashtags } from '../lib/campaign';
import type { Campaign } from '../lib/types';

/*
 * 団員募集カード（画像）を作る。
 * ブラウザの中だけで描画するので、外部サービスに情報を送りません。
 *  ・post  … 1080×1350（インスタ投稿・LINE 向け 4:5）
 *  ・story … 1080×1920（インスタのストーリーズ 9:16）
 */

export type CardFormat = 'post' | 'story';

export const CARD_SIZES: Record<CardFormat, { width: number; height: number; label: string }> = {
  post: { width: 1080, height: 1350, label: '投稿用（4:5）' },
  story: { width: 1080, height: 1920, label: 'ストーリーズ用（9:16）' }
};

const C = {
  navy: '#1c2a48',
  navyDeep: '#141f37',
  ivory: '#faf7ef',
  gold: '#c2a66b',
  goldSoft: '#e6d7b3',
  muted: '#b9c0cf'
};

const SERIF = '"Noto Serif JP", "Hiragino Mincho ProN", "Yu Mincho", serif';
const SANS = '"Noto Sans JP", "Hiragino Kaku Gothic ProN", "Hiragino Sans", "Yu Gothic", Meiryo, sans-serif';
const LATIN = '"Cormorant Garamond", "Times New Roman", serif';

/** 描画に使う文字のフォントを先に読み込む（読み込めなくても端末のフォントで描画を続ける） */
async function loadFonts(text: string): Promise<void> {
  if (typeof document === 'undefined' || !document.fonts) return;
  const sample = text + '0123456789KANAGAWACONNECTORCHESTRA急募募集中現在目標人締切詳しくはこちら';
  try {
    await Promise.all([
      document.fonts.load(`600 100px "Noto Serif JP"`, sample),
      document.fonts.load(`400 40px "Noto Sans JP"`, sample),
      document.fonts.load(`700 40px "Noto Sans JP"`, sample),
      document.fonts.load(`500 40px "Cormorant Garamond"`, 'KANAGAWA CONNECT ORCHESTRA')
    ]);
  } catch {
    // フォントが読めなくても続行
  }
}

/** 日本語も折り返せるよう1文字ずつ測って行に分ける（改行はそのまま） */
export function wrapText(ctx: Pick<CanvasRenderingContext2D, 'measureText'>, text: string, maxWidth: number, maxLines: number): string[] {
  const lines: string[] = [];
  for (const para of text.split(/\r?\n/)) {
    let line = '';
    for (const ch of [...para]) {
      const next = line + ch;
      if (ctx.measureText(next).width > maxWidth && line) {
        // 行頭に句読点が来ないようにする
        if (/^[、。，．）」』！？!?]$/.test(ch)) {
          lines.push(next);
          line = '';
          continue;
        }
        lines.push(line);
        line = ch;
      } else {
        line = next;
      }
    }
    lines.push(line);
  }
  const trimmed = lines.length > 1 && lines[lines.length - 1] === '' ? lines.slice(0, -1) : lines;
  if (trimmed.length <= maxLines) return trimmed;
  const out = trimmed.slice(0, maxLines);
  out[maxLines - 1] = out[maxLines - 1].replace(/.$/u, '') + '…';
  return out;
}

function spaced(ctx: CanvasRenderingContext2D, text: string, x: number, y: number, spacing: number) {
  // letterSpacing が使えるブラウザはそれを使う
  const anyCtx = ctx as CanvasRenderingContext2D & { letterSpacing?: string };
  if ('letterSpacing' in anyCtx) {
    anyCtx.letterSpacing = `${spacing}px`;
    ctx.fillText(text, x, y);
    anyCtx.letterSpacing = '0px';
    return;
  }
  ctx.fillText(text, x, y);
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

/** パートのチップを中央揃えで並べ、使った高さを返す（draw=false なら高さを測るだけ） */
function drawChips(ctx: CanvasRenderingContext2D, labels: string[], centerX: number, y: number, maxWidth: number, filled: boolean, scale: number, draw = true): number {
  const h = 64 * scale;
  const padX = 26 * scale;
  const gap = 16 * scale;
  ctx.font = `700 ${Math.round(32 * scale)}px ${SANS}`;
  // 1行に入るだけ並べる
  const rows: { label: string; w: number }[][] = [[]];
  let rowWidth = 0;
  for (const label of labels) {
    const w = ctx.measureText(label).width + padX * 2;
    const row = rows[rows.length - 1];
    if (row.length && rowWidth + gap + w > maxWidth) {
      rows.push([{ label, w }]);
      rowWidth = w;
    } else {
      row.push({ label, w });
      rowWidth += (row.length > 1 ? gap : 0) + w;
    }
  }
  const height = rows.length * h + (rows.length - 1) * gap;
  if (!draw) return height;
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'left';
  rows.forEach((row, i) => {
    const total = row.reduce((sum, c) => sum + c.w, 0) + gap * (row.length - 1);
    let cx = centerX - total / 2;
    const cy = y + i * (h + gap);
    for (const chip of row) {
      roundRect(ctx, cx, cy, chip.w, h, h / 2);
      if (filled) {
        ctx.fillStyle = C.gold;
        ctx.fill();
        ctx.fillStyle = C.navyDeep;
      } else {
        ctx.strokeStyle = C.gold;
        ctx.lineWidth = 3 * scale;
        ctx.stroke();
        ctx.fillStyle = C.ivory;
      }
      ctx.fillText(chip.label, cx + padX, cy + h / 2 + 1);
      cx += chip.w + gap;
    }
  });
  ctx.textBaseline = 'alphabetic';
  return height;
}

/** カードを描いた canvas を返す */
export async function renderCard(campaign: Campaign, joinUrl: string, format: CardFormat, canvas?: HTMLCanvasElement): Promise<HTMLCanvasElement> {
  const { width: W, height: H } = CARD_SIZES[format];
  const el = canvas ?? document.createElement('canvas');
  el.width = W;
  el.height = H;
  const ctx = el.getContext('2d');
  if (!ctx) throw new Error('この端末では画像を作成できません');

  const urgent = campaign.parts.filter(p => p.level === 'urgent').map(p => p.label);
  const wanted = campaign.parts.filter(p => p.level === 'wanted').map(p => p.label);
  await loadFonts(campaign.headline + campaign.message + urgent.join('') + wanted.join('') + campaign.deadlineText + campaign.hashtags);

  const story = format === 'story';
  const M = 72; // 外側の余白
  const inner = W - M * 2;

  // 背景（濃紺のグラデーション）
  const g = ctx.createLinearGradient(0, 0, 0, H);
  g.addColorStop(0, C.navy);
  g.addColorStop(1, C.navyDeep);
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, W, H);

  // 金の細い枠
  ctx.strokeStyle = C.gold;
  ctx.lineWidth = 2;
  ctx.strokeRect(36, 36, W - 72, H - 72);
  ctx.globalAlpha = 0.45;
  ctx.strokeRect(48, 48, W - 96, H - 96);
  ctx.globalAlpha = 1;

  // 五線（装飾）
  ctx.strokeStyle = C.gold;
  ctx.globalAlpha = 0.16;
  ctx.lineWidth = 2;
  const staffTop = story ? 330 : 250;
  for (let i = 0; i < 5; i++) {
    ctx.beginPath();
    ctx.moveTo(48, staffTop + i * 18);
    ctx.lineTo(W - 48, staffTop + i * 18);
    ctx.stroke();
  }
  ctx.globalAlpha = 1;

  let y = story ? 210 : 150;

  // 団体名
  ctx.textAlign = 'center';
  ctx.fillStyle = C.gold;
  ctx.font = `500 34px ${LATIN}`;
  spaced(ctx, 'KANAGAWA CONNECT ORCHESTRA', W / 2, y, 6);
  y += 56;
  ctx.fillStyle = C.goldSoft;
  ctx.font = `500 32px ${SERIF}`;
  ctx.fillText('かながわコネクトオーケストラ', W / 2, y);

  // 見出し
  y += story ? 230 : 190;
  ctx.fillStyle = C.ivory;
  let headSize = 150;
  ctx.font = `600 ${headSize}px ${SERIF}`;
  // 字間（8px）も含めて枠に収まる大きさにする
  const headWidth = () => ctx.measureText(campaign.headline).width + 8 * [...campaign.headline].length;
  while (headWidth() > inner - 40 && headSize > 50) {
    headSize -= 6;
    ctx.font = `600 ${headSize}px ${SERIF}`;
  }
  spaced(ctx, campaign.headline, W / 2, y, 8);

  // 金の区切り線
  y += 54;
  ctx.fillStyle = C.gold;
  ctx.fillRect(W / 2 - 60, y, 120, 3);

  // ---- 本文（メッセージ・パート・人数）：高さを測ってから、見出しと QR コードの間の中央に置く ----
  const qrSize = story ? 300 : 250;
  const bottom = H - (story ? 170 : 110);
  const tags = normalizeHashtags(campaign.hashtags).join('  ');
  const qrY = bottom - qrSize - (tags ? 70 : 20);

  const chipScale = campaign.parts.length > 10 ? 0.85 : 1;
  ctx.font = `400 36px ${SANS}`;
  const messageLines = campaign.message ? wrapText(ctx, campaign.message, inner - 60, story ? 7 : 4) : [];
  const facts: string[] = [];
  if (campaign.showMemberCount && campaign.targetMembers > 0) facts.push(`現在 ${campaign.memberCount}人 ／ 目標 ${campaign.targetMembers}人`);
  if (campaign.deadlineText) facts.push(`締切 ${campaign.deadlineText}`);

  type Block = { height: number; draw: (top: number) => void };
  const blocks: Block[] = [];
  if (messageLines.length) {
    blocks.push({
      height: messageLines.length * 58,
      draw: top => {
        ctx.textAlign = 'center';
        ctx.fillStyle = C.ivory;
        ctx.font = `400 36px ${SANS}`;
        messageLines.forEach((line, i) => ctx.fillText(line, W / 2, top + 42 + i * 58));
      }
    });
  }
  const group = (title: string, labels: string[], filled: boolean) => {
    if (!labels.length) return;
    const chipsH = drawChips(ctx, labels, W / 2, 0, inner - 40, filled, chipScale, false);
    blocks.push({
      height: 50 + chipsH,
      draw: top => {
        ctx.textAlign = 'center';
        ctx.fillStyle = C.gold;
        ctx.font = `700 34px ${SANS}`;
        ctx.fillText(title, W / 2, top + 34);
        drawChips(ctx, labels, W / 2, top + 50, inner - 40, filled, chipScale);
      }
    });
  };
  group('急募', urgent, true);
  group('募集中のパート', wanted, false);
  if (!urgent.length && !wanted.length) {
    blocks.push({
      height: 50,
      draw: top => {
        ctx.textAlign = 'center';
        ctx.fillStyle = C.ivory;
        ctx.font = `700 42px ${SANS}`;
        ctx.fillText('全パート募集中', W / 2, top + 42);
      }
    });
  }
  if (facts.length) {
    blocks.push({
      height: 46,
      draw: top => {
        ctx.textAlign = 'center';
        ctx.fillStyle = C.goldSoft;
        let size = 38;
        ctx.font = `700 ${size}px ${SANS}`;
        while (ctx.measureText(facts.join('　｜　')).width > inner - 40 && size > 24) {
          size -= 2;
          ctx.font = `700 ${size}px ${SANS}`;
        }
        ctx.fillText(facts.join('　｜　'), W / 2, top + 38);
      }
    });
  }

  const blockGap = story ? 70 : 40;
  const contentH = blocks.reduce((sum, b) => sum + b.height, 0) + blockGap * Math.max(blocks.length - 1, 0);
  const areaTop = y + 44;
  const areaH = qrY - 40 - areaTop;
  // 入りきらないときは本文全体を縮小する（QR コードと重ならないように）
  const k = contentH > areaH ? areaH / contentH : 1;
  ctx.save();
  ctx.translate(W / 2, areaTop + Math.max(0, (areaH - contentH * k) / 2));
  ctx.scale(k, k);
  ctx.translate(-W / 2, 0);
  let top = 0;
  for (const b of blocks) {
    b.draw(top);
    top += b.height + blockGap;
  }
  ctx.restore();

  // ---- 下部：QR コードと URL ----

  const qr = document.createElement('canvas');
  await QRCode.toCanvas(qr, joinUrl, { width: qrSize - 40, margin: 0, errorCorrectionLevel: 'M', color: { dark: C.navy, light: C.ivory } });
  const qrX = M + 20;
  ctx.fillStyle = C.ivory;
  roundRect(ctx, qrX, qrY, qrSize, qrSize, 18);
  ctx.fill();
  ctx.drawImage(qr, qrX + 20, qrY + 20, qrSize - 40, qrSize - 40);

  ctx.textAlign = 'left';
  const tx = qrX + qrSize + 44;
  ctx.fillStyle = C.ivory;
  ctx.font = `700 42px ${SANS}`;
  ctx.fillText('応募・詳細はこちら', tx, qrY + 80);
  ctx.fillStyle = C.goldSoft;
  ctx.font = `400 28px ${SANS}`;
  const urlLines = wrapText(ctx, joinUrl.replace(/^https:\/\//, ''), W - tx - M - 10, 2);
  urlLines.forEach((l, i) => ctx.fillText(l, tx, qrY + 140 + i * 40));
  ctx.fillStyle = C.muted;
  ctx.font = `400 26px ${SANS}`;
  ctx.fillText('QRコードを読み取ってください', tx, qrY + qrSize - 14);

  if (tags) {
    ctx.textAlign = 'center';
    ctx.fillStyle = C.gold;
    ctx.font = `400 30px ${SANS}`;
    const line = wrapText(ctx, tags, inner, 1)[0];
    ctx.fillText(line, W / 2, bottom + 30);
  }

  return el;
}

export function canvasToBlob(canvas: HTMLCanvasElement): Promise<Blob> {
  return new Promise((resolve, reject) => {
    canvas.toBlob(b => (b ? resolve(b) : reject(new Error('画像を作成できませんでした'))), 'image/png');
  });
}
