// Exit 1 when a source checkout needs rebuilding; exit 0 for a current build.
// Compare each input with its own output: checking only dist/bin/codegraph.js
// misses changes to the installer registry and other independently emitted files.
const fs = require('node:fs');
const path = require('node:path');

function needsBuild(root) {
  const entry = path.join(root, 'dist/bin/codegraph.js');
  if (!fs.existsSync(entry)) return true;
  const entryTime = fs.statSync(entry).mtimeMs;
  for (const name of ['package.json', 'package-lock.json', 'tsconfig.json']) {
    const input = path.join(root, name);
    if (fs.existsSync(input) && fs.statSync(input).mtimeMs > entryTime) return true;
  }

  function outdated(dir) {
    for (const item of fs.readdirSync(dir, { withFileTypes: true })) {
      const input = path.join(dir, item.name);
      if (item.isDirectory()) {
        if (outdated(input)) return true;
        continue;
      }
      if (!/\.(ts|sql|wasm)$/.test(item.name)) continue;
      // Ambient declarations affect compilation but have no emitted JS file.
      if (item.name.endsWith('.d.ts')) {
        if (fs.statSync(input).mtimeMs > entryTime) return true;
        continue;
      }
      const relative = path.relative(path.join(root, 'src'), input);
      const output = path.join(root, 'dist', relative.replace(/\.ts$/, '.js'));
      if (!fs.existsSync(output) || fs.statSync(input).mtimeMs > fs.statSync(output).mtimeMs) {
        return true;
      }
    }
    return false;
  }

  return outdated(path.join(root, 'src'));
}

if (require.main === module) {
  try {
    process.exitCode = needsBuild(path.resolve(process.argv[2] || '.')) ? 1 : 0;
  } catch (error) {
    console.error(`Cannot check local build: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { needsBuild };
