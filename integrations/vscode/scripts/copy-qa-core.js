const fs = require('fs');
const path = require('path');

const sourceDir = path.resolve(__dirname, '../../../packages/qa_core');
const destDir = path.resolve(__dirname, '../qa_core');

if (!fs.existsSync(sourceDir)) {
  console.log('packages/qa_core not found; skipping copy.');
  process.exit(0);
}

function copyRecursive(src, dest) {
  const stats = fs.statSync(src);
  if (stats.isDirectory()) {
    const base = path.basename(src);
    if (base === '.dart_tool' || base === 'test' || base === '.git') {
      return;
    }
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }
    for (const file of fs.readdirSync(src)) {
      copyRecursive(path.join(src, file), path.join(dest, file));
    }
  } else {
    fs.copyFileSync(src, dest);
  }
}

console.log(`Syncing qa_core to ${destDir}...`);
copyRecursive(sourceDir, destDir);
console.log('qa_core sync complete.');
