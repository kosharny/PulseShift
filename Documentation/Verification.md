# Refinement verification — 24 October 2026

- Debug simulator and unsigned Release device builds succeed with the iOS 17 deployment target.
- `swift test`: 34 tests pass, including all bundled campaign solutions, persistence, every gameplay preference, and movement animation ordering across portals, turns and simultaneous magnet events.
- Capsule/icon correction: Debug and unsigned Release builds pass. Both targeted UI flows pass after the capsule restoration and store removal. The generated icon is compiled into the app.
- Final targeted rerun: tutorial completion and changing settings while paused, resuming with the correct Tutorial Tips visibility, persistence after relaunch, and legal navigation all pass.
- Simulator: existing iPhone 18 Pro Max, iOS 27.0, UUID `901EFED6-F6F5-4124-8E19-665C5FDA9807`. No simulator devices or runtimes were created or installed.
- Reviewed Home and Collection screenshots confirm content remains visible behind the floating tab bar, which has its own capsule background and border; the area around and below the capsule stays clear. Screenshots: `Screenshots/Refinement-Home.png` and `Screenshots/Refinement-Collection.png`.
- App icon: opaque 1024 × 1024 PNG in `AppIcon.appiconset`; see `AppIcon.md` for the asset and generation prompt.
- Fourteen WAV files are bundled, including the eight-second ambient loop. Loading, audio-session activation and playback run on a dedicated serial queue.
- The Game Center capability and entitlement are declared. Authenticated Game Center reporting and physical-device haptics still require validation with the publisher’s Apple configuration and hardware.


---

# Verification — 13 September 2026

## Builds

- Debug: built and ran on iOS Simulator.
- Release: built successfully for generic iOS / arm64 with code signing disabled.
- Deployment target: iOS 17.0, iPhone, portrait.
- No compiler errors or Swift source warnings. Xcode emits an App Intents metadata notice because this game does not depend on AppIntents.

## Automated tests

`swift test`: **24 tests passed**. These include replaying all **60 bundled solutions**, blocked/free moves, redirects, rotators, portals and default direction preservation, switch/gate behavior, crystals, reactor/dormant chains, attraction/repulsion/conflicting magnetic destinations, undo, restart, completion, scoring, hints, invalid level references, compact JSON decoding, disk persistence, reward idempotency, preference persistence, calendar streak boundaries and missing audio handling.

The shared Xcode scheme runs three UI scenarios:

1. Finale: complete Level 60 through its core/reactor cascade, portals, crystal hits and polarity changes; earn a Perfect Shift with a best chain of 11.
2. Tutorial: complete Levels 1, 2 and 3 consecutively, then return automatically to Home through the result action.
3. Session flow: complete Level 1, undo and restart Level 2, relaunch the app, verify saved progression, continue play and open Daily/Collection.

All three scenarios passed on iPhone 17 Pro Max and iPhone SE (3rd generation), using the installed iOS 26.5 simulator runtime. The final layout and completion-animation regression suite passed on iPhone SE. The iOS 17 deployment target is compile-checked; an iOS 17 runtime was not installed for execution testing.

## Visual checks

Reviewed screenshots of Home, the first tutorial board, the finale board and the completion screen. Corrected board-accessibility cell alignment, SpriteKit surface layering, system emoji fallback in directional symbols, and small-screen letterboxing.

Screenshots are in `Documentation/Screenshots`.

## External release work

