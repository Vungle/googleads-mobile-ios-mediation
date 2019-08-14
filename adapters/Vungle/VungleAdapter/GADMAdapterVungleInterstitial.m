#import "GADMAdapterVungleInterstitial.h"
#import <GoogleMobileAds/Mediation/GADMAdNetworkConnectorProtocol.h>
#import "GADMAdapterVungleConstants.h"
#import "GADMAdapterVungleUtils.h"
#import "VungleRouter.h"

@interface GADMAdapterVungleInterstitial ()<VungleDelegate>
@property(nonatomic, weak) id<GADMAdNetworkConnector> connector;
@property(nonatomic, assign) CGSize bannerSize;
@end

@implementation GADMAdapterVungleInterstitial

// To check if the ad is presenting so that we don't call 'adapterDidReceiveInterstitial:' twice.
static BOOL _isAdPresenting;

+ (NSString *)adapterVersion {
  return kGADMAdapterVungleVersion;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
  return [VungleAdNetworkExtras class];
}

- (instancetype)initWithGADMAdNetworkConnector:(id<GADMAdNetworkConnector>)connector {
  self = [super init];
  if (self) {
    self.connector = connector;
    self.adapterAdType = Unknown;
  }
  return self;
}

- (void)dealloc {
  [self stopBeingDelegate];
}

#pragma mark - GAD Ad Network Protocol Banner Methods (MREC)

- (void)getBannerWithSize:(GADAdSize)adSize {
  // Check if given banner size is in MREC or Banner.
  if (!CGSizeEqualToSize(adSize.size, kGADAdSizeMediumRectangle.size) && !CGSizeEqualToSize(adSize.size, kGADAdSizeBanner.size) && !CGSizeEqualToSize(adSize.size, kVGNBannerShortSize) && !CGSizeEqualToSize(adSize.size, kGADAdSizeLeaderboard.size)) {
    NSError *error = [NSError
        errorWithDomain:kGADMAdapterVungleErrorDomain
                   code:0
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Vungle only supports banner ad size in 300 x 250, 320 x 50, 300 x 50 and 728 x 90."
               }];
    [self.connector adapter:self didFailAd:error];
    return;
  }
    
    self.bannerSize = adSize.size;
    if (CGSizeEqualToSize(adSize.size, kGADAdSizeMediumRectangle.size)) {
        self.adapterAdType = MREC;
    } else if (CGSizeEqualToSize(adSize.size, kGADAdSizeBanner.size)) {
        self.adapterAdType = Banner;
    } else if (CGSizeEqualToSize(adSize.size, kVGNBannerShortSize)) {
        self.adapterAdType = ShortBanner;
    } else if (CGSizeEqualToSize(adSize.size, kGADAdSizeLeaderboard.size)) {
        self.adapterAdType = LeaderboardBanner;
    }

  id<GADMAdNetworkConnector> strongConnector = self.connector;
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];

  if (!self.desiredPlacement) {
    [strongConnector
          adapter:self
        didFailAd:[NSError errorWithDomain:@"GADMAdapterVungleBanner"
                                      code:0
                                  userInfo:@{
                                    NSLocalizedDescriptionKey : @"'placementID' not specified"
                                  }]];
    return;
  }

  // Check if a banner or MREC ad has been initiated with the samne PlacementID
  // or not. (Vungle supports only one banner currently.)
  if (![[VungleRouter sharedInstance] canRequestBannerAdForPlacementID:self.desiredPlacement withBannerType:self.adapterAdType]) {
    NSError *error =
        [NSError errorWithDomain:@"google"
                            code:0
                        userInfo:@{
                          NSLocalizedDescriptionKey : @"A banner ad type has been already "
                                                      @"instanciated. Multiple banner ads are not "
                                                      @"supported with Vungle iOS SDK."
                        }];
    [self.connector adapter:self didFailAd:error];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
    if (appID) {
      GADMAdapterVungleInterstitial *__weak weakSelf = self;
      [[VungleRouter sharedInstance] initWithAppId:appID delegate:weakSelf];
    } else {
      NSError *error =
          [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                              code:0
                          userInfo:@{NSLocalizedDescriptionKey : @"Vungle app ID not specified!"}];
      [strongConnector adapter:self didFailAd:error];
    }
  } else {
    [self loadAd];
  }
}

#pragma mark - GAD Ad Network Protocol Interstitial Methods

