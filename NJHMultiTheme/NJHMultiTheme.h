#import <AppKit/AppKit.h>

@interface NJHMultiTheme : NSObject
@property (nonatomic, strong, readonly) NSBundle* bundle;
+ (instancetype)sharedPlugin;
@end


@interface NSMenu (MultiTheme)
- (NSMenuItem *)addItemWithTitle:(NSString *)title target:(id)target action:(SEL)selector;
@end


@interface NSObject (MultiTheme)
+ (id)mt_get:(SEL)selector;
- (id)mt_get:(SEL)selector;
@end