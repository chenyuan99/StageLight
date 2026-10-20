import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const releases = JSON.parse(readFileSync(new URL('../lib/releases.json', import.meta.url)));

test('pending submission is separate from the live version', () => {
  assert.equal(releases.status, 'waiting-for-review');
  assert.equal(releases.version, '1.5.0');
  assert.equal(releases.build, 7);
  assert.equal(releases.liveVersion, '1.4.1');
  assert.notEqual(releases.version, releases.liveVersion);
});

test('all storefront languages include complete release and privacy copy', () => {
  assert.deepEqual(Object.keys(releases.locales).sort(), ['en', 'ja', 'zh-Hans', 'zh-Hant']);
  for (const copy of Object.values(releases.locales)) {
    for (const key of ['heading', 'status', 'privacy', 'history', 'pending', 'live']) {
      assert.ok(copy[key].trim().length > 0, key);
    }
    assert.equal(copy.features.length, 3);
    assert.ok(copy.features.every(pair => pair.length === 2 && pair.every(text => text.trim())));
    assert.match(copy.privacy, /iCloud/);
    assert.match(copy.status, /1\.5\.0/);
  }
});
