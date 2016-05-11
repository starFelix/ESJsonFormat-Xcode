//
//  STClassInfo.h
//  ESJsonFormat
//
//  Created by felix zhu on 16/5/10.
//  Copyright © 2016年 EnjoySR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STPropertyInstance : NSObject

@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSArray *protocols;
@property (nonatomic, copy) NSString *propertyName;
@property (nonatomic, assign, getter=isOptional) BOOL optional;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, assign) BOOL isArray;

- (NSString *)propertyContent;
- (BOOL)canAssign;
- (BOOL)canCopy;

@end

@interface STClassInfo : STPropertyInstance

@property (nonatomic, strong) NSMutableArray *properties;

- (instancetype)initWithJSON:(id)json;

- (NSString *)classInterfaceContent;

- (NSString *)classImplementContent;

@end
