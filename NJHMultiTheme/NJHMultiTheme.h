#import <AppKit/AppKit.h>

@interface NJHMultiTheme : NSObject
@property (nonatomic, strong, readonly) NSBundle* bundle;
+ (instancetype)sharedPlugin;
@end


@interface NSMenu (MultiTheme)
- (NSMenuItem *)addItemWithTitle:(NSString *)aString target:(id)target action:(SEL)aSelector;
@end