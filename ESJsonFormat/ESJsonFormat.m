//
//  ESJsonFormat.m
//  ESJsonFormat
//
//  Created by 尹桥印 on 15/6/28.
//  Copyright (c) 2015年 EnjoySR. All rights reserved.
//

#import "ESJsonFormat.h"
#import "ESJsonFormatManager.h"
#import "ESFormatInfo.h"
#import "ESInputJsonController.h"
#import "ESSettingController.h"
#import "ESPbxprojInfo.h"
#import "ESJsonFormatSetting.h"
#import "ESClassInfo.h"
#import "STClassInfoCheckWindowController.h"

@interface ESJsonFormat()<ESInputJsonControllerDelegate>
@property (nonatomic, strong) ESInputJsonController *inputCtrl;
@property (nonatomic, strong) ESSettingController *settingCtrl;
@property (nonatomic, strong) STClassInfoCheckWindowController *checkCtrl;
@property (nonatomic, strong) id eventMonitor;
@property (nonatomic, strong, readwrite) NSBundle *bundle;
@property (nonatomic, copy) NSString *currentFilePath;
@property (nonatomic, copy) NSString *currentProjectPath;
@property (nonatomic) NSTextView *currentTextView;
@property (nonatomic, assign) BOOL notiTag;

@end

@implementation ESJsonFormat

+ (instancetype)sharedPlugin{
    return sharedPlugin;
}

+ (instancetype)instance{
    return instance;
}

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init]) {
        // reference to plugin's bundle, for resource access
        self.bundle = plugin;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didApplicationFinishLaunchingNotification:)
                                                     name:NSApplicationDidFinishLaunchingNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outputResult2:) name:ESFormatResultNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationLog:) name:NSTextViewDidChangeSelectionNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationLog:) name:@"IDEEditorDocumentDidChangeNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notificationLog:) name:@"PBXProjectDidOpenNotification" object:nil];
    }
    instance = self;
    return self;
}

- (void)notificationLog:(NSNotification *)notify
{
    if (!self.notiTag) return;
    if ([notify.name isEqualToString:NSTextViewDidChangeSelectionNotification]) {
        if ([notify.object isKindOfClass:[NSTextView class]]) {
            NSTextView *text = (NSTextView *)notify.object;
            self.currentTextView = text;
        }
    }else if ([notify.name isEqualToString:@"IDEEditorDocumentDidChangeNotification"]){
        //Track the current open paths
        NSObject *array = notify.userInfo[@"IDEEditorDocumentChangeLocationsKey"];
        NSURL *url = [[array valueForKey:@"documentURL"] firstObject];
        if (![url isKindOfClass:[NSNull class]]) {
            NSString *path = [url absoluteString];
            self.currentFilePath = path;
            if ([self.currentFilePath hasSuffix:@"swift"]) {
                self.swift = YES;
            }else{
                self.swift = NO;
            }
        }
    }else if ([notify.name isEqualToString:@"PBXProjectDidOpenNotification"]){
        self.currentProjectPath = [notify.object valueForKey:@"path"];
        [[ESPbxprojInfo shareInstance] setParamsWithPath:[self.currentProjectPath stringByAppendingPathComponent:@"project.pbxproj"]];
    }
}

-(void)outputResult2:(NSNotification*)noti{
    STClassInfo *classInfo = noti.object;
    self.checkCtrl = [[STClassInfoCheckWindowController alloc] initWithClassInfo:classInfo];
    [self.checkCtrl showWindow:self.checkCtrl];
    __weak typeof(self) weakSelf = self;
    [self.checkCtrl setCheckAction:^(STClassInfo *classInfo){
        [weakSelf outputByInfo:classInfo];
    }];
}

- (void)outputByInfo:(STClassInfo *)classInfo{
    if (!self.currentTextView) return;
    
    [self appendToHead:self.currentFilePath byInfo:classInfo];
    [self appendToMFiel:self.currentFilePath byInfo:classInfo];
    
}

- (void)appendToHead:(NSString *)path byInfo:(STClassInfo *)classInfo{
    //再添加.m文件的内容
    NSString *urlStr = [NSString stringWithFormat:@"%@h",[self.currentFilePath substringWithRange:NSMakeRange(0, path.length-1)]] ;
    NSURL *writeUrl = [NSURL URLWithString:urlStr];
    //The original content
    NSString *originalContent = [NSString stringWithContentsOfURL:writeUrl encoding:NSUTF8StringEncoding error:nil];
    
    originalContent = [originalContent stringByAppendingString:[classInfo classInterfaceContent]];
    
    [originalContent writeToURL:writeUrl atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)appendToMFiel:(NSString *)path byInfo:(STClassInfo *)classInfo{
    //再添加.m文件的内容
    NSString *urlStr = [NSString stringWithFormat:@"%@m",[self.currentFilePath substringWithRange:NSMakeRange(0, self.currentFilePath.length-1)]] ;
    NSURL *writeUrl = [NSURL URLWithString:urlStr];
    //The original content
    NSString *originalContent = [NSString stringWithContentsOfURL:writeUrl encoding:NSUTF8StringEncoding error:nil];
    
    originalContent = [originalContent stringByAppendingString:[classInfo classImplementContent]];
    
    [originalContent writeToURL:writeUrl atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti{
    self.notiTag = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Window"];
    if (menuItem) {
        
        NSMenu *menu = [[NSMenu alloc] init];
        
        //Input JSON window
        NSMenuItem *inputJsonWindow = [[NSMenuItem alloc] initWithTitle:@"Input JSON window" action:@selector(showInputJsonWindow:) keyEquivalent:@"J"];
        [inputJsonWindow setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
        inputJsonWindow.target = self;
        [menu addItem:inputJsonWindow];
        
        //Setting
        NSMenuItem *settingWindow = [[NSMenuItem alloc] initWithTitle:@"Setting" action:@selector(showSettingWindow:) keyEquivalent:@""];
        settingWindow.target = self;
        [menu addItem:settingWindow];
        
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:@"ESJsonFormat" action:nil keyEquivalent:@""];
        item.submenu = menu;
    
        [[menuItem submenu] addItem:item];
    }
}

- (void)showInputJsonWindow:(NSMenuItem *)item{

    if (!(self.currentTextView && self.currentFilePath)) {
        NSError *error = [NSError errorWithDomain:@"Current state is not edit!" code:0 userInfo:nil];
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
        return;
    }
    self.notiTag = NO;
    self.inputCtrl = [[ESInputJsonController alloc] initWithWindowNibName:@"ESInputJsonController"];
    self.inputCtrl.delegate = self;
    [self.inputCtrl showWindow:self.inputCtrl];
}

- (void)showSettingWindow:(NSMenuItem *)item{
    self.settingCtrl = [[ESSettingController alloc] initWithWindowNibName:@"ESSettingController"];
    [self.settingCtrl showWindow:self.settingCtrl];
}

-(void)windowWillClose{
    self.notiTag = YES;
}
- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
