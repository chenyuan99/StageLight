# Native iPad layout — initial scope

The app and test targets now support both iPhone and iPad. iPad supports all four orientations without requiring full screen, allowing the system to manage resizable windows.

- Collection chooses columns from available window width in regular size classes (up to six). Compact layouts retain two columns; accessibility text sizes use one column.
- Show detail, performance detail, diary, and profile use a centered reading width of at most 760 points in regular layouts.
- Bottom navigation retains the existing controls and gold add button, with a maximum content width of 640 points.
- Add/edit and memory-card flows retain system sheet presentation, rather than adding a separate iPad workflow.

This first pass deliberately does not add sidebar navigation or a two-pane diary. It uses the existing models, store, identifiers, iCloud container, and migration plan unchanged. Enabling iPad is not a release/version bump; App Store screenshot and release preparation remain separate work.

Verified on iOS 26.5 simulators:

- iPad: 66 tests passed, including existing unit regressions, width-policy tests, and empty-library/add/save UI flows.
- iPhone: width-policy tests and the add/save UI flow passed.
- Visually inspected the iPad collection in landscape and portrait; fixed duplicate system tabs so only the existing bottom navigation appears.

Physical-device multitasking, detailed sheet/share inspection, and a full accessibility audit remain release checks.
