#import "NJHMultiTheme.h"


static NJHMultiTheme *sharedPlugin;
static NSString *kPluginIdentifier = @"NJHMultiTheme";
static NSString *kObjcTheme = @"ObjcThemeName";
static NSString *kSwiftTheme = @"SwiftThemeName";
static NSString *kThemeNameSuffix = @".dvtcolortheme";
static NSString *kGeneralUIChange = @"DVTFontAndColorGeneralUISettingsChangedNotification";
static NSString *kFileChange = @"transition from one file to another";

typedef NS_ENUM(NSInteger, MTFileType) {
    MTFileTypeObjC = 1,
    MTFileTypeSwift
};


@interface NJHMultiTheme()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation NJHMultiTheme {
    MTFileType currentFileType;
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
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeDidChange:) name:kGeneralUIChange object:nil];

        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *swiftMenuItem = [NSMenuItem new];
            swiftMenuItem.title = @"Set Swift Theme";
            NSMenuItem *objcMenuItem = [NSMenuItem new];
            objcMenuItem.title = @"Set Obj-C Theme";
            NSMenu *swiftMenu = [NSMenu new];
            NSMenu *objcMenu = [NSMenu new];
            NSArray *themes = self.availableThemes;
            NSMutableArray *themeNames = [NSMutableArray arrayWithCapacity:themes.count];
            for (id theme in themes)
                [themeNames addObject:[[theme name] stringByReplacingOccurrencesOfString:kThemeNameSuffix withString:@""]];
            for (NSString *name in themeNames) {
                NSMenuItem *swiftItem = [swiftMenu addItemWithTitle:name target:self action:@selector(updateSwiftTheme:)];
                NSMenuItem *objcItem = [objcMenu addItemWithTitle:name target:self action:@selector(updateObjcTheme:)];
                swiftItem.state = (int)[swiftTheme isEqualToString:[name stringByAppendingString:kThemeNameSuffix]];
                objcItem.state = (int)[objcTheme isEqualToString:[name stringByAppendingString:kThemeNameSuffix]];
            }
            [swiftMenuItem setSubmenu:swiftMenu];
            [objcMenuItem setSubmenu:objcMenu];
            [[menuItem submenu] addItem:swiftMenuItem];
            [[menuItem submenu] addItem:objcMenuItem];
        }
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

    MTFileType nextType;

    if ([[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 2, 2)] isEqualToString:@".h"] ||
        [[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 2, 2)] isEqualToString:@".m"])
        nextType = MTFileTypeObjC;
    else if ([[fileURLString substringWithRange:NSMakeRange(fileURLString.length - 6, 6)] isEqualToString:@".swift"])
        nextType = MTFileTypeSwift;

    if (!nextType || nextType == currentFileType)
        return; //NOTE: Unsupported source files will use active theme

    currentFileType = nextType;
    [self changeActiveTheme];
}

- (void)updateObjcTheme:(NSMenuItem *)item {
    id selectedTheme = [item.title stringByAppendingString:kThemeNameSuffix];
    if ([objcTheme isEqualToString:selectedTheme])
        return;
    objcTheme = selectedTheme;
    for (NSMenuItem *otherItem in item.parentItem.submenu.itemArray)
        [otherItem setState:NSOffState];
    [item setState:NSOnState];
    if (currentFileType == MTFileTypeObjC)
        [self changeActiveTheme];
    [self savePreferences];
}

- (void)updateSwiftTheme:(NSMenuItem *)item {
    id selectedTheme = [item.title stringByAppendingString:kThemeNameSuffix];
    if ([swiftTheme isEqualToString:selectedTheme])
        return;
    swiftTheme = selectedTheme;
    for (NSMenuItem *otherItem in item.parentItem.submenu.itemArray)
        [otherItem setState:NSOffState];
    [item setState:NSOnState];
    if (currentFileType == MTFileTypeSwift)
        [self changeActiveTheme];
    [self savePreferences];
}

- (void)changeActiveTheme {
    id mgr = self.preferenceSetsManager;
    SEL setCurrentPreferenceSet = NSSelectorFromString(@"setCurrentPreferenceSet:");
    IMP setTheme = [mgr methodForSelector:setCurrentPreferenceSet];
    void (*func)(id, SEL, id) = (void *)setTheme;
    NSArray *themes = self.availableThemes;

    switch (currentFileType) {
        case MTFileTypeObjC:
            for (id theme in themes)
                if ([[theme name] isEqualToString:objcTheme])
                    func(mgr, setCurrentPreferenceSet, theme);
            break;
        case MTFileTypeSwift:
            for (id theme in themes)
                if ([[theme name] isEqualToString:swiftTheme])
                    func(mgr, setCurrentPreferenceSet, theme);
            break;
    }
}

//-(void)themeDidChange:(NSNotification *)note {
//    if (fileChangeInProgress)
//        return;
//
//    NSString *themeName = self.activeThemeName;
//    BOOL didUpdate = NO;
//
//    switch (currentFileType) {
//        case MTFileTypeObjC:
//            if (![objcTheme isEqualToString:themeName]) {
//                objcTheme = themeName;
//                didUpdate = YES;
//            }
//            break;
//        case MTFileTypeSwift:
//            if (![swiftTheme isEqualToString:themeName]) {
//                swiftTheme = themeName;
//                didUpdate = YES;
//            }
//            break;
//    }
//
//    if (didUpdate)
//        [self savePreferences];
//}

- (id)preferenceSetsManager {
    Class DVTFontAndColorTheme = NSClassFromString(@"DVTFontAndColorTheme");
    SEL selector = NSSelectorFromString(@"preferenceSetsManager");
    IMP imp = [DVTFontAndColorTheme methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(DVTFontAndColorTheme, selector);
}

- (NSArray *)availableThemes {
    id mgr = self.preferenceSetsManager;
    SEL selector = NSSelectorFromString(@"availablePreferenceSets");
    IMP imp = [mgr methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    return func(mgr, selector);
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