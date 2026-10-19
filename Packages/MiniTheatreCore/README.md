# MiniTheatreCore

Pure, deterministic reward and outfit rules used directly by the StageLight app through a local Swift package dependency. Inputs are values; there is no SwiftData, CloudKit, filesystem, UI or networking dependency in this module.

```sh
swift test --package-path Packages/MiniTheatreCore
```

The test-first sequence was verified: 31 tests initially failed against explicit `notImplemented` stubs; all 31 now pass against the implementation. The stubs have been removed. Run this suite locally; adding it to the iOS workflow is pending GitHub workflow authorization. Existing app-unit CI covers the companion integration tests.

Coverage: explicit activation/disable, thresholds, UUID deduplication, midnight/time zones/DST, structured venue identity, idempotent awards, rule versions, additive/retired catalogs, equipment validation and replacement, nickname graphemes, 1,000-record bounded output.

App integration tests live in `StageLightTests/MiniTheatreTests.swift`; UI tests in `StageLightUITests/MiniTheatreUITests.swift`. See `docs/specs/MINI_THEATRE_COMPANION.md` for privacy and remaining release gates. A pure-rule pass alone is not a data-durability or release certification.
