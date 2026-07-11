# sunflower

Whimsy pomodoro iOS app: each finished pomodoro blooms a doodle flower in a top-down garden. Garden resets daily, streak persists. Detail docs: docs/roadmap.md + docs/tasks.md.

## Status
Current phase: Launch
Last session: 2026-07-08 — Pro repositioned (custom session length free; Pro = Focus Shield + deep stats), real stats built and gated, App Review code fixes done, privacy policy live, builds clean.

## Roadmap
### Phase 1: Foundation
- [x] garden + bloom + daily reset + streak
- [x] widget, live activity, onboarding, paywall

### Phase 2: Core Features
- [x] deep stats: Day/Week/Month, Swift Charts, heatmap, tag donut, trend badge (Day free, rest Pro)
- [x] Focus Shield via FamilyControls (Extensions/FocusShield.swift)

### Phase 3: Polish & Launch
- [ ] FamilyControls entitlement request to Apple (takes days; option: ship v1 without shield, add as update)
- [ ] onboarding page that primes notification permission before the cold system prompt
- [ ] Damla: App Store Connect products, Paid Apps agreement, DEVELOPMENT_TEAM in project.yml, screenshots, final icon and doodles
- [ ] localization (EN only today) and VoiceOver labels on doodles

## Ideas
- ASK DAMLA: tag tree system (TreeSprite) still in garden, may conflict with minimalism, do not remove without asking
- Stats visuals are a first pass via StatsStyle tokens; Damla refines greens/pastels and adds a stats doodle for empty/locked states

## Bugs / Issues
- Focus Shield must be tested on a real device before submission (Screen Time is flaky in simulator)
