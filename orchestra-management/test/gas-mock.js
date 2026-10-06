/*
 * Google Apps Script（SpreadsheetApp など）のローカル検証用モック。
 * 本番環境には一切関係しません。Node.js 上で Code.gs をそのまま動かし、
 * 同期・集計・重複防止などの動作をテストするためだけに使います。
 *
 * 実装しているのは Code.gs が使う API のみです。
 * 実際の Google スプレッドシートの挙動に合わせている点：
 *  - 行数・列数（maxRows / maxColumns）を超える範囲への setValues はエラー
 *  - 「'」で始まる文字列は文字列として保存（先頭の ' は値に含まれない）
 *  - 「=」で始まる文字列は数式として扱われる（数式インジェクション検出用）
 *  - getLastRow / getLastColumn は値が入っている最終行・列
 */
'use strict';

const crypto = require('crypto');

function createGasEnvironment(options) {
  const opts = options || {};
  const stats = { reads: 0, writes: 0, otherCalls: 0 };
  const alerts = [];
  const toasts = [];
  const logs = [];
  let uiAvailable = opts.uiAvailable !== false;
  let confirmAnswer = 'YES';
  let lockAvailable = true;
  let sheetIdSeq = 1;
  const spreadsheetId = 'mock-spreadsheet-id';

  function isFormulaString(v) {
    return typeof v === 'string' && v.charAt(0) === '=';
  }

  function cloneValue(v) {
    if (v instanceof Date) return new Date(v.getTime());
    return v;
  }

  class MockRange {
    constructor(sheet, row, col, numRows, numCols) {
      if (row < 1 || col < 1 || numRows < 1 || numCols < 1) {
        throw new Error('範囲の指定が不正です: ' + [row, col, numRows, numCols].join(','));
      }
      this.sheet = sheet;
      this.row = row;
      this.col = col;
      this.numRows = numRows;
      this.numCols = numCols;
    }
    checkBounds() {
      if (this.row + this.numRows - 1 > this.sheet.maxRows ||
          this.col + this.numCols - 1 > this.sheet.maxCols) {
        throw new Error('範囲の座標がシートの範囲外です（' + this.sheet.name + '）');
      }
    }
    getRow() { return this.row; }
    getColumn() { return this.col; }
    getLastRow() { return this.row + this.numRows - 1; }
    getLastColumn() { return this.col + this.numCols - 1; }
    getNumRows() { return this.numRows; }
    getNumColumns() { return this.numCols; }
    getSheet() { return this.sheet; }
    getValues() {
      stats.reads++;
      this.checkBounds();
      const out = [];
      for (let r = 0; r < this.numRows; r++) {
        const line = [];
        for (let c = 0; c < this.numCols; c++) {
          line.push(cloneValue(this.sheet.get(this.row + r, this.col + c)));
        }
        out.push(line);
      }
      return out;
    }
    getValue() { return this.getValues()[0][0]; }
    getDisplayValues() {
      return this.getValues().map(r => r.map(v => (v === null || v === undefined ? '' : String(v))));
    }
    setValues(values) {
      stats.writes++;
      this.checkBounds();
      if (!Array.isArray(values) || values.length !== this.numRows) {
        throw new Error('データの行数が範囲と一致しません');
      }
      values.forEach((line, r) => {
        if (!Array.isArray(line) || line.length !== this.numCols) {
          throw new Error('データの列数が範囲と一致しません（' + (line && line.length) + ' / ' + this.numCols + '）');
        }
        line.forEach((v, c) => this.sheet.put(this.row + r, this.col + c, v));
      });
      return this;
    }
    setValue(v) {
      stats.writes++;
      this.checkBounds();
      this.sheet.put(this.row, this.col, v);
      return this;
    }
    setFormula(f) {
      stats.writes++;
      this.checkBounds();
      this.sheet.put(this.row, this.col, f);
      return this;
    }
    getFormula() {
      return this.sheet.formulas.get(this.row + ':' + this.col) || '';
    }
    clear() {
      stats.writes++;
      for (let r = 0; r < this.numRows; r++) {
        for (let c = 0; c < this.numCols; c++) {
          this.sheet.erase(this.row + r, this.col + c);
          this.sheet.validations.delete((this.row + r) + ':' + (this.col + c));
        }
      }
      return this;
    }
    clearContent() { return this.clear(); }
    setDataValidation(rule) {
      stats.otherCalls++;
      this.checkBounds();
      // 範囲単位で記録（セル単位に展開すると重いので先頭と範囲だけ保存）
      this.sheet.validationRanges.push({ row: this.row, col: this.col, numRows: this.numRows, numCols: this.numCols, rule });
      return this;
    }
    createFilter() {
      stats.otherCalls++;
      if (this.sheet.filter) throw new Error('すでにフィルタがあります');
      const sheet = this.sheet;
      const range = new MockRange(sheet, this.row, this.col, this.numRows, this.numCols);
      const criteria = {};
      sheet.filter = {
        range,
        criteria,
        getRange() { return range; },
        getColumnFilterCriteria(c) { return criteria[c] || null; },
        setColumnFilterCriteria(c, cr) { criteria[c] = cr; return this; },
        remove() { sheet.filter = null; }
      };
      return sheet.filter;
    }
    setBackgrounds() { stats.otherCalls++; return this; }
    setBackground() { stats.otherCalls++; return this; }
    setFontWeight() { stats.otherCalls++; return this; }
    setFontWeights() { stats.otherCalls++; return this; }
    setFontColor() { stats.otherCalls++; return this; }
    setNumberFormat() { stats.otherCalls++; return this; }
    setWrap() { stats.otherCalls++; return this; }
    setHorizontalAlignment() { stats.otherCalls++; return this; }
    setVerticalAlignment() { stats.otherCalls++; return this; }
    setNote() { stats.otherCalls++; return this; }
  }

  function parseA1(a1) {
    const m = String(a1).match(/^([A-Z]+)(\d+)(?::([A-Z]+)(\d+))?$/);
    if (!m) throw new Error('A1表記を解釈できません: ' + a1);
    const colOf = s => s.split('').reduce((n, ch) => n * 26 + (ch.charCodeAt(0) - 64), 0);
    const r1 = Number(m[2]);
    const c1 = colOf(m[1]);
    const r2 = m[4] ? Number(m[4]) : r1;
    const c2 = m[3] ? colOf(m[3]) : c1;
    return [r1, c1, r2 - r1 + 1, c2 - c1 + 1];
  }

  class MockSheet {
    constructor(name, ss) {
      this.name = name;
      this.ss = ss;
      this.cells = new Map();
      this.formulas = new Map();
      this.validations = new Map();
      this.validationRanges = [];
      this.maxRows = 1000;
      this.maxCols = 26;
      this.frozenRows = 0;
      this.filter = null;
      this.hidden = false;
      this.formUrl = null;
      this.id = sheetIdSeq++;
    }
    get(r, c) {
      const v = this.cells.get(r + ':' + c);
      return v === undefined ? '' : v;
    }
    put(r, c, v) {
      const key = r + ':' + c;
      this.formulas.delete(key);
      if (v === null || v === undefined || v === '') {
        this.cells.delete(key);
        return;
      }
      if (typeof v === 'string' && v.charAt(0) === "'") {
        this.cells.set(key, v.slice(1));
        return;
      }
      if (isFormulaString(v)) {
        // 数式として扱う（値は検証できないので目印を入れる）
        this.formulas.set(key, v);
        this.cells.set(key, '#FORMULA');
        return;
      }
      this.cells.set(key, cloneValue(v));
    }
    erase(r, c) {
      const key = r + ':' + c;
      this.cells.delete(key);
      this.formulas.delete(key);
    }
    getName() { return this.name; }
    setName(n) { this.name = n; return this; }
    getSheetId() { return this.id; }
    getParent() { return this.ss; }
    getLastRow() {
      stats.otherCalls++;
      let last = 0;
      this.cells.forEach((v, k) => { const r = Number(k.split(':')[0]); if (r > last) last = r; });
      return last;
    }
    getLastColumn() {
      stats.otherCalls++;
      let last = 0;
      this.cells.forEach((v, k) => { const c = Number(k.split(':')[1]); if (c > last) last = c; });
      return last;
    }
    getMaxRows() { return this.maxRows; }
    getMaxColumns() { return this.maxCols; }
    insertRowsAfter(after, n) {
      stats.otherCalls++;
      if (after !== this.maxRows) {
        // 途中挿入は Code.gs では使わない（末尾追加のみ）
        throw new Error('モックは末尾への行追加のみ対応');
      }
      this.maxRows += n;
      return this;
    }
    insertColumnsAfter(after, n) {
      stats.otherCalls++;
      if (after !== this.maxCols) throw new Error('モックは末尾への列追加のみ対応');
      this.maxCols += n;
      return this;
    }
    getRange(a, b, c, d) {
      stats.otherCalls++;
      if (typeof a === 'string') {
        const p = parseA1(a);
        return new MockRange(this, p[0], p[1], p[2], p[3]);
      }
      return new MockRange(this, a, b, c === undefined ? 1 : c, d === undefined ? 1 : d);
    }
    getDataRange() {
      const lr = Math.max(this.getLastRow(), 1);
      const lc = Math.max(this.getLastColumn(), 1);
      return new MockRange(this, 1, 1, lr, lc);
    }
    appendRow(values) {
      stats.writes++;
      const row = this.getLastRow() + 1;
      if (row > this.maxRows) this.maxRows = row;
      if (values.length > this.maxCols) this.maxCols = values.length;
      values.forEach((v, i) => this.put(row, i + 1, v));
      return this;
    }
    clear() {
      stats.writes++;
      this.cells.clear();
      this.formulas.clear();
      this.validations.clear();
      this.validationRanges = [];
      return this;
    }
    setFrozenRows(n) { this.frozenRows = n; return this; }
    getFrozenRows() { return this.frozenRows; }
    getFilter() { return this.filter; }
    autoResizeColumns() { stats.otherCalls++; return this; }
    setColumnWidth() { stats.otherCalls++; return this; }
    setColumnWidths() { stats.otherCalls++; return this; }
    hideSheet() { this.hidden = true; return this; }
    showSheet() { this.hidden = false; return this; }
    isSheetHidden() { return this.hidden; }
    getFormUrl() { return this.formUrl; }
    activate() { this.ss.active = this; return this; }

    // ---- テスト用ヘルパー（GASには存在しない） ----
    _setTable(rows) {
      this.cells.clear();
      this.formulas.clear();
      this.maxRows = Math.max(this.maxRows, rows.length);
      this.maxCols = Math.max(this.maxCols, rows.reduce((m, line) => Math.max(m, line.length), 0));
      rows.forEach((line, r) => line.forEach((v, c) => this.put(r + 1, c + 1, v)));
      return this;
    }
    _rows() {
      const lr = this.getLastRow();
      const lc = this.getLastColumn();
      const out = [];
      for (let r = 1; r <= lr; r++) {
        const line = [];
        for (let c = 1; c <= lc; c++) line.push(this.get(r, c));
        out.push(line);
      }
      return out;
    }
    _deleteRow(rowNumber) {
      const lr = this.getLastRow();
      const lc = this.getLastColumn();
      for (let r = rowNumber; r <= lr; r++) {
        for (let c = 1; c <= lc; c++) {
          const below = this.cells.get((r + 1) + ':' + c);
          const key = r + ':' + c;
          if (below === undefined) this.cells.delete(key); else this.cells.set(key, below);
        }
      }
    }
    _insertColumnBefore(col) {
      const entries = [];
      this.cells.forEach((v, k) => entries.push([k, v]));
      this.cells.clear();
      entries.forEach(([k, v]) => {
        const [r, c] = k.split(':').map(Number);
        this.cells.set(r + ':' + (c >= col ? c + 1 : c), v);
      });
      this.maxCols += 1;
    }
    _moveColumnToEnd(col) {
      const lc = this.getLastColumn();
      const lr = this.getLastRow();
      for (let r = 1; r <= lr; r++) {
        const moved = this.get(r, col);
        for (let c = col; c < lc; c++) {
          const v = this.get(r, c + 1);
          if (v === '') this.cells.delete(r + ':' + c); else this.cells.set(r + ':' + c, v);
        }
        if (moved === '') this.cells.delete(r + ':' + lc); else this.cells.set(r + ':' + lc, moved);
      }
    }
  }

  class MockSpreadsheet {
    constructor(name) {
      this.name = name;
      this.sheets = [];
      this.active = null;
    }
    getName() { return this.name; }
    getId() { return spreadsheetId; }
    getSheets() { return this.sheets.slice(); }
    getSheetByName(name) { return this.sheets.find(s => s.name === name) || null; }
    insertSheet(name) {
      stats.otherCalls++;
      if (this.getSheetByName(name)) throw new Error('同じ名前のシートがあります: ' + name);
      const s = new MockSheet(name, this);
      this.sheets.push(s);
      this.active = s;
      return s;
    }
    getActiveSheet() { return this.active || this.sheets[0] || null; }
    setActiveSheet(s) { this.active = s; return s; }
    getSpreadsheetTimeZone() { return 'Asia/Tokyo'; }
    toast(msg) { toasts.push(String(msg)); }
  }

  const spreadsheet = new MockSpreadsheet(opts.name || 'テスト用 応募者管理');

  // ---- トリガー ----
  let triggerSeq = 1;
  const triggers = [];
  const EventType = { ON_FORM_SUBMIT: 'ON_FORM_SUBMIT', ON_EDIT: 'ON_EDIT', CLOCK: 'CLOCK', ON_OPEN: 'ON_OPEN' };
  class MockTrigger {
    constructor(handler, type, sourceId) {
      this.handler = handler;
      this.type = type;
      this.sourceId = sourceId;
      this.id = 'trigger-' + (triggerSeq++);
    }
    getHandlerFunction() { return this.handler; }
    getEventType() { return this.type; }
    getTriggerSourceId() { return this.sourceId; }
    getUniqueId() { return this.id; }
  }
  const ScriptApp = {
    EventType,
    getProjectTriggers() { return triggers.slice(); },
    deleteTrigger(t) {
      const i = triggers.indexOf(t);
      if (i >= 0) triggers.splice(i, 1);
    },
    newTrigger(handler) {
      const b = {
        _ss: null, _type: null,
        forSpreadsheet(ss) { this._ss = ss; return this; },
        onFormSubmit() { this._type = EventType.ON_FORM_SUBMIT; return this; },
        onEdit() { this._type = EventType.ON_EDIT; return this; },
        create() {
          const t = new MockTrigger(handler, this._type, this._ss ? this._ss.getId() : null);
          triggers.push(t);
          return t;
        }
      };
      return b;
    }
  };

  // ---- UI ----
  const Button = { YES: 'YES', NO: 'NO', OK: 'OK', CANCEL: 'CANCEL' };
  const ButtonSet = { YES_NO: 'YES_NO', OK: 'OK', OK_CANCEL: 'OK_CANCEL' };
  const menus = [];
  const ui = {
    Button, ButtonSet,
    alert(a, b, c) {
      if (c === ButtonSet.YES_NO || b === ButtonSet.YES_NO) {
        alerts.push({ title: a, message: c ? b : a, confirm: true });
        return confirmAnswer === 'YES' ? Button.YES : Button.NO;
      }
      alerts.push({ title: b === undefined ? '' : a, message: b === undefined ? a : b });
      return Button.OK;
    },
    createMenu(name) {
      const menu = { name, items: [], addItem(label, fn) { this.items.push({ label, fn }); return this; },
        addSeparator() { this.items.push({ separator: true }); return this; },
        addSubMenu(sub) { this.items.push({ submenu: sub }); return this; },
        addToUi() { menus.push(this); } };
      return menu;
    }
  };

  class ValidationBuilder {
    constructor() { this.values = null; this.allowInvalid = true; }
    requireValueInList(values, showDropdown) { this.values = values.slice(); this.showDropdown = showDropdown; return this; }
    setAllowInvalid(b) { this.allowInvalid = b; return this; }
    build() { return { values: this.values, allowInvalid: this.allowInvalid }; }
  }

  const SpreadsheetApp = {
    getActiveSpreadsheet() { return spreadsheet; },
    getUi() {
      if (!uiAvailable) throw new Error('Cannot call SpreadsheetApp.getUi() from this context.');
      return ui;
    },
    newDataValidation() { return new ValidationBuilder(); },
    flush() {}
  };

  // ---- Lock / Properties / Utilities ----
  let lockHeld = false;
  const LockService = {
    getScriptLock() {
      return {
        tryLock() { if (!lockAvailable || lockHeld) return false; lockHeld = true; return true; },
        waitLock() { if (!lockAvailable || lockHeld) throw new Error('ロックを取得できませんでした'); lockHeld = true; },
        releaseLock() { lockHeld = false; },
        hasLock() { return lockHeld; }
      };
    }
  };
  const props = new Map();
  const PropertiesService = {
    getScriptProperties() {
      return {
        getProperty(k) { return props.has(k) ? props.get(k) : null; },
        setProperty(k, v) { props.set(k, String(v)); return this; },
        deleteProperty(k) { props.delete(k); return this; }
      };
    }
  };
  function pad(n, w) { return String(n).padStart(w || 2, '0'); }
  const Utilities = {
    DigestAlgorithm: { SHA_256: 'sha256' },
    Charset: { UTF_8: 'utf8' },
    computeDigest(alg, value) {
      const buf = crypto.createHash(alg).update(String(value), 'utf8').digest();
      // GAS は符号付きバイト（-128〜127）の配列を返す
      return Array.from(buf).map(b => (b > 127 ? b - 256 : b));
    },
    formatDate(date, tz, fmt) {
      // テストは TZ=Asia/Tokyo で実行する前提でローカル時刻を使う
      const d = date;
      return fmt
        .replace('yyyy', d.getFullYear())
        .replace('MM', pad(d.getMonth() + 1))
        .replace('dd', pad(d.getDate()))
        .replace('HH', pad(d.getHours()))
        .replace('mm', pad(d.getMinutes()))
        .replace('ss', pad(d.getSeconds()));
    },
    sleep() {}
  };
  const Session = { getScriptTimeZone() { return 'Asia/Tokyo'; } };
  const Logger = { log(m) { logs.push(String(m)); } };
  const consoleProxy = {
    log(...a) { logs.push(a.join(' ')); },
    info(...a) { logs.push(a.join(' ')); },
    warn(...a) { logs.push('[warn] ' + a.join(' ')); },
    error(...a) { logs.push('[error] ' + a.join(' ')); }
  };

  return {
    globals: { SpreadsheetApp, ScriptApp, LockService, PropertiesService, Utilities, Session, Logger, console: consoleProxy, Date },
    spreadsheet, stats, alerts, toasts, logs, triggers, menus, props,
    setUiAvailable(v) { uiAvailable = v; },
    setConfirmAnswer(v) { confirmAnswer = v; },
    setLockAvailable(v) { lockAvailable = v; },
    resetStats() { stats.reads = 0; stats.writes = 0; stats.otherCalls = 0; },
    addForeignTrigger(handler) { triggers.push(new MockTrigger(handler, EventType.ON_FORM_SUBMIT, spreadsheetId)); }
  };
}

module.exports = { createGasEnvironment };
