#import <Foundation/Foundation.h>
@import GoogleMobileAds;

@interface GADMAdapterVungleRewardedAd : NSObject <GADMediationRewardedAd>

- (instancetype)initWithAdConfiguration:(GADMediationRewardedAdConfiguration *)adConfiguration
                      completionHandler:(GADRewardedLoadCompletionHandler)handler;
- (instancetype)init NS_UNAVAILABLE;

- (void)requestRewardedAd;

@end
