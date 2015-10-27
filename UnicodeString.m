//
//  UnicodeString.m
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import "UnicodeString.h"

@interface UnicodeString (Private)

-(void)separateLines;
-(void)concatenateLines;

-(void)translateToLaTeXFormat:(NSMutableAttributedString*)str;
-(void)translateTextMode:(NSMutableAttributedString*)str;
-(void)translateMathMode:(NSMutableAttributedString*)str;

-(void)replaceSpecials:(NSMutableAttributedString*)str;

-(void)replaceDiacritics:(NSMutableAttributedString*)str;
-(void)replaceCharTransforms:(NSMutableAttributedString*)str;

-(void)replaceGreek:(NSMutableAttributedString*)str;


///convenience method

-(void)replaceValuesFromDictionary:(NSDictionary*)dic forString:(NSMutableAttributedString*)str prefixingString:( NSString* _Nullable )prefix affixingString:( NSString* _Nullable )affix;

@end

@interface UnicodeString (Dictionaries)

+(NSDictionary*)dictionaryDiacritics;
+(NSDictionary*)dictionaryGreeksMM;
+(NSDictionary*)dictionarySpecials;
+(NSDictionary*)dictionaryCharacterTransforms;

@end

@implementation UnicodeString (Dictionaries)

+(NSDictionary *)dictionaryDiacritics{
    return @{@"\u0300":@"`", @"\u0301":@"'", @"\u0302":@"^", @"\u0303":@"~", @"\u0304":@"=", @"\u0306":@"u", @"\u0307":@".", @"\u0308":@"\"", @"\u030A":@"r", @"\u030B":@"H", @"\u030C":@"n", @"\u030D":@"|", @"\u030E":@"U", @"\u0323":@"d", @"\u0327":@"c", @"\u0328":@"k", @"\u0331":@"b",
             };
}


+(NSDictionary*)dictionaryBinaryDiacritics{
    return @{@"\u0361":@"t"
             };
}

+(NSDictionary*)dictionaryGreeksMM{
    return @{@"α":@"$\\alpha$", @"β":@"$\\beta$", @"γ":@"$\\gamma$", @"δ":@"$\\delta$", @"ϵ":@"$\\epsilon$", @"ε":@"$\\varepsilon$", @"ζ":@"$\\zeta$", @"η":@"$\\eta$", @"θ":@"$\\theta$", @"ϑ":@"$\\vartheta$", @"ι":@"$\\iota$", @"κ":@"$\\kappa$", @"λ":@"$\\lambda$", @"μ":@"$\\mu$", @"ν":@"$\\nu$", @"ξ":@"$\\xi$", @"π":@"$\\pi$", @"ϖ":@"$\\varpi$", @"ρ":@"$\\rho$", @"ϱ":@"$\\varrho$", @"σ":@"$\\sigma$", @"ς":@"$\\varsigma$", @"τ":@"$\\tau$", @"υ":@"$\\upsilon$", @"ϕ":@"$\\phi$", @"φ":@"$\\varphi$", @"χ":@"$\\chi$", @"ψ":@"$\\psi$", @"ω":@"$\\omega$", @"Γ":@"$\\Gamma$", @"Δ":@"$\\Delta$", @"Θ":@"$\\Theta$", @"Λ":@"$\\Lambda$", @"Ξ":@"$\\Xi$", @"Π":@"$\\Pi$", @"Σ":@"$\\Sigma$", @"Υ":@"$\\Upsilon$", @"Φ":@"$\\Phi$", @"Ψ":@"$\\Psi$", @"Ω":@"$\\Omega$"
             };
}

+(NSDictionary*)dictionarySpecials{
    return @{@"{":@"\\{", @"}":@"\\}", @"_":@"\\_", @"%":@"\\%", @"#":@"\\#", @"&":@"\\&", @"$":@"\\$" //still \\ to figure out;
             };
}

+(NSDictionary*)dictionaryCharacterTransforms{
    return @{@"ł":@"l", @"Ł":@"L", @"ø":@"o", @"Ø":@"O", @"\u0131":@"i", @"\u0237":@"j"
             };
}



@end

@implementation UnicodeString

@synthesize unicodeString;
@synthesize lines;

