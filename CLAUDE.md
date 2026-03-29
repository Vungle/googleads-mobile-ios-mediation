# Google Ads Mobile iOS Mediation

## Overview
Google-maintained iOS mediation adapters for the Google Mobile Ads SDK. Contains 18 third-party network adapters enabling mediation through AdMob/Ad Manager.

## Language
- **Objective-C** (100% for adapters)

## Build System
- **Xcode projects** for adapter builds
- **xcframework build scripts** for multi-architecture distribution
- **CocoaPods** for example app dependencies

## Architecture
- Directory structure: `adapters/{Network}/{Network}Adapter/`
- Main adapter class: `GADMediation{Network}Adapter`
- Router pattern: Centralized SDK lifecycle management via shared Router class
- Format-specific classes for banner, interstitial, rewarded
- Bidding support via separate bidding adapter classes

## Vungle Adapter
- Main class: `GADMediationAdapterVungle`
- Supporting: Banner, Interstitial, Rewarded format classes + Router + Utils
- Bidding support with signal collection
- Consent handling integration

## Ad Formats
- Banner
- Interstitial
- Rewarded Video
- Bidding variants of each format

## Code Standards
- Early return pattern
- GCD for threading (`dispatch_async`, `dispatch_get_main_queue`)
- Nullability annotations (`nullable`, `nonnull`)

## Example App
- `MediationExample` app for manual testing

## Key Conventions
- Router class per adapter for shared SDK state
- Separate classes for bidding vs. waterfall
- Format-specific delegate/callback classes
- Utils class for shared helper methods
