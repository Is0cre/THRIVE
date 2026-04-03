# THRIVES — Todo

Priority order. Update after every session.

---

## Before Writing a Single Line of Code

- [ ] Check domain availability — thrives.app / thrives.io / thrives.dev
- [x] Set up GitHub repository — public, GPL-3.0 (README + LICENSE written, repo push pending)
- [x] Set up Obsidian vault in repo or separate private repo
- [ ] Contact psychology friends about advisory role
- [ ] Read NLnet open calls — nlnet.nl — assess fit and deadline
- [x] Install Flutter SDK and set up development environment
- [ ] Install Sailfish SDK (for future reference)
- [ ] Set up Proxmox deployment environment for PWA

---

## MVP (v0.1) — Build in This Order

### 1. Project skeleton
- [x] Flutter project initialised
- [x] Folder structure set up (features, core, data, ui)
- [x] Dark theme implemented with design tokens
- [x] Navigation structure (bottom nav, category home)
- [x] Local storage (shared_preferences) initialised
- [x] PWA manifest and service worker configured

### 2. Onboarding questionnaire
- [x] Question flow built
- [x] Profile generation logic
- [x] Local storage of profile
- [x] Skip option for returning users (WoT check-in on subsequent launches)

### 3. Regulate category
- [x] Box breathing with animated visual pacer
- [x] Physiological sigh (3/5/10 rounds, auto-play, haptic)
- [x] 4-7-8 breathing
- [x] 5-4-3-2-1 grounding protocol
- [x] Vagal nerve prompts (humming, cold, gargling, exhale)
- [x] Safe place visualisation with ambient audio
- [x] Wim Hof (with safety gates)
- [x] Cold water / diving reflex

### 4. Process category — bilateral stimulation
- [x] Bilateral visual dot (smooth left-right animation)
- [x] Speed controls (slow/medium/fast)
- [x] Dot size and colour options
- [x] Audio bilateral (alternating tones via just_audio)
- [x] Tactile bilateral (alternating vibration)
- [x] Combined modes
- [x] Session timer with gentle chime

### 5. Attune category
- [x] Binaural beats (Delta/Theta/Alpha/Beta) via just_audio (generated in Dart)
- [x] Isochronic tones
- [x] Nature sounds grid (file-needed state — assets to be added)
- [ ] Background audio when screen locks

### 6. Basic Monitor
- [x] Window of tolerance manual check-in (wired to app-wide WoT state)
- [x] Session history local storage
- [x] Tolerance history display
- [ ] Camera PPG heart rate (v0.2)

### 7. Safety and UX
- [x] Emergency grounding button (panic sequence — physiological sigh × 3)
- [x] Crisis resources screen (Malta + international)
- [x] First launch disclaimer
- [x] Privacy statement
- [ ] Advisory credits screen (pending Marit confirmation)
- [x] Window of Tolerance check-in gate (daily)
- [x] Tool gating by WoT state

### 8. PWA deployment
- [x] Flutter web build
- [ ] Deploy to Proxmox
- [ ] Test on iPhone Safari
- [ ] Test offline functionality

---

## v0.2

- [ ] Wearable integration (Health Connect API)
- [ ] HRV monitoring via wearable
- [ ] Pre-episode early warning system
- [ ] EFT tapping with body map
- [ ] Trauma-informed journaling with encryption
- [ ] Solfeggio frequencies
- [ ] Binaural + bilateral combination sessions
- [ ] User preset saving

---

## v0.3

- [ ] Adaptive suggestions based on usage patterns
- [ ] Optional cloud sync (user-provided endpoint)
- [ ] Electrodermal activity (EDA) via compatible wearables
- [ ] Resonance frequency breathing (personalised HRV)
- [ ] Reflect category — mood tracking, insights

---

## Future / Ongoing

- [ ] Sailfish OS native Qt/QML port
- [ ] F-Droid submission
- [ ] NLnet grant application
- [ ] NGO outreach for white-label deployments
- [ ] Psychology advisor onboarding
- [ ] Reproducible build pipeline
- [ ] Security audit
- [ ] Blacklight privacy inspection on PWA
- [ ] Community contributions via GitHub

---

## Ready to ship (non-code tasks)

- [ ] Push to GitHub — README.md, LICENSE, .gitignore all ready
- [ ] Domain check — thrives.app / thrives.io / thrives.dev
- [ ] App icons — 192px + 512px PNG to replace Flutter defaults
- [ ] Nature sound assets — CC0 sources: freesound.org / zapsplat.com (free tier)
- [ ] Marit advisory credit — add to Settings once confirmed

## Blocked / Waiting

- Domain name — check availability first
- Psychology advisors — need to reach out
- NLnet — need to check current open calls at nlnet.nl
