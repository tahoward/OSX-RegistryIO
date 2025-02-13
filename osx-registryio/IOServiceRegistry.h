//
//  IOServiceRegistry.h
//  osx-registryio
//
//  Created by Trevor Howard on 2/8/25.
//

#import <Foundation/Foundation.h>

@interface IOHelper : NSObject
+ (NSDictionary *_Nonnull)getDVFS:(NSDictionary *_Nullable)registryProperties :(NSString *_Nullable)key;
@end

@interface IOServiceRegistry : NSObject <NSFastEnumeration> {
    NSMutableDictionary<NSString *, NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> * > *> *_registryPropertiesMap;
}

@property (readonly) NSDictionary *_Nonnull service;

- (id _Nullable)init:(NSString *_Nullable)serviceName;
- (NSDictionary *_Nullable)objectForKey:(NSString *_Nullable)key;
- (NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *_Nullable)objectForKeyedSubscript:(NSString *_Nullable)key;
- (NSArray<NSString *> *_Nonnull)allKeys;
- (NSArray<NSDictionary<NSString *, NSDictionary<NSString *, NSDictionary *> *> *> *_Nonnull)allValues;
- (NSEnumerator<NSString *> *_Nonnull)keyEnumerator;
- (NSUInteger)count;
- (NSString *_Nonnull)description;
@end
