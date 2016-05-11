//
//  STClassInfo.m
//  ESJsonFormat
//
//  Created by felix zhu on 16/5/10.
//  Copyright © 2016年 EnjoySR. All rights reserved.
//

#define NSDictionaryClass @"NSDictionary"
#define NSArrayClass @"NSArray"
#define NSStringClass @"NSString"
#define NSNumberClass @"NSNumber"

#import "STClassInfo.h"

@interface STClassInfo ()

@end

@implementation STClassInfo

- (instancetype)init{
    return [self initWithJSON:nil];
}

- (instancetype)initWithJSON:(id)json{
    if (!json || !([json isKindOfClass:[NSArray class]] || [json isKindOfClass:[NSDictionary class]])) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.properties = [NSMutableArray new];
        self.propertyName = @"";
        [self dealWithJSON:json toClassInfo:self];
    }
    return self;
}

- (void)dealWithJSON:(id)json toClassInfo:(STClassInfo *)classInfo{
    if ([json isKindOfClass:[NSDictionary class]]) {
        self.className = NSDictionaryClass;
        NSDictionary *jsonDic = (NSDictionary *)json;
        [jsonDic enumerateKeysAndObjectsUsingBlock:^(NSString*  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]]) {
                STClassInfo *info = [[STClassInfo alloc] initWithJSON:obj];
                info.propertyName = key;
                info.key = key;
                [self.properties addObject:info];
                return ;
            }
            STPropertyInstance *property = [STPropertyInstance new];
            property.key = key;
            property.propertyName = key;
            property.className = [self classOfObject:obj];
            [self.properties addObject:property];
        }];
    }else if ([json isKindOfClass:[NSArray class]]){
        self.className = NSArrayClass;
        self.isArray = YES;
        NSArray *jsonArray = (NSArray *)json;
        __block NSString *className = nil;
        __block NSMutableDictionary *keysCompator = [NSMutableDictionary new];
        [jsonArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (className && ![className isEqualToString:[self classOfObject:obj]]) {
                @throw [NSException exceptionWithName:@"解析" reason:@"解析json出错，数组内容类型不同" userInfo:@{@"json":jsonArray}];
                *stop = YES;
                return ;
            }
            if ([obj isKindOfClass:[NSDictionary class]]) {
                className = NSDictionaryClass;
                [keysCompator addEntriesFromDictionary:obj];
                return;
            }
            className = [self classOfObject:obj];
        }];
        if ([className isEqualToString:NSDictionaryClass]) {
            STClassInfo *info = [[STClassInfo alloc] initWithJSON:keysCompator];
            [self.properties addObject:info];
            return ;
        }
    }
}

- (NSString *)classInterfaceContent{
    BOOL printSelf = YES;
    if (self.isArray) {
        printSelf = NO;
    }
    if ([self.className hasPrefix:@"NS"]
        || [self.className hasPrefix:@"CG"]
        || [self.className hasPrefix:@"int"]
        || [self.className hasPrefix:@"float"]
        || [self.className hasPrefix:@"double"]) {
        printSelf = NO;
    }
    __block NSMutableString *result = [NSMutableString new];
    NSMutableArray *baseProperty = [NSMutableArray new];
    NSMutableArray *customProperty = [NSMutableArray new];
    [self.properties enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[STClassInfo class]]) {
            [customProperty addObject:obj];
        }else{
            [baseProperty addObject:obj];
        }
    }];
    [customProperty enumerateObjectsUsingBlock:^(STClassInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result appendString:[obj classInterfaceContent]];
    }];
    if (printSelf) {
        [result appendString:self.interfaceHeadString];
        [baseProperty enumerateObjectsUsingBlock:^(STPropertyInstance*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [result appendString:[obj propertyContent]];
        }];
        [customProperty enumerateObjectsUsingBlock:^(STClassInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [result appendString:[obj propertyContent]];
        }];
        [result appendString:self.endString];
    }
    return result;
}

- (NSString *)classImplementContent{
    BOOL printSelf = YES;
    if (self.isArray) {
        printSelf = NO;
    }
    if ([self.className hasPrefix:@"NS"]
        || [self.className hasPrefix:@"CG"]
        || [self.className hasPrefix:@"int"]
        || [self.className hasPrefix:@"float"]
        || [self.className hasPrefix:@"double"]) {
        printSelf = NO;
    }
    __block NSMutableString *result = [NSMutableString new];
    NSMutableArray *baseProperty = [NSMutableArray new];
    NSMutableArray *customProperty = [NSMutableArray new];
    NSMutableArray *changeKeys = [NSMutableArray new];
    NSMutableArray *optionals = [NSMutableArray new];
    [self.properties enumerateObjectsUsingBlock:^(STPropertyInstance*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[STClassInfo class]]) {
            [customProperty addObject:obj];
        }else{
            [baseProperty addObject:obj];
        }
        if (![obj.key isEqualToString:obj.propertyName]) {
            [changeKeys addObject:obj];
        }
        if ([obj canAssign] && obj.isOptional) {
            [optionals addObject:obj];
        }
    }];
    [customProperty enumerateObjectsUsingBlock:^(STClassInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result appendString:[obj classImplementContent]];
    }];
    if (printSelf) {
        [result appendString:self.implementHeadString];
        [result appendString:[self keymapString:changeKeys]];
        [result appendString:[self optionalString:optionals]];
        [result appendString:[self endString]];
    }
    return result;
}

