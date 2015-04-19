//TODO: Detect theme additions/removals and update menus

#import "NJHMultiTheme.h"


static NJHMultiTheme *sharedPlugin;
static NSString *kPluginIdentifier = @"com.NathanHosselton.MultiTheme";
static NSString *kObjcTheme = @"ObjcThemeName";
static NSString *kSwiftTheme = @"SwiftThemeName";
static NSString *kThemeNameSuffix = @".dvtcolortheme";
static NSString *kFileChange = @"transition from one file to another";
static NSString *kProjectChange = @"DVTSourceExpressionUnderMouseDidChangeNotification";

typedef NS_ENUM(NSInteger, MTFileType) {
    MTFileTypeObjC = 1,
    MTFileTypeSwift
};


@interface NJHMultiTheme()
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation NJHMultiTheme {
    MTFileType currentFileType;
    NSString *currentProject;
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
        self.bundle = plugin;
        [self loadPreferences];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDidChange:) name:kFileChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectDidChange:) name:kProjectChange object:nil];
        [self addMTMenuToMenuItem:[[NSApp mainMenu] itemWithTitle:@"Edit"]];
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
    id fileName = func(loc, selector);

    [self verifyFile:fileName];
}

-(void)projectDidChange:(NSNotification *)note {
    NSString *nextProject = [[note object] description];
    if (!nextProject || [nextProject isEqualToString:currentProject])
        return;

    currentProject = nextProject;
    id sourceCodeEditor = [note userInfo][@"DVTSourceExpressionUserInfoKey"];
    SEL selector = NSSelectorFromString(@"sourceCodeDocument");
    IMP imp = [sourceCodeEditor methodForSelector:selector];
    id (*func)(id, SEL) = (void *)imp;
    NSDocument *sourceCodeDocument = func(sourceCodeEditor, selector);

    [self verifyFile:[sourceCodeDocument fileURL].absoluteString];
}

- (void)verifyFile:(NSString *)fileName {
    MTFileType nextType;

    if ([[fileName substringWithRange:NSMakeRange(fileName.length - 2, 2)] isEqualToString:@".h"] ||
        [[fileName substringWithRange:NSMakeRange(fileName.length - 2, 2)] isEqualToString:@".m"])
        nextType = MTFileTypeObjC;
    else if ([[fileName substringWithRange:NSMakeRange(fileName.length - 6, 6)] isEqualToString:@".swift"])
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

- (void)addMTMenuToMenuItem:(NSMenuItem *)menuItem {
    if (!menuItem)
        return;
    NSMenuItem *swiftMenuItem = [NSMenuItem new];
    NSMenuItem *objcMenuItem = [NSMenuItem new];
    NSMenu *swiftMenu = [NSMenu new];
    NSMenu *objcMenu = [NSMenu new];

    swiftMenuItem.title = @"Set Swift Theme";
    objcMenuItem.title = @"Set Objective-C Theme";

    NSArray *themes = self.availableThemes;
    for (id theme in themes) {
        NSString *name = [theme name];
        NSString *cleanName = [name stringByReplacingOccurrencesOfString:kThemeNameSuffix withString:@""];

        NSMenuItem *swiftItem = [swiftMenu addItemWithTitle:cleanName target:self action:@selector(updateSwiftTheme:)];
        swiftItem.state = (int)[swiftTheme isEqualToString:name];
        NSMenuItem *objcItem = [objcMenu addItemWithTitle:cleanName target:self action:@selector(updateObjcTheme:)];
        objcItem.state = (int)[objcTheme isEqualToString:name];
    }

    [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
    [swiftMenuItem setSubmenu:swiftMenu];
    [objcMenuItem setSubmenu:objcMenu];
    [[menuItem submenu] addItem:swiftMenuItem];
    [[menuItem submenu] addItem:objcMenuItem];
}

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

#define MTDefaults [[NSUserDefaults standardUserDefaults] persistentDomainForName:kPluginIdentifier]

- (void)loadPreferences {
    NSDictionary *defaults = MTDefaults;
    objcTheme = defaults[kObjcTheme] ?: self.activeThemeName;
    swiftTheme = defaults[kSwiftTheme] ?: self.activeThemeName;
}

- (void)savePreferences {
    NSMutableDictionary *defaults = MTDefaults.mutableCopy ?: [NSMutableDictionary new];
    [defaults setObject:objcTheme forKey:kObjcTheme];
    [defaults setObject:swiftTheme forKey:kSwiftTheme];
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:defaults forName:kPluginIdentifier];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end