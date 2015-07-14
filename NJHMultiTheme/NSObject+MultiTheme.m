#import "NJHMultiTheme.h"

@implementation NSObject (NJHMultiTheme)

+ (id)mt_get:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

- (id)mt_get:(SEL)selector {
    IMP imp = [self methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(self, selector);
}

@end