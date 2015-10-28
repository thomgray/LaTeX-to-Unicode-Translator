//
//  TeXTranslator.m
//  LaTeX
//
//  Created by Thomas Gray on 15/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import "TeXTranslator.h"
#import "LaTeXString.h"
#import "UnicodeString.h"

@implementation TeXTranslator

+(NSString*)translateAttributedStringToTex:(NSAttributedString *)unicodeString{
    return [UnicodeString translateAttributedString:unicodeString];
}

+(NSString *)translateStringToTex:(NSString *)unicodeString{
    return [UnicodeString translateString:unicodeString];
}

+(NSAttributedString*)translateTexToAttributedString:(NSString *)texString{
    return [LaTeXString translateString:texString];
}

@end
