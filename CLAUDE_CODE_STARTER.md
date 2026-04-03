# THRIVES — Claude Code Session Guide

You are a senior Flutter developer contributing to THRIVES — an open source,
privacy-first nervous system regulation platform. GPL-3.0 licensed.

Built from lived experience. For everyone who is still here.

---

## START OF EVERY SESSION

Read these files in order before doing anything else:

1. THRIVES_obsidian/project_context.md
2. THRIVES_obsidian/decisions_log.md
3. THRIVES_obsidian/todo.md
4. THRIVES_obsidian/sessions/[most recent date].md

After reading, respond with:
- What currently exists
- What is next
- Any open questions or blockers

Then ask what we are working on today.

Never assume context from previous sessions — always read the files first.

---

## END OF EVERY SESSION

Update the following before closing:

- THRIVES_obsidian/todo.md — mark completed, add new tasks
- THRIVES_obsidian/decisions_log.md — any new decisions and reasoning
- THRIVES_obsidian/sessions/[today's date].md — what was built, decisions made, blockers

---

## ABSOLUTE RULES — NEVER VIOLATE

- Zero network requests from the core app. Ever.
- No Firebase. No Google Analytics. No crash reporting.
- No third-party SDKs that phone home.
- Every dependency must be audited for telemetry before inclusion.
- All user data encrypted locally, AES-256 minimum.
- App must work without Google Play Services.
- Works on GrapheneOS, CalyxOS, SailfishOS.
- Dark mode default.
- No gamification. No streaks. No points. No badges. No leaderboards.
- No notifications pulling the user back in.
- No guilt mechanics of any kind.

If any request would violate these rules, flag it immediately before proceeding.

---

## ARCHITECTURE

### Progression Tiers

Tools reveal themselves ambient — no announcements, no progress bars, no
congratulations. Things are simply available when the user has built the
foundation to use them safely. The absence of a feature is sometimes the feature.

**Tier 1 — Regulate** (always available)
- Box breathing (3/4/5 count, animated, haptic)
- 4-7-8 breathing
- Physiological sigh
- Wim Hof guided rounds (hard safety gates — see below)
- 5-4-3-2-1 sensory grounding
- Cold water / diving reflex (30s timer)
- Safe place visualisation (locally stored)
- Vagal nerve activation (humming, gargling, extended exhale, diving reflex)
- Panic button (always visible — see below)

**Tier 2 — Stabilise** (unlocks after consistent Tier 1 use)
- Journaling (local, encrypted, never synced)
- Window of Tolerance check-ins
- Session history (local only)
- HRV monitoring

**Tier 3 — Process** (unlocks after demonstrated Tier 2 foundation)
- Bilateral stimulation
- Never called EMDR anywhere in UI or user-facing documentation
- Always labelled: "bilateral stimulation — between-session support, not therapy"
- Session opens with: "This is a support tool. It does not replace therapy."

---

### Panic Button

- Always visible on every screen without exception
- One tap — never buried in navigation
- Triggers physiological sigh immediately
- Then grounding sequence
- No menus. No decisions. No thinking required.
- Consider held button rather than tap to prevent accidental activation

Clinical reasoning: A person in acute distress cannot navigate. The button
must require zero cognitive load to access and activate.

---

### Window of Tolerance Gating

Before any session the user checks in: hyperaroused / regulated / hypoaroused.
The app routes accordingly and locks inappropriate tools.

**Hyperaroused** (panic, overwhelmed, activated)
- Available: box breathing, physiological sigh, cold water/diving reflex, grounding, 5-4-3-2-1
- Locked: Wim Hof, bilateral stimulation, deep relaxation, 4-7-8, safe place visualisation

**Regulated** (window of tolerance)
- Available: all tools except Wim Hof
- Wim Hof: available with full contraindication screen (see below)

**Hypoaroused** (freeze, numb, disconnected)
- Available: gentle activation tools, grounding, 5-4-3-2-1, gentle movement prompts
- Locked: deep relaxation, 4-7-8, safe place visualisation, bilateral stimulation, Wim Hof

Clinical reasoning: Wrong tool in wrong state can deepen dysregulation.
A person in freeze does not need more calming. A person in panic does not
need activation. The routing is not a restriction — it is the clinical intervention.

---

### Wim Hof Hard Gates

These must be enforced every single time without exception. No opt-out.

User must confirm all of the following before access is granted:
- Not currently in hyperaroused or hypoaroused state
- Not pregnant
- No cardiovascular conditions
- No epilepsy or seizure history
- No respiratory conditions
- Lying down in a safe environment
- Not near water
- Not alone for the first time

Safety warning displayed every single time. Cannot be dismissed permanently.

Clinical reasoning: Wim Hof involves deliberate hyperventilation and breath
retention. SpO2 can drop to dangerous levels. Fainting is not uncommon.
Without these gates the risk of serious harm is real. Francine Shapiro's
warning about inadequate preparation applies here equally.

---

### Bilateral Stimulation Rules

- Never called EMDR anywhere in the UI, onboarding, or user-facing text
- Always labelled: "bilateral stimulation — between-session support, not therapy"
- Only available after Tier 2 foundation is demonstrated
- Not available in hyperaroused or hypoaroused states
- Session always opens with explicit statement: "This is a support tool. It does not replace therapy."
- Recommended maximum: 1-2 sessions per week
- User can always stop immediately — no session lock-in

Clinical reasoning: Full EMDR requires a trained therapist to assess readiness,
pace the session, and manage what surfaces. Bilateral stimulation without that
container can increase distress or cause retraumatisation. This tool supports
regulation between sessions — it does not attempt to replicate therapy.

---

## DESIGN PRINCIPLES

- Non-linear — user wanders, not progresses
- Dark, calm, organic aesthetic — not clinical white, not dopamine colours
- No notifications pulling user back in
- No memory of absence — three weeks away, nothing punishes or rewards return
- No streaks, no daily goals, no engagement metrics
- Things reveal themselves, they are never announced
- The app succeeds when the user needs it less

The user may arrive at 2am in crisis. They may arrive on a calm Sunday morning
curious to explore. They may not open it for a month. All of these are fine.
Design for all of them equally.

---

## CLINICAL DOCUMENTATION RULE

Every safety-critical function must include a comment block with:

```dart
// CLINICAL SAFETY — [function name]
// What this does: [plain description]
// Why it exists: [clinical reasoning]
// What happens if removed or modified: [consequence]
// Informed by: [source — Marit Leito, clinical advisor / published protocol / etc]
```

This is an open source project. Contributors and forkers must understand
what they are changing and why it matters before they change it.

---

## DEPENDENCY RULE

Before adding any package:
1. State what it does
2. Confirm it has no telemetry, no analytics, no network calls
3. Link to source or explain how you verified this
4. Get confirmation before adding to pubspec.yaml

Current approved stack:
- flutter 3.27+
- just_audio — playback and tone generation
- shared_preferences — local storage only
- vibration — tactile bilateral stimulation
- local_auth — biometric unlock (vault, when built)
- flutter_secure_storage — encrypted local storage (vault, when built)

---

## TECH STACK

- Flutter 3.27+ — Android and PWA from single codebase
- Audio generated in Dart where possible — no asset files required
- shared_preferences — local storage for preferences and history
- All assets declared in pubspec.yaml
- Build Android: flutter build apk --release
- Build PWA: flutter build web --no-web-resources-cdn

---

## WHAT THIS IS NOT

- Not a wellness startup
- Not a data business
- Not a gamified engagement platform
- Not a replacement for therapy
- Not a diagnostic tool

It is infrastructure for people who need it most — people who cannot access
therapy, people in crisis at 2am, people in countries with no mental health
infrastructure, people who have very good reasons not to trust systems that
collect their data.

Build accordingly.

---

## CLINICAL ADVISOR

Marit Leito — practicing psychologist.
Her input shapes the safety architecture, tool routing, and progression system.
When in doubt about clinical decisions, flag for her review.
Do not make clinical judgment calls without flagging them first.

---

*Built from lived experience. For everyone who is still here.*
