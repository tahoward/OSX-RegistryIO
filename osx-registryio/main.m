//
//  main.m
//  osx-registryio
//
//  Created by Trevor Howard on 2/8/25.
//

#import <Foundation/Foundation.h>
#import "DisplayRegistry.h"
#import "IOServiceRegistry.h"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        // Prints entire IORegistry tree
        // displayRegistry(argc, argv);

        // First stab at resolving GPU voltage-states
        // Not very efficient as it loads several
        // unused IORegistryEntry objects and properties
        NSLog(@"%@", [IOHelper getDVFS:[[IOServiceRegistry alloc] init:@"AppleARMIODevice"][@"pmgr"]:@"voltage-states9"]);
        
        /* Sample Output
        {
            frequencyScale = (
                125,
                610,
                670,
                720,
                760,
                760,
                790,
                790,
                850,
                850,
                920,
                920,
                945,
                945
            );
            voltageScale = (
                0,
                338,
                618,
                796,
                832,
                924,
                952,
                1056,
                1064,
                1182,
                1182,
                1312,
                1242,
                1380
            );
        }
        */
    }

    return 0;
}
