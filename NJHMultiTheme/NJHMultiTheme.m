#import "NJHMultiTheme.h"


static NJHMultiTheme *sharedPlugin;
static NSString *kPluginIdentifier = @"NJHMultiTheme";
static NSString *kObjcTheme = @"ObjcThemeName";
static NSString *kSwiftTheme = @"SwiftThemeName";
static NSString *kGeneralUIChange = @"DVTFontAndColorGeneralUISettingsChangedNotification";
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
    BOOL fileChangeInProgress;
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
        self.bundle = plugin;

        [self loadPreferences];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDidChange:) name:kFileChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange:) name:kGeneralUIChange object:nil];
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

    if (!nextType || nextType == currentFileType)
        return; //NOTE: Unsupported source files will use active theme

    fileChangeInProgress = YES;

    id mgr = self.prefsMgr;
    SEL setCurrentPreferenceSet = NSSelectorFromString(@"setCurrentPreferenceSet:");
    SEL availablePreferenceSets = NSSelectorFromString(@"availablePreferenceSets");

    IMP availableThemes = [mgr methodForSelector:availablePreferenceSets];
    func = (void *)availableThemes;

    IMP setTheme = [mgr methodForSelector:setCurrentPreferenceSet];
    void (*changeTheme)(id, SEL, id) = (void *)setTheme;
    NSArray *themes = func(mgr, availablePreferenceSets);

    switch (nextType) {
        case LTFileTypeObjC:
            for (id theme in themes)
                if ([[theme name] isEqualToString:objcTheme])
                    changeTheme(mgr, setCurrentPreferenceSet, theme);
            break;
        case LTFileTypeSwift:
            for (id theme in themes)
                if ([[theme name] isEqualToString:swiftTheme])
                    changeTheme(mgr, setCurrentPreferenceSet, theme);
            break;
    }

    currentFileType = nextType;
    fileChangeInProgress = NO;
}

-(void)themeDidChange:(NSNotification *)note {
    if (fileChangeInProgress)
        return;

    NSString *themeName = self.activeThemeName;
    BOOL didUpdate = NO;

    switch (currentFileType) {
        case LTFileTypeObjC:
            if (![objcTheme isEqualToString:themeName]) {
                objcTheme = themeName;
                didUpdate = YES;
            }
            break;
        case LTFileTypeSwift:
            if (![swiftTheme isEqualToString:themeName]) {
                swiftTheme = themeName;
                didUpdate = YES;
            }
            break;
    }

    if (didUpdate)
        [self savePreferences];
}

- (id)prefsMgr {
    Class DVTFontAndColorTheme = NSClassFromString(@"DVTFontAndColorTheme");
    SEL selector = NSSelectorFromString(@"preferenceSetsManager");
    IMP imp = [DVTFontAndColorTheme methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(DVTFontAndColorTheme, selector);
}

- (NSString *)activeThemeName {
    Class DVTFontAndColorTheme = NSClassFromString(@"DVTFontAndColorTheme");
    SEL currentTheme = NSSelectorFromString(@"currentTheme");
    IMP impCurrentTheme = [DVTFontAndColorTheme methodForSelector:currentTheme];
    id (*func)(id, SEL) = (void *)impCurrentTheme;
    id newTheme = func(DVTFontAndColorTheme, currentTheme);
    return [newTheme name];
}

- (void)loadPreferences {
    NSDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kPluginIdentifier];
    objcTheme = defaults[kObjcTheme] ?: self.activeThemeName;
    swiftTheme = defaults[kSwiftTheme] ?: self.activeThemeName;
}

- (void)savePreferences {
    NSMutableDictionary *defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName:kPluginIdentifier].mutableCopy;
    [defaults setObject:objcTheme ?: swiftTheme forKey:kObjcTheme];
    [defaults setObject:swiftTheme ?: objcTheme forKey:kSwiftTheme];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults forName:kPluginIdentifier];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end