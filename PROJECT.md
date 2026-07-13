# sunflower

Whimsy pomodoro iOS app: each finished pomodoro blooms a doodle flower in a top-down garden. Garden resets daily, streak persists. Detail docs: docs/roadmap.md + docs/tasks.md.

## Status
Current phase: Launch
Last session: 2026-07-13 — asset production moved to Midjourney (Damla cannot draw them): prompt pack in docs/mj-asset-prompts.md, long style iteration (sticker style still open, storybook painterly is the live candidate), garden ground decided as plain calm base + dynamic grass sprite layer.

## Roadmap
### Phase 1: Foundation
- [x] garden + bloom + daily reset + streak
- [x] widget, live activity, onboarding, paywall

### Phase 2: Core Features
- [x] deep stats: Day/Week/Month, Swift Charts, heatmap, tag donut, trend badge (Day free, rest Pro)
- [x] Focus Shield via FamilyControls (Extensions/FocusShield.swift)

### Phase 3: Polish & Launch
- [ ] assets via Midjourney: Damla generates from docs/mj-asset-prompts.md into mj-raw/, Claude cuts to transparent PNGs and places 1:1 by name (sticker style still open; ground = plain calm green)
- [ ] dynamic grass layer: ~50 childlike doodle blade sprites from MJ asset sheets (grass_blade_01..N), wind sway + finger response with Canvas + TimelineView + spring physics, daisies and bugs as reacting sprites (ladybug flees finger); no texture-warp shader in v1 (water ripple risk), shader parked as polish
- [ ] FamilyControls entitlement request to Apple (takes days; option: ship v1 without shield, add as update)
- [ ] onboarding page that primes notification permission before the cold system prompt
- [ ] Damla: App Store Connect products, Paid Apps agreement, DEVELOPMENT_TEAM in project.yml, screenshots, final icon and doodles
- [ ] localization (EN only today) and VoiceOver labels on doodles

## Ideas
- ASK DAMLA: tag tree system (TreeSprite) still in garden, may conflict with minimalism, do not remove without asking
- Stats visuals are a first pass via StatsStyle tokens; Damla refines greens/pastels and adds a stats doodle for empty/locked states

## Bugs / Issues
- Focus Shield must be tested on a real device before submission (Screen Time is flaky in simulator)