+(NSString*)translateAttributedString:(NSAttributedString*)str{
    UnicodeString* ucstr = [[UnicodeString alloc]initWithString:str];
    return ucstr.unicodeString.string;
}
+(NSString*)translateString:(NSString *)str{
    UnicodeString* ustr = [[UnicodeString alloc]initWithString:[[NSAttributedString alloc] initWithString:str]];
    return ustr.unicodeString.string;
}

-(instancetype)initWithString:(NSAttributedString*)str{
    self = [super init];
    if (self) {
        unicodeString = [[NSMutableAttributedString alloc]initWithAttributedString:str];
        [self separateLines];
        for (NSInteger i=0; i<lines.count; i++) {
            [self translateToLaTeXFormat:[lines objectAtIndex:i]];
        }
        [self concatenateLines];
    }
    return self;
}

-(void)separateLines{
    lines = [[NSMutableArray alloc]init];
    NSInteger m=0;
    for (NSInteger i=0; i<unicodeString.length; i++) {
        unichar c = [unicodeString.string characterAtIndex:i];
        if ([[NSCharacterSet newlineCharacterSet]characterIsMember:c]) {
            NSRange rng = NSMakeRange(m, i-m);
            [lines addObject:[[NSMutableAttributedString alloc]initWithAttributedString:[unicodeString attributedSubstringFromRange:rng]]];
            i++;
            m=i;
        }else if(i==unicodeString.length-1){
            NSRange rng = NSMakeRange(m, i-m+1);
            [lines addObject:[[NSMutableAttributedString alloc]initWithAttributedString:[unicodeString attributedSubstringFromRange:rng]]];
        }
    }
}

-(void)concatenateLines{
    NSMutableString* conc = [[NSMutableString alloc]init];
    for (NSInteger i=0; i<lines.count; i++) {
        NSAttributedString* line = [lines objectAtIndex:i];
        [conc appendString:line.string];
        if (i==lines.count-1) break;
        [conc appendString:@"\n\n"];
    }
    unicodeString = [[NSMutableAttributedString alloc]initWithString:conc];
}

-(void)translateToLaTeXFormat:(NSMutableAttributedString*)str{
    [self replaceSpecials:str];
    
    
    [self translateTextMode:str];
}


-(void)translateTextMode:(NSMutableAttributedString*)str{
}

-(void)translateMathMode:(NSMutableAttributedString*)str{
}


//only works if the key string is removed else infinite loops!
-(void)replaceValuesFromDictionary:(NSDictionary *)dic forString:(NSMutableAttributedString *)str prefixingString:(NSString *)prefix affixingString:(NSString *)affix{
    
    for (NSString* key in dic.allKeys){
        NSRange rng;
        while ((rng = [str.string rangeOfString:key]).length) {
            NSString * val = [dic valueForKey:key];
            val = [NSString stringWithFormat:@"%@%@%@", prefix? prefix:@"", val, affix? affix:@""];
            [str replaceCharactersInRange:rng withString:val];
        }
    }
}

#pragma mark Universal replacements;

-(void)replaceSpecials:(NSMutableAttributedString *)str{

    for (NSInteger i = str.length-1; i>=0; i--) {   //loop backwards to avoid growing string complications
        unichar c = [str.string characterAtIndex:i];
        if (c=='{' || c=='}' || c=='_' || c=='&' || c=='%' || c=='$' || c=='\\' || c=='#') {
            [str insertAttributedString:[[NSAttributedString alloc]initWithString:@"\\"] atIndex:i];
        }
    }
}


#pragma mark Text Mode replacements;

-(void)replaceDiacritics:(NSMutableAttributedString *)str{
    NSDictionary* dic = [UnicodeString dictionaryDiacritics];
    for (NSInteger n=0; n<dic.allKeys.count; n++){
        NSString* key =[dic.allKeys objectAtIndex:n];
        NSRange rng;
        while ((rng = [str.string rangeOfString:key]).length) {
            NSString * val = [dic valueForKey:key];
            NSString* rep;
            if (rng.location>0) {
                
            }else{
                
            }
        }
    }
}


#pragma mark Math Mode replacements;

-(void)replaceCharTransforms:(NSMutableAttributedString *)str{
    NSDictionary* dic = [UnicodeString dictionaryCharacterTransforms];
    [self replaceValuesFromDictionary:dic forString:str prefixingString:nil affixingString:@"{}"];
}


@end
