import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import * as fs from 'node:fs';
import * as os from 'node:os';
import * as path from 'node:path';
import { spawnSync } from 'node:child_process';

const repo = path.resolve(__dirname, '..');
const checker = path.join(repo, 'scripts/check-local-build.js');
let checkout: string;

function write(name: string, content = '', time = 1000) {
  const file = path.join(checkout, name);
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, content);
  fs.utimesSync(file, time, time);
}

function check() {
  return spawnSync(process.execPath, [checker, checkout]).status;
}

beforeEach(() => {
  checkout = fs.mkdtempSync(path.join(os.tmpdir(), 'cg-build with spaces-'));
  write('package.json', '{}');
  write('src/bin/codegraph.ts');
  write('dist/bin/codegraph.js', '', 2000);
});

afterEach(() => fs.rmSync(checkout, { recursive: true, force: true }));

describe('Quick tool build freshness', () => {
  it('keeps a current build and rebuilds a missing entry', () => {
    expect(check()).toBe(0);
    fs.unlinkSync(path.join(checkout, 'dist/bin/codegraph.js'));
    expect(check()).toBe(1);
  });

  it('rebuilds when a newly supported target has no compiled output', () => {
    write('src/installer/targets/copilot-vscode.ts');
    expect(check()).toBe(1);
  });

  it('compares the registry to its output even when the CLI entry is newer', () => {
    write('src/installer/targets/registry.ts', '', 1500);
    write('dist/installer/targets/registry.js');
    expect(check()).toBe(1);
  });

  it.each(['src/db/schema.sql', 'src/extraction/wasm/tree-sitter-test.wasm'])(
    'rebuilds missing or outdated copied assets: %s', (name) => {
      write(name, '', 1500);
      expect(check()).toBe(1);
      write(name.replace('src/', 'dist/'), '', 2000);
      expect(check()).toBe(0);
      write(name, '', 3000);
      expect(check()).toBe(1);
    },
  );

  it.each(['package.json', 'package-lock.json', 'tsconfig.json', 'src/types.d.ts'])(
    'rebuilds after compiler inputs change: %s', (name) => {
      write(name, '', 3000);
      expect(check()).toBe(1);
    },
  );
});

describe.runIf(process.platform === 'win32')('Windows quick tool startup', () => {
  function start(buildExit: number) {
    // Run the actual startup block with an isolated checkout and npm stub.
    // No user MCP settings or installed global CLI are touched.
    const batch = fs.readFileSync(path.join(repo, 'CodeGraph 快速工具.bat'), 'utf8').replace(/\r\n/g, '\n');
    const block = batch.slice(batch.indexOf('rem Step 2:'), batch.indexOf(':detect_done'));
    write('node_modules/typescript/placeholder');
    write('scripts/check-local-build.js', fs.readFileSync(checker, 'utf8'));
    write('src/installer/targets/copilot-vscode.ts');
    write('npm.cmd', `@echo off\r\necho build>build-called\r\nexit /b ${buildExit}\r\n`);
    write('startup.cmd', [
      '@echo off',
      'setlocal enabledelayedexpansion',
      `set "SCRIPT_DIR=${checkout}"`,
      `set "NODE_CMD=${process.execPath}"`,
      block,
      'echo selected>local-selected',
      'exit /b 0',
      batch.slice(batch.indexOf('\n:cg_setup_failed\n'), batch.indexOf('\n:cg_main\n')),
      ':ui',
      'exit /b 0',
      ':ensure_global_codegraph',
      'echo global>global-called',
      'exit /b 0',
    ].join('\n').replace(/\r?\n/g, '\r\n'));
    return spawnSync('cmd.exe', ['/d', '/c', 'startup.cmd'], {
      cwd: checkout, input: '\r\n', timeout: 15000,
    });
  }

  it('rebuilds stale dist before selecting the local CLI, without a global install', () => {
    expect(start(0).status).toBe(0);
    expect(fs.existsSync(path.join(checkout, 'build-called'))).toBe(true);
    expect(fs.existsSync(path.join(checkout, 'local-selected'))).toBe(true);
    expect(fs.existsSync(path.join(checkout, 'global-called'))).toBe(false);
  });

  it('stops on build failure instead of selecting stale dist or a global CLI', () => {
    const result = start(1);
    expect(result.status, `${result.stdout}\n${result.stderr}`).toBe(1);
    expect(result.stderr.toString()).toBe('');
    expect(fs.existsSync(path.join(checkout, 'build-called'))).toBe(true);
    expect(fs.existsSync(path.join(checkout, 'local-selected'))).toBe(false);
    expect(fs.existsSync(path.join(checkout, 'global-called'))).toBe(false);
  });
});
