//
//  GADMAdapterVungleUtils.h
//  Copyright © 2019 Google. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VungleSDK/VungleSDK.h>
#import "VungleAdNetworkExtras.h"

void GADMAdapterVungleMutableSetAddObject(NSMutableSet *_Nullable set, NSObject *_Nonnull object);

NS_ASSUME_NONNULL_BEGIN

@interface GADMAdapterVungleUtils : NSObject

+ (NSString *)findAppID:(NSDictionary *)serverParameters;
+ (NSString *)findPlacement:(NSDictionary *)serverParameters
              networkExtras:(VungleAdNetworkExtras *)networkExtras;

@end

NS_ASSUME_NONNULL_END
