//
//  STClassInfoCheckWindowController.m
//  ESJsonFormat
//
//  Created by felix zhu on 16/5/10.
//  Copyright © 2016年 EnjoySR. All rights reserved.
//

#import "STClassInfoCheckWindowController.h"

@interface STClassInfoCheckWindowController ()<NSOutlineViewDelegate,NSOutlineViewDataSource>

@property (nonatomic, strong) STClassInfo *classInfo;
@property (weak) IBOutlet NSTextField *modelNameField;
@property (weak) IBOutlet NSOutlineView *outlineView;

@end

@implementation STClassInfoCheckWindowController

- (instancetype)initWithClassInfo:(STClassInfo *)classInfo{
    self = [super initWithWindowNibName:@"STClassInfoCheckWindowController"];
    if (self) {
        self.classInfo = classInfo;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.outlineView.delegate = self;
    self.outlineView.dataSource = self;
}

- (IBAction)onConfirm:(id)sender {
    if (self.modelNameField.stringValue.length == 0) {
        return;
    }
    self.classInfo.className = self.modelNameField.stringValue;
    if (self.checkAction) {
        self.checkAction(self.classInfo);
    }
    [self close];
}

#pragma mark - outlineView
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item{
    item = item?:self.classInfo;
    if (![item isKindOfClass:[STClassInfo class]]) {
        return 0;
    }
    return [[(STClassInfo *)item properties] count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item{
    if (!item) {
        return YES;
    }
    if (![item isKindOfClass:[STClassInfo class]]) {
        return NO;
    }
    return [[(STClassInfo *)item properties] count] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item{
    item = item?:self.classInfo;
    if (![item isKindOfClass:[STClassInfo class]]) {
        return nil;
    }
    return [(STClassInfo *)item properties][index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    STPropertyInstance *instance = (STPropertyInstance *)item;
    if ([[tableColumn identifier] isEqualToString:@"ClassName"]) {
        return instance.className;
    }
    if (![[tableColumn identifier] isEqualToString:@"ClassName"] && !instance.key.length && !instance.propertyName.length) {
        return nil;
    }
    if ([[tableColumn identifier] isEqualToString:@"Property"]) {
        return instance.key;
    }
    if ([[tableColumn identifier] isEqualToString:@"Optional"]) {
        return @(instance.isOptional);
    }
    return nil;
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item{
    STPropertyInstance *instance = (STPropertyInstance *)item;
    if ([[tableColumn identifier] isEqualToString:@"ClassName"]) {
        [instance setClassName:object];
    }
    if ([[tableColumn identifier] isEqualToString:@"Property"]) {
        [instance setKey:object];
    }
    if ([[tableColumn identifier] isEqualToString:@"Optional"]) {
        [instance setOptional:[object boolValue]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item{
    STPropertyInstance *instance = (STPropertyInstance *)item;
    if ([[tableColumn identifier] isEqualToString:@"ClassName"] && instance.isArray) {
        return NO;
    }
    if (![[tableColumn identifier] isEqualToString:@"ClassName"] && !instance.key.length && !instance.propertyName.length) {
        return NO;
    }
    return YES;
}

@end
