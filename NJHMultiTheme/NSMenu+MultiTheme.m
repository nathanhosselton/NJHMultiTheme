#import "NJHMultiTheme.h"

@implementation NSMenu (MultiTheme)

- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)selector {
    NSMenuItem *item = [self addItemWithTitle:title action:selector keyEquivalent:@""];
    [item setTarget:target];
    return item;
}

@end