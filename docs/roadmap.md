# Roadmap

Direction (jul 2): whimsy version of focuspomo. minimal in function, kitsch doodle in visuals.
Top-down garden: each finished pomodoro blooms a doodle flower on the ground. Garden resets each morning, streak carries.

## Phase 1: Foundation
- [x] project setup with xcodegen
- [x] swiftdata models (FocusTag, FocusSession, FlowerDrop, UserSettings)
- [x] color palette
- [x] horizontal page tab navigation (settings, timer, stats)

## Phase 2: Core Features
- [x] timer view with countdown, start/stop, tag selection
- [x] session persistence (completed, abandoned)
- [x] flower drop spawning on completed sessions
- [x] summary view with today's stats, timeline, tag breakdown
- [x] stats view with daily timeline
- [x] settings view with duration picker, tag management, toggles
- [x] market removed (simplicity; money model is pro subscription instead)

## Phase 3: Doodle World
- [x] doodle placeholder assets (pinterest crops, transparent, halo-cleaned)
- [x] top-down garden: ground texture + doodle flowers
- [x] garden shows today's flowers, fresh each morning
- [ ] damla's final doodle assets replace placeholders 1:1 by name (see assets list in tasks.md)

## Phase 4: Gentle Wilt
- [x] wall-clock timer (endDate based, background safe)
- [x] sprout marks where the flower will bloom during a session
- [x] leave mid-focus: wilt notification within seconds, 30s grace
- [x] return in time: sprout droops then recovers (drawn motion, no fade)
- [x] don't return: session abandoned honestly, wilted sprout sinks into soil, no grave
- [x] locking the phone is never punished; calls are never punished
- [x] app killed mid-session: settled honestly on next launch

## Phase 5: Widget + Live Activity
- [x] home screen widget: today's mini garden + streak (small, medium)
- [x] live activity: countdown on lock screen + dynamic island

## Phase 6: Onboarding + Identity
- [x] onboarding (3 pages, skippable, whimsy)
- [x] launch screen (cream + sprout)
- [x] placeholder app icon from doodle assets
- [ ] final app icon (damla)

## Phase 7: Money (day-1 paywall)
- [x] sunflower pro: monthly, yearly, lifetime (storekit 2)
- [x] paywall view + purchase error handling + restore
- [x] free tier: 2 flower types; pro: all types
- [x] local storekit config for sandbox testing
- [ ] app store connect: create products, bank/tax setup (needs apple developer account)

## Phase 8: Launch
- [ ] app store screenshots and metadata
- [ ] privacy policy hosted
- [ ] test storekit purchases in sandbox (damla runs)
- [ ] TR localization pass
