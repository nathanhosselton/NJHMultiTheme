#import <AppKit/AppKit.h>

@interface NJHMultiTheme : NSObject
@property (nonatomic, strong, readonly) NSBundle* bundle;
+ (instancetype)sharedPlugin;
@end