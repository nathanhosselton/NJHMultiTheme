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
    MTFileTypeOther,
    MTFileTypeObjC,
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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunching:) name:NSApplicationDidFinishLaunchingNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fileDidChange:) name:kFileChange object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectDidChange:) name:kProjectChange object:nil];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)note {
    [self addMTMenuToMenuItem:[[NSApp mainMenu] itemWithTitle:@"Edit"]];
}

- (void)fileDidChange:(NSNotification *)note {
    NSArray *toolbarItems = [[NSApp mainWindow] toolbar].items;

    if (toolbarItems.count >= 6) {
        NSToolbarItem *editorItem = [toolbarItems objectAtIndex:5];
        NSSegmentedControl *control = (NSSegmentedControl *)[editorItem view];
        if (![note.object count] || control.selectedSegment == 1)
            return;
    }

    id loc = note.object[@"next"];
    id fileName = [loc mt_get:NSSelectorFromString(@"documentURLString")];

    [self verifyFile:fileName];
}

-(void)projectDidChange:(NSNotification *)note {
    NSString *nextProject = [[note object] description];
    if (!nextProject || [nextProject isEqualToString:currentProject])
        return;

    currentProject = nextProject;
    id sourceCodeEditor = [note userInfo][@"DVTSourceExpressionUserInfoKey"];
    NSDocument *sourceCodeDocument = [sourceCodeEditor mt_get:NSSelectorFromString(@"sourceCodeDocument")];

    [self verifyFile:[sourceCodeDocument fileURL].absoluteString];
}

- (void)verifyFile:(NSString *)fileName {
    MTFileType nextType;

    if ([[fileName substringWithRange:NSMakeRange(fileName.length - 2, 2)] isEqualToString:@".h"] ||
        [[fileName substringWithRange:NSMakeRange(fileName.length - 2, 2)] isEqualToString:@".m"])
        nextType = MTFileTypeObjC;
    else if ([[fileName substringWithRange:NSMakeRange(fileName.length - 6, 6)] isEqualToString:@".swift"])
        nextType = MTFileTypeSwift;
    else
        nextType = currentFileType = MTFileTypeOther;

    if (nextType != currentFileType) {
        currentFileType = nextType;
        [self changeActiveTheme];
    }
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
    id mgr = [NSClassFromString(@"DVTFontAndColorTheme") mt_get:NSSelectorFromString(@"preferenceSetsManager")];
    SEL setCurrentPreferenceSet = NSSelectorFromString(@"setCurrentPreferenceSet:");
    IMP setTheme = [mgr methodForSelector:setCurrentPreferenceSet];
    void (*func)(id, SEL, id) = (void *)setTheme;

    NSArray *themes = [mgr mt_get:NSSelectorFromString(@"availablePreferenceSets")];

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
        default:
            break;
    }
}

- (NSString *)activeThemeName {
    id activeTheme = [NSClassFromString(@"DVTFontAndColorTheme") mt_get:NSSelectorFromString(@"currentTheme")];
    return [activeTheme name];
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

    id mgr = [NSClassFromString(@"DVTFontAndColorTheme") mt_get:NSSelectorFromString(@"preferenceSetsManager")];
    NSArray *themes = [mgr mt_get:NSSelectorFromString(@"availablePreferenceSets")];

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