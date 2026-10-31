# Cresto reference

- Upstream: https://github.com/Nevodev/Cresto
- Revision: `74564563a686106d76d7d9a403dd994a4fbcb6a7`
- License: Apache-2.0 (retained in `LICENSE` and the application's legal assets).
- Referenced files: `feature/main/NavContainer.kt`, `theme/Transitions.kt`, `feature/guide/GuideScreen.kt` under `app/src/main/java/com/nevoit/cresto/`.
- Adaptation: `native/.../CrestoMotion.kt` preserves the 0.95 page scale, 100ms incoming delay, 200ms opacity, 400ms EaseOutExpo entry and 600ms cubic-bezier exit. Native cached pages remain mounted; incoming animations cancel/reverse on a new selection. Detail routes retain their outgoing destination until the animation finishes.
- Onboarding uses the reference's centered headings, compact icon/text cards, 96dp welcome emblem, fixed bottom action and critically damped pager spring (1.0, 300). Sachet's own account, consent and permission flows replace Cresto's todo content; no Cresto branding or artwork is bundled.

Adapted by Pluvist for Xachet; see the source comments in the modified files.
