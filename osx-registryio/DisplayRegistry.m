//
//  DisplayRegistry.m
//  osx-registryio
//
//  Created by Trevor Howard on 2/13/25.
//
//  Source: https://github.com/opensource-apple/IOKitUser/blob/master/iodisplayregistry.c
//

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOCFSerialize.h>
#include <IOKit/IOKitLib.h>

static void indent(Boolean node, int depth, UInt64 stackOfBits);
static void properties(io_registry_entry_t service,
                       int                 depth,
                       UInt64              stackOfBits);
static void traverse(unsigned int options,
                     io_name_t plane, io_iterator_t services,
                     io_registry_entry_t first,
                     int depth, UInt64 stackOfBits);

enum {
    kDoPropsOption = 1,
    kDoRootOption  = 2
};

void displayRegistry(int argc, const char *argv[]) {
    io_registry_entry_t root;
    char *plane;
    unsigned int options;
    int arg;

    // Parse args

    plane = kIOServicePlane;
    options = kDoPropsOption;

    for (arg = 1; arg < argc; arg++) {
        if ('-' == argv[arg][0]) {
            switch (argv[arg][1]) {
                case 'h':
                    printf("%s [-p] [-r] [-h] [plane]\n", argv[0]);
                    exit(0);
                    break;

                case 'p':
                    options &= ~kDoPropsOption;
                    break;

                case 'r':
                    options |= kDoRootOption;
                    break;
            }
        } else {
            plane = argv[arg];
        }
    }

    // Obtain the registry root entry.
    root = IORegistryGetRootEntry(kIOMainPortDefault);
    assert(root);

    // Traverse below the root in the plane.
    traverse(options, plane, 0, root, 0, 0);
}

struct indent_ctxt {
    int depth;
    UInt64 stackOfBits;
};

void traverse(unsigned int options,
              io_name_t plane, io_iterator_t services,
              io_registry_entry_t serviceUpNext,
              int depth, UInt64 stackOfBits) {
    io_registry_entry_t service;
    Boolean doProps;

    // We loop for every service in the list of services provided.
    while ( (service = serviceUpNext) ) {
        io_iterator_t children;
        Boolean hasChildren;
        io_name_t name;
        kern_return_t status;
        io_registry_entry_t child;
        UInt busy;

        // Obtain the next service entry, if any.
        serviceUpNext = IOIteratorNext(services);

        // Obtain the current service entry's children, if any.
        status = IORegistryEntryGetChildIterator(service,
                                                 plane,
                                                 &children);
        assert(status == KERN_SUCCESS);

        child = IOIteratorNext(children); ///ok
        hasChildren = child ? true : false;

        // Save has-more-siblings state into stackOfBits for this depth.
        if (serviceUpNext) {
            stackOfBits |=  (1 << depth);
        } else {
            stackOfBits &= ~(1 << depth);
        }

        // Save has-children state into stackOfBits for this depth.
        if (hasChildren) {
            stackOfBits |=  (2 << depth);
        } else {
            stackOfBits &= ~(2 << depth);
        }

        indent(true, depth, stackOfBits);

        // Print out the name of the service.
        status = IORegistryEntryGetName(service, name);
        assert(status == KERN_SUCCESS);

        printf("%s", name);

        if (strcmp("Root", name)) {
            doProps = (options & kDoPropsOption) != 0;
        } else {
            doProps = (options & kDoRootOption) != 0;
        }

        // Print out the class of the service.
        status = IOObjectGetClass(service, name);
        assert(status == KERN_SUCCESS);
        printf("  <class %s", name);

        status = IOServiceGetBusyState(service, &busy);

        if (status == KERN_SUCCESS) {
            printf(", busy %d", busy);
        }

        // Print out the retain count of the service.
        printf(", retain count %d>\n", IOObjectGetRetainCount(service));

        // Print out the properties of the service.
        if (doProps) {
            properties(service, depth, stackOfBits);
        }

        // Recurse down.
        traverse(options, plane, children, child, depth + 1, stackOfBits);

        // Release resources.
        IOObjectRelease(children); children = 0;
        IOObjectRelease(service);  service = 0;
    }
}

static void printCFString(CFStringRef string) {
    CFIndex len;
    char *buffer;

    len = CFStringGetMaximumSizeForEncoding(CFStringGetLength(string),
                                            CFStringGetSystemEncoding()) + sizeof('\0');
    buffer = malloc(len);

    if (buffer && CFStringGetCString(string, buffer, len,
                                     CFStringGetSystemEncoding()) ) {
        printf("%s", buffer);
    }

    if (buffer) {
        free(buffer);
    }
}

static void printEntry(const void *key, const void *value, void *context) {
    struct indent_ctxt *ctxt = context;

#if 1
    // IOKit pretty
    CFDataRef data;

    indent(false, ctxt->depth, ctxt->stackOfBits);
    printf("  ");
    printCFString( (CFStringRef)key);
    printf(" = ");

    data = IOCFSerialize((CFStringRef)value, kNilOptions);

    if (data) {
        if (10000 > CFDataGetLength(data)) {
            printf("%s", CFDataGetBytePtr(data));
        } else {
            printf("<is BIG>");
        }

        CFRelease(data);
    } else {
        printf("<IOCFSerialize failed>");
    }

    printf("\n");

#else  /* if 1 */
    // CF ugly
    CFStringRef keyStr = (CFStringRef)key;
    CFStringRef valueStr = CFCopyDescription((CFTypeRef)val);
    CFStringRef outStr;

    indent(false, ctxt->depth, ctxt->stackOfBits);
    outStr = CFStringCreateWithFormat(kCFAllocatorDefault, 0,
                                      CFSTR("  %@ = %@\n"), keyStr, valueStr);
    assert(outStr);
    printCFString(outStr);
    CFRelease(valueStr);
    CFRelease(outStr);
#endif /* if 1 */
}

static void properties(io_registry_entry_t service,
                       int                 depth,
                       UInt64              stackOfBits) {
    CFMutableDictionaryRef dictionary;
    kern_return_t status;
    struct indent_ctxt context;

    context.depth = depth;
    context.stackOfBits = stackOfBits;

    // Prepare to print out the service's properties.
    indent(false, context.depth, context.stackOfBits);
    printf("{\n");

    // Obtain the service's properties.
    status = IORegistryEntryCreateCFProperties(service,
                                               &dictionary,
                                               kCFAllocatorDefault, kNilOptions);
    assert(KERN_SUCCESS == status);
    assert(CFDictionaryGetTypeID() == CFGetTypeID(dictionary));

    CFDictionaryApplyFunction(dictionary,
                              (CFDictionaryApplierFunction)printEntry, &context);

    CFRelease(dictionary);

    indent(false, context.depth, context.stackOfBits);
    printf("}\n");
    indent(false, context.depth, context.stackOfBits);
    printf("\n");
}

void indent(Boolean node, int depth, UInt64 stackOfBits) {
    int i;

    // stackOfBits representation, given current depth is n:
    //   bit n+1             = does depth n have children?       1=yes, 0=no
    //   bit [n, .. i .., 0] = does depth i have more siblings?  1=yes, 0=no

    if (node) {
        for (i = 0; i < depth; i++) {
            printf( (stackOfBits & (1 << i)) ? "| " : "  ");
        }

        printf("+-o ");
    } else { // if (!node)
        for (i = 0; i <= depth + 1; i++) {
            printf( (stackOfBits & (1 << i)) ? "| " : "  ");
        }
    }
}
