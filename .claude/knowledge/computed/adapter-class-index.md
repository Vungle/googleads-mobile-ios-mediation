# Google Mobile Ads (GMA) — Vungle iOS Mediation Adapter Class Index

## Adapter Entry Point

| Class | Superclass | File |
|-------|-----------|------|
| `GADMediationAdapterVungle` | `NSObject <GADRTBAdapter>` | `GADMediationAdapterVungle.m` |

**Initialization**: `setUpWithConfiguration:completionHandler:` → calls `[VungleAds initWithAppId:]`
**Version**: `+adSDKVersion` returns Vungle SDK version, `+adapterVersion` returns adapter version

## Format Classes

| Format | Class | Google Protocol |
|--------|-------|----------------|
| Interstitial | `GADMAdapterVungleInterstitial` | `GADMediationInterstitialAd` |
| Rewarded | `GADMAdapterVungleRewardedAd` | `GADMediationRewardedAd` |
| Banner | `GADMAdapterVungleBanner` | `GADMediationBannerAd` |
| Bidding Interstitial | `GADMAdapterVungleBiddingInterstitial` | `GADMediationInterstitialAd` |
| Bidding Rewarded | `GADMAdapterVungleBiddingRewardedAd` | `GADMediationRewardedAd` |
| Bidding Banner | `GADMAdapterVungleBiddingBanner` | `GADMediationBannerAd` |

## Router Singleton

```
GADMAdapterVungleRouter.sharedInstance
  ├─ initWithAppId: (one-time initialization)
  ├─ requestInterstitialAdWithPlacementID:delegate:
  ├─ requestRewardedAdWithPlacementID:delegate:
  └─ requestBannerAdWithPlacementID:size:delegate:
```

The router manages ad lifecycle and delegates callbacks to the appropriate format adapter instance.

## Callback Mapping (Vungle → Google GMA)

| Vungle Callback | GMA Callback | Context |
|----------------|-------------|---------|
| `adDidLoad:` | `didLoadAd` (load callback) | Load success |
| `adDidFailToLoad:withError:` | `didFailToPresentError:` | Load failure |
| `adWillPresent:` | `willPresentFullScreenView` | About to show |
| `adDidTrackImpression:` | `reportImpression` | Impression tracked |
| `adDidClick:` | `reportClick` | Click |
| `adDidClose:` | `didDismissFullScreenView` | Fullscreen closed |
| `adDidRewardUser:` | `didEndVideo` + `didRewardUser` | Reward granted |

## Bidding Support

- Implements `GADRTBAdapter` protocol (extends `GADMediationAdapter`)
- `collectSignalsForRequestParameters:completionHandler:` → `[VungleAds getBiddingToken]`
- Separate bidding adapter classes handle RTB-specific load flow with bid payload

## Key Patterns

1. **Router singleton**: `GADMAdapterVungleRouter` centralizes ad lifecycle management, delegates to per-instance adapters
2. **Waterfall vs Bidding split**: Separate classes for waterfall (`GADMAdapterVungle*`) and bidding (`GADMAdapterVungleBidding*`) flows
3. **Error domain mapping**: Vungle errors mapped to `GADMAdapterVungleErrorDomain` with Google-standard codes
4. **Banner size mapping**: Google `GADAdSize` → Vungle banner size via helper method
5. **Server parameters**: App ID and placement ID from `GADMediationCredentials.settings` dictionary
6. **Privacy**: GDPR/CCPA/COPPA forwarded via `VunglePrivacySettings` from mediation extras
