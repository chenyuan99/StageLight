import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const releases = JSON.parse(readFileSync(new URL('../lib/releases.json', import.meta.url)));

test('current release is live without inventing a build or release date', () => {
  assert.equal(releases.status, 'live');
  assert.equal(releases.version, '1.5.1');
  assert.equal(releases.liveVersion, releases.version);
  assert.equal(releases.previousVersion, '1.4.1');
  assert.equal(releases.confirmedLiveOn, '2026-10-20');
  assert.equal(releases.build, undefined);
  assert.equal(releases.releasedOn, undefined);
});

test('all storefront languages include complete release and privacy copy', () => {
  assert.deepEqual(Object.keys(releases.locales).sort(), ['en', 'ja', 'zh-Hans', 'zh-Hant']);
  for (const copy of Object.values(releases.locales)) {
    for (const key of ['heading', 'status', 'privacy', 'history', 'previous', 'live']) {
      assert.ok(copy[key].trim().length > 0, key);
    }
    assert.equal(copy.features.length, 3);
    assert.ok(copy.features.every(pair => pair.length === 2 && pair.every(text => text.trim())));
    assert.match(copy.privacy, /iCloud/);
    assert.match(copy.status, /1\.5\.1/);
    assert.match(copy.live, /1\.5\.1/);
    assert.equal(copy.pending, undefined);
    assert.doesNotMatch(copy.status + copy.live, /Awaiting|Coming in|等待|即将|即將|審査待ち|登場予定/);
  }
});

test('public documentation and metadata advertise the live release', () => {
  const readme = readFileSync(new URL('../../README.md', import.meta.url), 'utf8');
  const layout = readFileSync(new URL('../app/layout.tsx', import.meta.url), 'utf8');
  const home = readFileSync(new URL('../app/home.tsx', import.meta.url), 'utf8');
  assert.match(readme, /1\.5\.1 is now live/);
  assert.match(readme, /RELEASE_1\.5\.1\.md/);
  assert.equal(layout.match(/1\.5\.1 is now available/g)?.length, 3);
  assert.ok(!home.includes('release.pending'));
  assert.ok(!home.includes('releases.build'));
});
