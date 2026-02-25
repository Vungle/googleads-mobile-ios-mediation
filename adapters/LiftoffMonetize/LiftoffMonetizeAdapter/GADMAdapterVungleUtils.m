// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "GADMAdapterVungleUtils.h"
#import "GADMAdapterVungleConstants.h"

#import <VungleAdsSDK/VungleAdsSDK.h>

NSError *_Nonnull GADMAdapterVungleErrorWithCodeAndDescription(GADMAdapterVungleErrorCode code,
                                                               NSString *_Nonnull description) {
  NSDictionary<NSString *, NSString *> *userInfo =
      @{NSLocalizedDescriptionKey : description, NSLocalizedFailureReasonErrorKey : description};
  NSError *error = [NSError errorWithDomain:GADMAdapterVungleErrorDomain
                                       code:code
                                   userInfo:userInfo];
  return error;
}

VungleAdSize *_Nonnull GADMAdapterVungleConvertGADAdSizeToVungleAdSize(
    GADAdSize adSize, NSString *_Nonnull placementId) {
  return [VungleAdSize VungleValidAdSizeFromCGSizeWithSize:adSize.size placementId:placementId];
}

@implementation GADMAdapterVungleUtils

+ (nonnull NSString *)findAppID:(nullable NSDictionary *)serverParameters {
  NSString *appId = serverParameters[GADMAdapterVungleApplicationID];
  if (!appId) {
    NSString *const message = @"Liftoff Monetize app ID should be specified!";
    NSLog(message);
    return @"";
  }
  return appId;
}

+ (nonnull NSString *)findPlacement:(nullable NSDictionary *)serverParameters {
  NSString *placementId = serverParameters[GADMAdapterVunglePlacementID];
  return placementId ? placementId : @"";
}

+ (void)updateVungleCOPPAStatusIfNeeded {
  NSNumber *tagForChildDirectedTreatment =
      GADMobileAds.sharedInstance.requestConfiguration.tagForChildDirectedTreatment;
  NSNumber *tagForUnderAgeOfConsent =
      GADMobileAds.sharedInstance.requestConfiguration.tagForUnderAgeOfConsent;
  if ([tagForChildDirectedTreatment isEqual:@YES] || [tagForUnderAgeOfConsent isEqual:@YES]) {
    [VunglePrivacySettings setCOPPAStatus:YES];
  } else if ([tagForChildDirectedTreatment isEqual:@NO] || [tagForUnderAgeOfConsent isEqual:@NO]) {
    [VunglePrivacySettings setCOPPAStatus:NO];
  }
}

+ (void)logCustomSizeForBannerPlacement:(NSString *_Nonnull)placementId
                                 adSize:(GADAdSize)adSize
                           bannerViewAd:(VungleBannerView *_Nullable)adViewAd {
  // For dev, will remove
  NSString *adSizeName = nil;
  if (GADAdSizeEqualToSize(adSize, GADAdSizeBanner)) {
    adSizeName = @"GADAdSizeBanner (320x50)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeLargeBanner)) {
    adSizeName = @"GADAdSizeLargeBanner (320x100)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle)) {
    adSizeName = @"GADAdSizeMediumRectangle (300x250)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeFullBanner)) {
    adSizeName = @"GADAdSizeFullBanner (468x60)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeLeaderboard)) {
    adSizeName = @"GADAdSizeLeaderboard (728x90)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeSkyscraper)) {
    adSizeName = @"GADAdSizeSkyscraper (120x600)";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeFluid)) {
    adSizeName = @"GADAdSizeFluid";
  } else if (GADAdSizeEqualToSize(adSize, GADAdSizeInvalid)) {
    adSizeName = @"GADAdSizeInvalid";
  } else {
    NSLog(@"--->>> [VungleAdapter] logCustomSizeForBannerPlacement: placementId=%@ adSize=%@ (adaptive/custom)",placementId, NSStringFromGADAdSize(adSize));
  }
  NSLog(@"--->>> [VungleAdapter] logCustomSizeForBannerPlacement: placementId=%@ adSize=%@",placementId, adSizeName);
  // For dev, will remove ---<<<

  if (!GADAdSizeEqualToSize(adSize, GADAdSizeBanner) &&           // 320x50
      !GADAdSizeEqualToSize(adSize, GADAdSizeLargeBanner) &&      // 320x100 // need to exclude?
      !GADAdSizeEqualToSize(adSize, GADAdSizeMediumRectangle) &&  // 300x250
      !GADAdSizeEqualToSize(adSize, GADAdSizeFullBanner) &&       // 468x60  // need to exclude?
      !GADAdSizeEqualToSize(adSize, GADAdSizeLeaderboard) &&      // 728x90
      !GADAdSizeEqualToSize(adSize, GADAdSizeSkyscraper) &&       // 120x600 // need to exclude?
      !GADAdSizeEqualToSize(adSize, GADAdSizeFluid) &&            // fluid (dynamic height) // need to exclude?
      ![VungleAdSize VungleValidAdSizeFromCGSizeWithSize:adSize.size placementId:placementId]) {
    // Not a standard size — GADAdSizeInvalid or custom size
    adViewAd.adapterAdFormat = @"GADMediationVungleBanner-custom";
    NSString *adaptiveSizeMessage = [NSString stringWithFormat:@"CustomBannerSizeMismatch:w-%.0f|h-%.0f",
                                     adSize.size.width,
                                     adSize.size.height];
    [VungleMediationLogger logErrorForAd:adViewAd message:adaptiveSizeMessage];

    NSLog(@"Please use a Liftoff inline placement ID in order to use custom size banner: placementId=%@ adSize=%@",
          placementId, NSStringFromGADAdSize(adSize));
  }
}

#pragma mark - Safe Collection utility methods.

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object) {
  if (object) {
    [set addObject:object];  // Allow pattern.
  }
}

@end
