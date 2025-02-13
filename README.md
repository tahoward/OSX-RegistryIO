# OSX-RegistryIO

Repository for exploring OSX IORegistry

## IOServiceRegistry

Module for traversing IORegistry using keys:

Example of returning `pmgr` properties under the `AppleARMIODevice` registry:
```objective-c
NSDictionary * pmgrProperties = [IOServiceRegistry alloc] init:@"AppleARMIODevice"][@"pmgr"]
```

Example of parsing voltage states from `voltage-states9`(GPU) property in `pmgr` entry:
```objective-c
NSLog(@"%@", [IOHelper getDVFS:[[IOServiceRegistry alloc] init:@"AppleARMIODevice"][@"pmgr"]:@"voltage-states9"]);

```
