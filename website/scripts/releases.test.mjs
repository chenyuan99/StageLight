import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const releases = JSON.parse(readFileSync(new URL('../lib/releases.json', import.meta.url)));

test('the submitted build is distinct from the live App Store release', () => {
  assert.equal(releases.version, '1.7.0');
  assert.equal(releases.build, 10);
  assert.equal(releases.status, 'waiting_for_review');
  assert.equal(releases.submittedOn, '2026-11-14');
  assert.equal(releases.liveVersion, '1.6.0');
  assert.equal(releases.previousVersion, '1.5.1');
  assert.equal(releases.releasedOn, undefined);
});

test('each language identifies the review status and current availability', () => {
  const statuses = { en: 'Waiting for Review', 'zh-Hans': '等待审核', 'zh-Hant': '等待審核', ja: '審査待ち' };
  assert.deepEqual(Object.keys(releases.locales).sort(), Object.keys(statuses).sort());
  for (const [language, copy] of Object.entries(releases.locales)) {
    assert.equal(copy.status, releases.version + ' · ' + statuses[language]);
    for (const key of ['heading', 'privacy', 'history', 'previous', 'live']) {
      assert.ok(copy[key].trim(), key);
    }
    assert.equal(copy.features.length, 3);
    assert.ok(copy.features.every(pair => pair.length === 2 && pair.every(text => text.trim())));
  }
});
