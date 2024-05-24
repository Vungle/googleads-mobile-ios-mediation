// Copyright 2020 Google LLC
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

#import "GADMAdapterVungleBanner.h"
#import "GADMAdapterVungleRouter.h"
#import "GADMAdapterVungleUtils.h"

@interface GADMAdapterVungleBanner () <GADMAdapterVungleDelegate, VungleBannerViewDelegate>
@end

@implementation GADMAdapterVungleBanner {
  /// Connector from Google Mobile Ads SDK to receive ad configurations.
  __weak id<GADMAdNetworkConnector> _connector;

  /// Adapter for receiving ad request notifications.
  __weak id<GADMAdNetworkAdapter> _adapter;

  /// The requested ad size.
  GADAdSize _bannerSize;

  /// Liftoff Monetize bannerView ad instance.
  VungleBannerView *_bannerAdView;
}

@synthesize desiredPlacement;

- (nonnull instancetype)initWithGADMAdNetworkConnector:(nonnull id<GADMAdNetworkConnector>)connector
                                               adapter:(nonnull id<GADMAdNetworkAdapter>)adapter {
  self = [super init];
  if (self) {
    _adapter = adapter;
    _connector = connector;
  }
  return self;
}

- (void)dealloc {
  _adapter = nil;
  _connector = nil;
  _bannerAdView = nil;
}

- (void)getBannerWithSize:(GADAdSize)adSize {
  id<GADMAdNetworkConnector> strongConnector = _connector;
  id<GADMAdNetworkAdapter> strongAdapter = _adapter;
  if (!strongConnector || !strongAdapter) {
    return;
  }

  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]];
  _bannerSize = adSize;
  if ([VungleAds isInitialized]) {
    [self loadAd];
    return;
  }

  NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
  [GADMAdapterVungleRouter.sharedInstance initWithAppId:appID delegate:self];
}

- (void)loadAd {
  _bannerAdView = [[VungleBannerView alloc]
      initWithPlacementId:self.desiredPlacement
             vungleAdSize:GADMAdapterVungleConvertGADAdSizeToVungleAdSize(_bannerSize, self.desiredPlacement)];

  _bannerAdView.delegate = self;
  // Pass nil for the payload because this is not bidding
  [_bannerAdView load:nil];
}

#pragma mark - VungleBannerViewDelegate

- (void)bannerAdDidLoad:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidFail:(VungleBannerView *)bannerView withError:(NSError *)withError {
  [_connector adapter:_adapter didFailAd:withError];
}

- (void)bannerAdWillPresent:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidPresent:(VungleBannerView *)bannerView {
  [_connector adapter:_adapter didReceiveAdView:bannerView];
}

- (void)bannerAdWillClose:(VungleBannerView *)bannerView {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewWillDismissScreen:.
}

- (void)bannerAdDidClose:(VungleBannerView *)bannerView {
  // This callback is fired when the banner itself is destroyed/removed, not when the user returns
  // to the app screen after clicking on an ad. Do not map to adViewDidDismissScreen:.
}

- (void)bannerAdDidTrackImpression:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

- (void)bannerAdDidClick:(VungleBannerView *)bannerView {
  [_connector adapterDidGetAdClick:_adapter];
}

- (void)bannerAdWillLeaveApplication:(VungleBannerView *)bannerView {
  // Google Mobile Ads SDK doesn't have a matching event.
}

#pragma mark - GADMAdapterVungleDelegate delegates

- (void)initialized:(BOOL)isSuccess error:(nullable NSError *)error {
  if (!isSuccess) {
    [_connector adapter:_adapter didFailAd:error];
    return;
  }
  [self loadAd];
}

@end
