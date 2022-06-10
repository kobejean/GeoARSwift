//
//  Tracking.h
//
//
//  Created by Jean Flaherty on 2021/12/26.
//

#pragma once

#if __APPLE__
    #include "TargetConditionals.h"
    #if TARGET_OS_IPHONE
        #import <ARKit/ARKit.h>
        #import <CoreLocation/CoreLocation.h>
    #endif
#endif

#ifdef __cplusplus
    #import <lar/mapping/mapper.h>
#endif

#import "LARMapperData.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LARMapper: NSObject

#ifdef __cplusplus
    @property(nonatomic,readonly) lar::Mapper* _internal;
#endif

@property(nonatomic,readonly) NSURL* directory;
@property(nonatomic,strong,readonly) LARMapperData* data;

- (id)initWithDirectory:(NSURL*)directory;

- (void)writeMetadata;

#if TARGET_OS_IPHONE
    - (void)addFrame:(ARFrame*)frame NS_SWIFT_NAME( add(frame:) );
    - (void)addPosition:(simd_float3)position timestamp:(NSDate*)timestamp NS_SWIFT_NAME( add(position:timestamp:) );
    - (void)addLocation:(CLLocation*)location  NS_SWIFT_NAME( add(location:) );
#endif

@end

NS_ASSUME_NONNULL_END
