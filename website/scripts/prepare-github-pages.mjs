import { existsSync, readdirSync, readFileSync, renameSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';

const output = resolve('dist/client');
const basePath = process.env.NEXT_PUBLIC_BASE_PATH ?? '/StageLight';

// Vinext includes assetPrefix in its output directory. Pages already serves
// the entire artifact under this prefix, so _next belongs at the artifact root.
const nestedAssets = join(output, basePath.replace(/^\//, ''), '_next');
if (existsSync(nestedAssets)) {
  renameSync(nestedAssets, join(output, '_next'));
}

let checked = 0;
for (const page of readdirSync(output).filter((name) => name.endsWith('.html'))) {
  const html = readFileSync(join(output, page), 'utf8');
  for (const match of html.matchAll(/(?:src|href)="([^"]+)"/g)) {
    const url = new URL(match[1], `https://example.com${basePath}/`);
    if (url.origin !== 'https://example.com') continue;
    if (!url.pathname.startsWith(`${basePath}/`)) {
      throw new Error(`${page}: local URL is outside the Pages path: ${match[1]}`);
    }
    const relative = decodeURIComponent(url.pathname.slice(basePath.length + 1));
    const target = join(output, relative || 'index.html');
    if (!existsSync(target) || !statSync(target).isFile()) {
      throw new Error(`${page}: missing exported file for ${match[1]}`);
    }
    checked += 1;
  }
}
console.log(`Verified ${checked} local page, image, script, and stylesheet references.`);
