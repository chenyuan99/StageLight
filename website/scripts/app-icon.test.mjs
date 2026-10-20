import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

test('landing page icon exactly matches the primary iOS app icon', () => {
  const source = new URL('../../StageLight/Resources/Assets.xcassets/DefaultAppIcon.appiconset/', import.meta.url);
  const manifest = JSON.parse(readFileSync(new URL('Contents.json', source)));
  const icon = readFileSync(new URL(manifest.images[0].filename, source));
  assert.deepEqual(readFileSync(new URL('../public/golden-premiere-icon.png', import.meta.url)), icon);
});

test('header, download section, and browser metadata use the new icon', () => {
  const home = readFileSync(new URL('../app/home.tsx', import.meta.url), 'utf8');
  const layout = readFileSync(new URL('../app/layout.tsx', import.meta.url), 'utf8');
  assert.equal(home.match(/golden-premiere-icon\.png/g)?.length, 2);
  assert.ok(!home.includes('/app-icon.png'));
  assert.ok(layout.includes('/golden-premiere-icon.png'));
  assert.ok(layout.includes('apple: { url: iconURL'));
});
