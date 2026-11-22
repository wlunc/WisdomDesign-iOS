#!/usr/bin/env node
'use strict';
// Safe scaffold copy: whitelist page id, reject traversal/missing target/overwrite.
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const TEMPLATE = path.join(ROOT, 'ai', 'skill-provider', 'templates', 'task-list.swift');
const WORKSPACE = path.join(ROOT, 'AIStarter');
const PAGE_IDS = { 'task-list': TEMPLATE };

function fail(message) { console.error(message); process.exit(1); }
function main() {
  if (process.argv.length !== 4) fail('usage: copy_template.js <page-id> <workspace-relative-destination>');
  const [page, rel] = process.argv.slice(2);
  if (!Object.prototype.hasOwnProperty.call(PAGE_IDS, page)) fail('unsupported page id: ' + page);
  if (!/^[A-Za-z][A-Za-z0-9]*$/.test(path.basename(rel, path.extname(rel)))) fail('invalid destination filename');
  const dest = path.resolve(WORKSPACE, rel);
  const relative = path.relative(WORKSPACE, dest);
  if (relative.startsWith('..') || path.isAbsolute(relative)) fail('destination escapes workspace');
  if (!fs.existsSync(path.dirname(dest)) || !fs.statSync(path.dirname(dest)).isDirectory()) fail('destination directory does not exist');
  if (fs.existsSync(dest)) fail('refusing to overwrite existing file');
  fs.copyFileSync(PAGE_IDS[page], dest);
  console.log('copied template to ' + path.relative(WORKSPACE, dest).split(path.sep).join('/'));
}
main();