- (NSString *)interfaceHeadString{
    NSMutableString *result = [NSMutableString new];
    if (!self.propertyName.length) {
        [result appendFormat:@"@protocol %@ <NSObject> @end\n",self.className];
    }
    [result appendFormat:@"\n@interface %@ : JSONModel\n\n",self.className];
    return [result copy];
}

- (NSString *)implementHeadString{
    return [NSString stringWithFormat:@"\n@implementation %@\n",self.className];
}

- (NSString *)propertyContent{
    NSString *oString = @"strong";
    NSString *pointString = @"*";
    NSString *optionalString = self.isOptional?@"Optional":@"";
    if (self.isArray) {
        NSString *fillClass = @"";
        if ([[self.properties firstObject] isKindOfClass:[STClassInfo class]]
            && ![[[self.properties firstObject] className] isEqualToString:NSDictionaryClass]) {
            fillClass = [[self.properties firstObject] className];
        }
        BOOL needSeperate = self.isOptional && fillClass.length;
        optionalString = [NSString stringWithFormat:@"<%@%@%@>",optionalString,needSeperate?@",":@"",fillClass];
        NSString *classString = self.isArray?NSArrayClass:self.className;
        return [NSString stringWithFormat:@"@property (nonatomic, %@) %@%@ %@%@;\n",oString,classString,optionalString,pointString,self.key];
    }else{
        return [NSString stringWithFormat:@"@property (nonatomic, %@) %@%@ %@%@;\n",oString,self.className,optionalString,pointString,self.key];
    }
}

- (NSString *)keymapString:(NSArray *)changeKeys{
    if (changeKeys.count<=0) {
        return @"\n";
    }
    NSString *formatString = @"+ (JSONKeyMapper *)keyMapper {\n"
        "    return [[JSONKeyMapper alloc] initWithDictionary:@{%@}];\n"
        "}\n";
    NSMutableArray *keys = [NSMutableArray new];
    [changeKeys enumerateObjectsUsingBlock:^(STPropertyInstance*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *map = [NSString stringWithFormat:@"@\"%@\":@\"%@\"",obj.propertyName,obj.key];
        [keys addObject:map];
    }];
    NSString *map = [keys componentsJoinedByString:@",\n"];
    return [NSString stringWithFormat:formatString,map];
}

- (NSString *)optionalString:(NSArray *)optionals{
    if (optionals.count<=0) {
        return @"\n";
    }
    NSString *formatString = @"+(BOOL)propertyIsOptional:(NSString*)propertyName {\n"
    "    if (%@) {\n"
    "        return YES;\n"
    "    }\n"
    "    return [super propertyIsOptional:propertyName];\n"
    "}\n";
    NSMutableArray *keys = [NSMutableArray new];
    [optionals enumerateObjectsUsingBlock:^(STPropertyInstance*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *map = [NSString stringWithFormat:@"[propertyName isEqualToString:@\"%@\"]",obj.propertyName];
        [keys addObject:map];
    }];
    NSString *map = [keys componentsJoinedByString:@" || "];
    return [NSString stringWithFormat:formatString,map];
}

- (NSString *)endString {
    return @"\n@end\n";
}

- (NSString *)classOfObject:(id)object{
    if ([object isKindOfClass:[NSArray class]]) {
        return NSArrayClass;
    }else if ([object isKindOfClass:[NSDictionary class]]) {
        return NSDictionaryClass;
    }else if ([object isKindOfClass:[NSString class]]){
        return NSStringClass;
    }else if ([object isKindOfClass:[NSNumber class]]){
        return NSNumberClass;
    }
    return NSStringFromClass([object class]);
}

- (NSString *)debugDescription{
    NSMutableString *result = [NSMutableString new];
    [result appendString:@"\n<STClassInfo>\n"];
    [result appendString:[super debugDescription]];
    [result appendString:@"\n____\n"];
    [self.properties enumerateObjectsUsingBlock:^(STPropertyInstance*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result appendString:[obj debugDescription]];
    }];
    return result;
}

@end

@implementation STPropertyInstance

- (BOOL)canAssign{
    if ([self.className isEqualToString:@"int"]
        || [self.className isEqualToString:@"NSInteger"]
        || [self.className isEqualToString:@"CGFloat"]
        || [self.className isEqualToString:@"float"]
        || [self.className isEqualToString:@"double"]
        || [self.className isEqualToString:@"long"]
        || [self.className isEqualToString:@"NSTimeInterval"]
        || [self.className isEqualToString:@"BOOL"]
        || [self.className isEqualToString:@"bool"]) {
        return YES;
    }
    return NO;
}

- (BOOL)canCopy{
    if ([self.className isEqualToString:NSStringClass]){
        return YES;
    }
    return NO;
}

- (NSString *)propertyContent{
    BOOL canAssgin = [self canAssign];
    NSString *oString = canAssgin?@"assign":([self canCopy]?@"copy":@"strong");
    NSString *pointString = canAssgin?@"":@"*";
    NSString *optionalString = (self.isOptional && !canAssgin)?@"<Optional>":@"";
    return [NSString stringWithFormat:@"@property (nonatomic, %@) %@%@ %@%@;\n",oString,self.className,optionalString,pointString,self.key];
}

- (NSString *)debugDescription{
    return [NSString stringWithFormat:@"<STPropertyInstance>\nclassName:%@,propertyName:%@,optional:%@,key:%@,isArray:%@\n",self.className,self.propertyName,self.optional?@"YES":@"NO",self.key,self.isArray?@"YES":@"NO"];
}

@end
