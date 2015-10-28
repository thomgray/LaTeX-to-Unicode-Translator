//
//  LaTeXComponent.h
//  LaTeX
//
//  Created by Thomas Gray on 11/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LaTeXComponent : NSObject{    
    NSMutableArray<NSString*>* words;
    NSMutableAttributedString* string;
}

@property  NSString* _Nullable command;
@property  NSMutableArray* _Nonnull components;
@property BOOL mathmode;
@property BOOL treatGapLiterally;

-(instancetype _Nonnull)initWithString:(NSString* _Nonnull)str;
-(instancetype _Nonnull)initWithString:(NSString * _Nullable)str andCommand:(NSString* _Nullable)cmmd inheritingFrom:(LaTeXComponent* _Nullable)parent;

-(NSMutableAttributedString* _Nonnull)toString;
-(void)test;
-(void)print;

+(NSCharacterSet* _Nonnull)charactersSpecialEscape;
+(NSCharacterSet* _Nonnull)charactersAlphabetic;



@end