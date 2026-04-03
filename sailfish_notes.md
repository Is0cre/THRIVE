# THRIVES — Sailfish OS Notes

## Why Sailfish
- Genuine Linux-based mobile OS — no Google anywhere
- Privacy-respecting by architecture
- Our target users overlap significantly with Sailfish users
- Native app = first class citizen, not Android compatibility layer

---

## Current Status
- Phase: Future — post MVP
- Flutter APK runs via AlienDalvik (Android compatibility) now
- Native Qt/QML port planned

---

## Sailfish Development Basics
- Framework: Qt/QML (Silica UI components)
- Language: C++ and/or QML
- IDE: Sailfish SDK (free)
- App store: Jolla Harbour (free submission)
- No annual fee unlike Apple

---

## Sailfish SDK
- Download: sailfishos.org/develop
- Includes emulator
- Cross-compiles from Linux/Mac/Windows

---

## Silica UI Notes
- Sailfish uses its own Silica QML components
- Similar concepts to Flutter but different syntax
- Key components: Page, SilicaFlickable, PullDownMenu, Label, Slider
- Dark theme is native — fits THRIVES perfectly

---

## Audio on Sailfish
- Qt Multimedia — built in, no extra packages
- Good low-latency audio support
- Binaural beats and bilateral audio should work well

---

## Wearable Integration on Sailfish
- Limited compared to Android Health Connect
- Gadgetbridge works on Sailfish for some wearables
- May need custom BLE integration for biofeedback features

---

## Port Strategy
1. Ship Flutter MVP on Android + PWA first
2. Open GitHub issue for Sailfish native port
3. Sailfish community may contribute — they are active and technical
4. If no community contribution after 6 months, begin Qt/QML port
5. Reuse business logic — only UI layer needs rewriting

---

## Community
- talk.maemo.org — active Sailfish community
- Reddit: r/SailfishOS
- Announce there when Android version ships — gauge interest in native port
