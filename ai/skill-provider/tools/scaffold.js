#!/usr/bin/env node
'use strict';
/**
 * Package-relative scaffold copier.
 *
 * The provider payload ships templates under templates/, but the consumer app
 * path is only known at install time. This script therefore requires an explicit
 * target directory instead of assuming an in-repo AIStarter workspace, while
 * keeping the same safety rules as the repo-local copy_template.js:
 *   - whitelisted page id
 *   - destination must be inside the given workspace
 *   - destination directory must already exist
 *   - refuse to overwrite
 *
 * Usage:
 *   node scaffold.js --list
 *   node scaffold.js --page task-list --workspace <dir> --as TaskListScreen.swift
 *   node scaffold.js --page task-list --workspace <dir> --as TaskListScreen.swift --force
 */
const fs = require('node:fs');
const path = require('node:path');

const PACKAGE_ROOT = path.resolve(__dirname, '..');
const TEMPLATES = path.join(PACKAGE_ROOT, 'templates');
const PAGES = { 'task-list': 'task-list.swift' };

function fail(message) {
  console.error('scaffold: ' + message);
  process.exit(1);
}

function parseArgs(argv) {
  const args = { force: false };
  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (token === '--list') args.list = true;
    else if (token === '--force') args.force = true;
    else if (token === '--help' || token === '-h') args.help = true;
    else if (token === '--page') args.page = argv[++i];
    else if (token === '--workspace') args.workspace = argv[++i];
    else if (token === '--as') args.as = argv[++i];
    else fail('unknown argument ' + token);
  }
  return args;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log('usage: node scaffold.js --list | --page <id> --workspace <dir> --as <FileName.swift> [--force]');
    return;
  }
  if (args.list) {
    for (const [id, file] of Object.entries(PAGES)) {
      const source = path.join(TEMPLATES, file);
      console.log(id + '\t' + file + '\t' + (fs.existsSync(source) ? 'available' : 'MISSING'));
    }
    return;
  }
  if (!args.page || !args.workspace || !args.as) {
    fail('--page, --workspace and --as are required (use --list to see page ids)');
  }
  if (!Object.prototype.hasOwnProperty.call(PAGES, args.page)) {
    fail('unsupported page id "' + args.page + '"; available: ' + Object.keys(PAGES).join(', '));
  }
  if (!/^[A-Za-z][A-Za-z0-9]*\.swift$/.test(args.as)) {
    fail('--as must be a Swift file name like TaskListScreen.swift');
  }
  const workspace = path.resolve(args.workspace);
  if (!fs.existsSync(workspace) || !fs.statSync(workspace).isDirectory()) {
    fail('workspace does not exist or is not a directory: ' + workspace);
  }
  const destination = path.resolve(workspace, args.as);
  const relative = path.relative(workspace, destination);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    fail('destination escapes the workspace');
  }
  const source = path.join(TEMPLATES, PAGES[args.page]);
  if (!fs.existsSync(source)) fail('template missing in package: ' + source);
  if (fs.existsSync(destination) && !args.force) {
    fail('refusing to overwrite existing file (pass --force to replace): ' + destination);
  }
  fs.copyFileSync(source, destination);
  console.log('copied ' + args.page + ' -> ' + path.relative(workspace, destination).split(path.sep).join('/'));
}

main();
