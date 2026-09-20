# FridgeCig

Track every Diet Coke. FridgeCig turns a small daily habit into streaks, badges, and a bit of
friendly competition with friends — on iPhone, Apple Watch, and the home screen.

📱 **[Download on the App Store](https://apps.apple.com/us/app/fridgecig/id6757887069)**

## Features

- **One-tap logging** from the app, a widget, the Apple Watch, or a Siri shortcut
- **Streaks and badges** that reward consistency rather than volume
- **Friends and leaderboards** — compare counts with people you actually know
- **Watch app and complications** so logging never needs the phone
- **Home screen widgets** showing today's count at a glance

## Tech

| Area | Stack |
|---|---|
| UI | SwiftUI |
| Watch | watchOS app + complications, WatchConnectivity |
| Widgets | WidgetKit |
| System integration | App Intents (Siri & Shortcuts), UserNotifications |
| Sync | CloudKit |
| Health | HealthKit |
| Monetization | StoreKit 2, RevenueCat |
| Analytics | TelemetryDeck |

## Repository layout

```
DietCokeTracker/             Main iOS app
DietCokeWatch Watch App/     watchOS companion
DietCokeWatchWidget/         Watch complications
DietCokeWidget/              iOS home screen widgets
scripts/, .aso-tools/        App Store screenshot & ASO tooling
docs/                        Supporting documentation
```

## Notes

Published to show how the app is built; the App Store release is the supported way to use FridgeCig.
