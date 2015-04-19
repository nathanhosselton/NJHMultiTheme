#import "NJHMultiTheme.h"

@implementation NSMenu (MultiTheme)

- (NSMenuItem *)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector {
    NSMenuItem *item = [self addItemWithTitle:aString action:aSelector keyEquivalent:@""];
    [item setTarget:target];
    return item;
}

@end