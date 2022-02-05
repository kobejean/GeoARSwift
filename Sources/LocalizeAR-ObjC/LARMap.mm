//
//  LARMap.mm
//  
//
//  Created by Jean Flaherty on 2021/12/26.
//

#import <iostream>
#import <fstream>
#import "lar/core/utils/json.h"

#import "Helpers/LARConversion.h"
#import "LARMap.h"

@interface LARMap ()

@property(nonatomic,readwrite) lar::Map* _internal;

@end

@implementation LARMap

- (id)initWithContentsOf:(NSString*)filepath {
    self = [super init];
    nlohmann::json json = nlohmann::json::parse(std::ifstream([filepath UTF8String]));
    lar::Map* map = new lar::Map();
    lar::from_json(json, *map);
    self._internal = map;
    return self;
}

- (bool)globalPointFrom:(simd_double3)relative global:(simd_double3*) global {
    Eigen::Vector3d _relative = [LARConversion vector3dFromSIMD3:relative];
    Eigen::Vector3d _global;
    bool success = self._internal->globalPointFrom(_relative, _global);
    *global = [LARConversion simd3FromVector3d:_global];
    return success;
}

- (bool)relativePointFrom:(simd_double3)global relative:(simd_double3*) relative {
    Eigen::Vector3d _global = [LARConversion vector3dFromSIMD3:global];
    Eigen::Vector3d _relative;
    bool success = self._internal->relativePointFrom(_global, _relative);
    *relative = [LARConversion simd3FromVector3d:_relative];
    return success;
}

- (id)initWithInternal:(lar::Map*)map {
    self = [super init];
    self._internal = map;
    return self;
}

- (NSArray<LARLandmark*>*)landmarks {
    int size = (int)self._internal->landmarks.size();
    NSMutableArray<LARLandmark *> *landmarks = [[NSMutableArray<LARLandmark*> alloc] initWithCapacity: size];
    for (int i=0; i<size; i++) {
        LARLandmark *landmark = [[LARLandmark alloc] initWithInternal: &self._internal->landmarks[i]];
        [landmarks addObject: landmark];
    }
    return [landmarks copy];
}

@end
