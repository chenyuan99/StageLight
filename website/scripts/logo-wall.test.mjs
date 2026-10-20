import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const root = new URL('../../', import.meta.url);
const wall = JSON.parse(readFileSync(new URL('../lib/logo-wall.json', import.meta.url)));
const originals = [
  'StageLight/Resources/Assets.xcassets/DefaultAppIcon.appiconset/GoldenPremiereIcon.png',
  'StageLight/Resources/Assets.xcassets/CreamBunnyIcon.appiconset/CreamBunnyIcon.png',
  'StageLight/Resources/Assets.xcassets/BunnyIcon.appiconset/BunnyIcon.png',
  'StageLight/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png',
  'docs/images/logo-concepts/golden-premiere-cat.png',
];
test('all five frames preserve original artwork and apply equal rounded corners', () => {
  assert.equal(wall.icons.length, 5);
  wall.icons.forEach((name, index) => {
    const svg = readFileSync(new URL(`../public/logo-wall/${name}.svg`, import.meta.url), 'utf8');
    assert.ok(svg.includes('rx="224"'));
    assert.ok(svg.includes('clip-path="url(#icon)"'));
    const encoded = svg.match(/base64,([^"]+)/)[1];
    assert.deepEqual(Buffer.from(encoded, 'base64'), readFileSync(new URL(originals[index], root)));
  });
});
test('all languages include complete names and concept/default disclosures', () => {
  assert.deepEqual(Object.keys(wall.locales).sort(), ['en', 'ja', 'zh-Hans', 'zh-Hant']);
  for (const locale of Object.values(wall.locales)) {
    assert.equal(locale.names.length, 5);
    for (const value of Object.values(locale)) {
      assert.ok(Array.isArray(value) ? value.every(Boolean) : value.length > 0);
    }
  }
});
test('README and landing page share the rounded assets without the glasses concept', () => {
  const readme = readFileSync(new URL('README.md', root), 'utf8');
  for (const name of wall.icons) assert.ok(readme.includes(`website/public/logo-wall/${name}.svg`));
  assert.ok(!readme.includes('cat-glasses'));
  const home = readFileSync(new URL('../app/home.tsx', import.meta.url), 'utf8');
  assert.ok(home.includes('${basePath}/logo-wall/${icon}.svg'));
  assert.ok(home.includes('loading="lazy"'));
});
