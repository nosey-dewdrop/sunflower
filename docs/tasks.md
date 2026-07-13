# Tasks

## Open
- [ ] damla: final doodle assets via Midjourney — prompt pack ready in docs/mj-asset-prompts.md (13 Tem); Damla generates, Claude chroma-keys + places; new slots added: grass tufts + bugs (need small garden-decor code pass after assets land)
- [ ] pro power features (pre-launch): month/year trends, calendar view, icloud sync
- [ ] ux fixes from jul 2 review: dead show all button (intent unclear, left as is), stop confirmation,
      cumulative grace budget, notifications-off warning, tag rename, week start setting
      (done jul 7: tag delete crash risk, midnight rollover)
- [ ] app store connect setup (products, bank, tax) once developer account is ready
- [ ] decide fate of tag-tree system on the garden (keep or cut for simplicity)
- [ ] screenshots + metadata + privacy policy hosting

## Damla asset list (replace 1:1, keep these names)
All hand-drawn doodle, transparent PNG, big canvas (will be scaled down):

| asset | current placeholder | used in |
|---|---|---|
| flower_yellow | crayon yellow flower | garden, icon, onboarding |
| flower_red | crayon red flower | garden |
| flower_blue | crayon blue flower | garden |
| flower_purple | crayon purple flower | garden, paywall |
| sprout | green sprout | session marker, wilt animation, widget empty state, launch screen, live activity |
| ground_texture | green swirl fabric | garden bg, widget bg, icon bg |
| decor_strawberry | crayon strawberry | onboarding, paywall |
| decor_star | shooting star | onboarding |
| decor_sparkles | gold sparkles | onboarding, paywall, icon |
| decor_cloud_1 / decor_cloud_2 | blue clouds | onboarding |
| decor_butterfly_pink / decor_butterfly_pastel | butterflies | onboarding, paywall |
| AppIcon | composed from above | app icon 1024 |

Wilt animation upgrade (optional, later): 3 drawn frames per flower (upright, drooping, wilted) to replace the transform-based droop.

## Done (jul 2 sprint)
- doodle placeholders wired, pixel art fully retired
- market + coins removed
- gentle wilt mechanic (wall-clock, grace, lock/call safe, kill safe)
- widget (today garden + streak) + live activity countdown
- onboarding + launch screen + placeholder icon
- sunflower pro paywall (storekit 2, monthly/yearly/lifetime, restore, error handling)
- garden resets daily, widget matches
