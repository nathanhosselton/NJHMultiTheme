#import "NJHMultiTheme.h"


static NJHMultiTheme *sharedPlugin;
static NSString *kPluginIdentifier = @"NJHLanguageTheme";
static NSString *kGeneralUIChange = @"DVTFontAndColorGeneralUISettingsChangedNotification";
static NSString *kSourceTextChange = @"DVTFontAndColorSourceTextSettingsChangedNotification";
static NSString *kFileChange = @"transition from one file to another";

typedef NS_ENUM(NSInteger, LTFileType) {
    LTFileTypeObjC = 1,
    LTFileTypeSwift
};


@interface NJHMultiTheme()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation NJHMultiTheme {
    LTFileType currentFileType;
    NSString *objcTheme;
    NSString *swiftTheme;
}

+ (void)pluginDidLoad:(NSBundle *)plugin {
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
}

+ (instancetype)sharedPlugin {
    return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin {
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
//        DVTPreferenceSetManager *mgr = [DVTFontAndColorTheme preferenceSetsManager];
//        mgr.currentPreferenceSet = mgr.userPreferenceSets.firstObject;
//        NSLog(@"%@", ((DVTPreferenceSetManager *)[DVTFontAndColorTheme preferenceSetsManager]).availablePreferenceSets);
//        NSLog(@"%@", ((DVTPreferenceSetManager *)[DVTFontAndColorTheme preferenceSetsManager]).userPreferenceSets);
        // Listener for theme changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange:) name:kGeneralUIChange object:nil];
        // Listener for file changes
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDidChange:) name:kFileChange object:nil];
    }
    return self;
}

- (void)fileDidChange:(NSNotification *)note {
    if (![note.object count])
        return;

    id loc = note.object[@"next"];
    SEL selector = NSSelectorFromString(@"documentURLString");
    IMP imp = [loc methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    NSString *fileURLString = func(loc, selector);
    LTFileType nextType;

    if ([[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 2, 2)] isEqualToString:@".h"] ||
        [[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 2, 2)] isEqualToString:@".m"])
        nextType = LTFileTypeObjC;
    else if ([[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 6, 6)] isEqualToString:@".swift"])
        nextType = LTFileTypeSwift;

    if (!nextType || nextType == currentFileType) //NOTE: Non-native source files will maintain current theme
        return;

    switch (nextType) {
        case LTFileTypeObjC:
            // Set ObjC Theme
            break;
        case LTFileTypeSwift:
            // Set Swift Theme
            break;
    }

    currentFileType = nextType;
}

-(void)themeDidChange:(NSNotification *)note {
    NSLog(@"Theme changed");
}

- (NSMutableDictionary *)defaultz {
    return [[[NSUserDefaults standardUserDefaults] persistentDomainForName:kPluginIdentifier] mutableCopy];
}

- (void)loadPreferences {
    //
}

- (void)savePreferences {
    //
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end