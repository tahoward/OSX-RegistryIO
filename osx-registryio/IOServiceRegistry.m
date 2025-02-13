//
//  IOServiceRegistry.m
//  osx-registryio
//
//  Created by Trevor Howard on 2/8/25.
//

#import <CoreFoundation/CoreFoundation.h>
#import <math.h>
#import "IOServiceRegistry.h"

#define VOLTAGE_STATES  @"voltage-states"
#define VOLTAGE_SCALE   @"voltageScale"
#define FREQUENCY_SCALE @"frequencyScale"

@implementation IOHelper

+ (NSArray *)chunkData:(NSData *_Nullable)data :(NSUInteger)chunkSize {
    NSMutableArray *chunkArray = [[NSMutableArray alloc] init];
    NSUInteger length = [data length];
    NSUInteger offset = 0;

    do {
        NSUInteger thisChunkSize =
            length - offset > chunkSize ? chunkSize : length - offset;
        NSData *chunk =
            [NSData dataWithBytesNoCopy:(char *)[data bytes] + offset
                                 length:thisChunkSize
                           freeWhenDone:NO];

        offset += thisChunkSize;
        [chunkArray addObject:chunk];
    } while (offset < length);

    return chunkArray;
}

+ (NSDictionary<NSString *, NSArray *> *)getDVFS:(NSDictionary *)registryProperties :(NSString *)key {
    UInt32 voltage;
    UInt32 frequency;
    NSData *data = [registryProperties objectForKey:key];
    NSMutableArray<NSNumber *> *voltageScale = [[NSMutableArray alloc] init];
    NSMutableArray<NSNumber *> *frequencyScale = [[NSMutableArray alloc] init];
    NSDictionary<NSString *, NSArray<NSNumber *> *> *dvfs = @{
            VOLTAGE_SCALE: voltageScale, FREQUENCY_SCALE: frequencyScale
    };

    if (!data || ![key hasPrefix:VOLTAGE_STATES]) {
        return NULL;
    }

    for (NSData *byteData in [IOHelper chunkData:data:8]) {
        NSArray *splitDataArray = [IOHelper chunkData:byteData:4];
        voltage = *(UInt32 *)([splitDataArray[0] bytes]) * 1e-6;
        [voltageScale addObject:[NSNumber numberWithUnsignedInt:voltage]];

        if (1 < splitDataArray.count) {
            frequency = *(UInt32 *)([splitDataArray[1] bytes]);
            [frequencyScale addObject:[NSNumber numberWithUnsignedInt:frequency]];
        }
    }

    return dvfs;
}

@end

@implementation IOServiceRegistry

- (id _Nullable)init:(NSString *)serviceName {
    if (self = [super init]) {
        io_iterator_t entryIterator;
        io_registry_entry_t registryEntry;
        CFDictionaryRef service = IOServiceMatching(serviceName.UTF8String);

        CFAllocatorRef serviceCopy;
        CFDictionaryCreateCopy(serviceCopy, service);
        _service = CFBridgingRelease(serviceCopy);

        IOServiceGetMatchingServices(0, service, &entryIterator);
        _registryPropertiesMap = [[NSMutableDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> * > *> alloc] init];

        while ((registryEntry = IOIteratorNext(entryIterator)))
            [self mapRegistryEntry:registryEntry];
        ;

        return self;
    } else {
        return NULL;
    }
}

- (void)mapRegistryEntry:(io_registry_entry_t)registryEntry {
    char *nameBuffer = malloc(128);
    CFMutableDictionaryRef serviceDictionaryRef;

    IORegistryEntryGetName(registryEntry, nameBuffer);

    if (IORegistryEntryCreateCFProperties(registryEntry, &serviceDictionaryRef, 0,
                                          0) == kIOReturnSuccess) {
        id _Nullable serviceDictionary = CFBridgingRelease(serviceDictionaryRef);
        [_registryPropertiesMap
         setValue:serviceDictionary
           forKey:[NSString stringWithUTF8String:nameBuffer]];
    }
}

- (NSUInteger)
    countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state
                        objects:
    (__unsafe_unretained id _Nullable *_Nonnull)buffer
                          count:(NSUInteger)len {
    return [_registryPropertiesMap countByEnumeratingWithState:state
                                                       objects:buffer
                                                         count:len];
}

- (NSMutableDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *> *)getRegistryPropertiesMap {
    return _registryPropertiesMap;
}

- (NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *_Nullable)objectForKey:(NSString *)key {
    return _registryPropertiesMap[key];
}

- (NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *_Nullable)objectForKeyedSubscript:(NSString *)key {
    return _registryPropertiesMap[key];
}

- (NSArray<NSString *> *)allKeys {
    return [_registryPropertiesMap allKeys];
}

- (NSArray<NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *> *)allValues {
    return [_registryPropertiesMap allValues];
}

- (NSEnumerator<NSString *> *)keyEnumerator {
    return [_registryPropertiesMap keyEnumerator];
}

- (NSUInteger)count {
    return [_registryPropertiesMap count];
}

- (NSString *)description {
    return [_registryPropertiesMap description];
}

@end
