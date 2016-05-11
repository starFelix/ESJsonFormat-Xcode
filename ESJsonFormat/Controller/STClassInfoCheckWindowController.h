//
//  STClassInfoCheckWindowController.h
//  ESJsonFormat
//
//  Created by felix zhu on 16/5/10.
//  Copyright © 2016年 EnjoySR. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "STClassInfo.h"

typedef void(^STCheckAction)(STClassInfo *info);

@interface STClassInfoCheckWindowController : NSWindowController

@property (nonatomic, copy) STCheckAction checkAction;

- (instancetype)initWithClassInfo:(STClassInfo *)classInfo;

@end