- (void)getInterstitial {
  self.adapterAdType = Interstitial;
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  self.desiredPlacement = [GADMAdapterVungleUtils findPlacement:[strongConnector credentials]
                                                  networkExtras:[strongConnector networkExtras]];
  if (!self.desiredPlacement) {
    [strongConnector
          adapter:self
        didFailAd:[NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                                      code:0
                                  userInfo:@{
                                    NSLocalizedDescriptionKey : @"'placementID' not specified"
                                  }]];
    return;
  }

  VungleSDK *sdk = [VungleSDK sharedSDK];
  if ([[VungleRouter sharedInstance] hasDelegateForPlacementID:self.desiredPlacement
                                                   adapterType:Interstitial]) {
    NSError *error = [NSError
        errorWithDomain:@"GADMAdapterVungleInterstitial"
                   code:0
               userInfo:@{
                 NSLocalizedDescriptionKey : @"Vungle SDK does not support multiple concurrent ads "
                                             @"load for Interstitial ad type."
               }];

    [self.connector adapter:self didFailAd:error];
    return;
  }

  if (![sdk isInitialized]) {
    NSString *appID = [GADMAdapterVungleUtils findAppID:[strongConnector credentials]];
    if (appID) {
      GADMAdapterVungleInterstitial *__weak weakSelf = self;
      [[VungleRouter sharedInstance] initWithAppId:appID delegate:weakSelf];
    } else {
      NSError *error =
          [NSError errorWithDomain:kGADMAdapterVungleErrorDomain
                              code:0
                          userInfo:@{NSLocalizedDescriptionKey : @"Vungle app ID not specified!"}];
      [strongConnector adapter:self didFailAd:error];
    }
  } else {
    [self loadAd];
  }
}

- (void)stopBeingDelegate {
  if ([self isBannerAd]) {
    [[VungleRouter sharedInstance] completeBannerAdViewForPlacementID:self.desiredPlacement];
    self.connector = nil;
    [[VungleRouter sharedInstance] removeDelegate:self];
  } else if (self.adapterAdType == Interstitial) {
    self.connector = nil;
    [[VungleRouter sharedInstance] removeDelegate:self];
  }
}

- (BOOL)isBannerAnimationOK:(GADMBannerAnimationType)animType {
  return YES;
}

- (void)presentInterstitialFromRootViewController:(UIViewController *)rootViewController {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  if (![[VungleRouter sharedInstance] playAd:rootViewController
                                    delegate:self
                                      extras:[strongConnector networkExtras]]) {
    [strongConnector adapterDidDismissInterstitial:self];
  }
  _isAdPresenting = YES;
}

#pragma mark - Private methods

- (void)loadAd {
  NSError *error = [[VungleRouter sharedInstance] loadAd:self.desiredPlacement withDelegate:self];
  if (error) {
    [self.connector adapter:self didFailAd:error];
  }
}

- (void)connectAdViewToViewController {
  UIView *bannerView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, _bannerSize.width, _bannerSize.height)];
  bannerView = [[VungleRouter sharedInstance] renderBannerAdInView:bannerView
                                                          delegate:self
                                                            extras:[self.connector networkExtras]
                                                    forPlacementID:self.desiredPlacement];
  if (bannerView) {
    self.bannerState = BannerRouterDelegateStatePlaying;
    [self.connector adapter:self didReceiveAdView:bannerView];
  } else {
    [self.connector
          adapter:self
        didFailAd:[NSError
                      errorWithDomain:@"GADMAdapterVungleBanner"
                                 code:0
                             userInfo:@{NSLocalizedDescriptionKey : @"Error in creating adView"}]];
  }
}

- (BOOL)isBannerAd {
    if (self.adapterAdType == MREC || self.adapterAdType == Banner || self.adapterAdType == ShortBanner || self.adapterAdType == LeaderboardBanner) {
        return YES;
    }
    return NO;
}

#pragma mark - VungleRouter delegates

@synthesize desiredPlacement;
@synthesize adapterAdType;
@synthesize bannerState;

- (void)initialized:(BOOL)isSuccess error:(NSError *)error {
  if (isSuccess && self.desiredPlacement) {
    [self loadAd];
  } else {
    [self.connector adapter:self didFailAd:error];
  }
}

- (void)adAvailable {
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateCached;
    [self connectAdViewToViewController];
  } else if (self.adapterAdType == Interstitial) {
    [self.connector adapterDidReceiveInterstitial:self];
  }
}

- (void)adNotAvailable:(NSError *)error {
  [self.connector adapter:self didFailAd:error];
}

- (void)willShowAd {
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStatePlaying;
  } else if (self.adapterAdType == Interstitial) {
    [self.connector adapterWillPresentInterstitial:self];
  }
}

- (void)willCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  id<GADMAdNetworkConnector> strongConnector = self.connector;
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateClosing;
    if (didDownload) {
      if (strongConnector) {
        [strongConnector adapterDidGetAdClick:self];
        [strongConnector adapterWillLeaveApplication:self];
      }
    }
  } else if (self.adapterAdType == Interstitial) {
    if (didDownload) {
      [strongConnector adapterDidGetAdClick:self];
      [strongConnector adapterWillLeaveApplication:self];
    }
    [strongConnector adapterWillDismissInterstitial:self];
    _isAdPresenting = NO;
  }
}

- (void)didCloseAd:(BOOL)completedView didDownload:(BOOL)didDownload {
  if ([self isBannerAd]) {
    self.bannerState = BannerRouterDelegateStateClosed;
  } else if (self.adapterAdType == Interstitial) {
    [self.connector adapterDidDismissInterstitial:self];
    self.desiredPlacement = nil;
  }
}

@end
