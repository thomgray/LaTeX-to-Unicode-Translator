//
//  LaTexCommander.m
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//
//  Just a reminder. To implement any functionality, write or add to an execute method (and corresponding dictionary getter if necessary), and ensure that the appropriate principle method calls that method if it doesn't already. These principle methods are:
//      executeCommandFromComponent (univerasal), executeCommandInTextMode and executeCommandInMathMode

#import "LaTexCommander.h"

@interface LaTexCommander (Private)

+(NSMutableAttributedString*)executeCommandInTextMode:(LaTeXComponent*)comp withString:(NSMutableAttributedString*)str;
+(NSMutableAttributedString*)executeCommandInMathMode:(LaTeXComponent*)comp withString:(NSMutableAttributedString*)str;

//+(NSDictionary*)commandsDiacritic;
+(BOOL)executeDiacriticCommand:(NSString*)command withString:(NSMutableAttributedString*)in;

+(BOOL)executeCharTransform:(NSString*)command withString:(NSMutableAttributedString*)in treatingLiterally:(BOOL)lit;

+(NSMutableAttributedString*)executeSpecialCommand:(NSString*)command withString:(NSMutableAttributedString*)in;

+(BOOL)executeMathModeTransforms:(NSString*)command withString:(NSMutableAttributedString*)in treatingLiterally:(BOOL)lit;



+(void)trimLeadingWhitespace:(NSMutableAttributedString*)in;
+(void)trimOneLeadingWhitespace:(NSMutableAttributedString*)in;

@end

@interface LaTexCommander (Dictionaries)

+(NSArray*)commandsSpecial;
+(NSDictionary*)commandsDiacritic;


//text mode
+(NSDictionary*)commandsCharacterTransforms;

//mathmode
+(NSDictionary*)commandsGreekLettersMM;

@end

@implementation LaTexCommander (Dictionaries)

+(NSDictionary*)commandsDiacritic{
    return @{@"`":@"\u0300", @"'":@"\u0301", @"^" : @"\u0302", @"~":@"\u0303", @"=":@"\u0304", @"u":@"\u0306", @".":@"\u0307", @"\"":@"\u0308", @"r":@"\u030A", @"H": @"\u030B", @"n":@"\u030C",@"|":@"\u030D", @"U":@"\u030E", @"d":@"\u0323", @"c":@"\u0327", @"k":@"\u0328", @"b":@"\u0331",
             //binary diacritics
             @"t":@"\u0361"
             };
}
+(NSArray *)commandsSpecial{
    return @[@"{", @"}", @"_", @"\\", @"%", @"$", @"#", @"&"];
}

+(NSDictionary *)commandsCharacterTransforms{
    return @{@"l":@"ł", @"L":@"Ł", @"o":@"ø", @"O":@"Ø", @"i":@"\u0131", @"j":@"\u0237"
             };
}

+(NSDictionary *)commandsGreekLettersMM{
    return @{@"alpha":@"α", @"beta":@"β", @"gamma":@"γ", @"delta":@"δ", @"epsilon":@"ϵ", @"varepsilon":@"ε", @"zeta":@"ζ", @"eta":@"η", @"theta":@"θ", @"vartheta":@"ϑ", @"iota":@"ι", @"kappa":@"κ", @"lambda":@"λ", @"mu":@"μ", @"nu":@"ν", @"xi":@"ξ", @"omicron":@"ο", @"pi":@"π", @"varpi":@"ϖ", @"rho":@"ρ", @"varrho":@"ϱ", @"sigma":@"σ", @"varsigma":@"ς", @"tau":@"τ", @"upsilon":@"υ", @"phi":@"ϕ", @"varphi":@"φ", @"chi":@"χ", @"psi":@"ψ", @"omega":@"ω", @"Gamma":@"Γ", @"Delta":@"Δ", @"Theta":@"Θ", @"Lambda":@"Λ", @"Xi":@"Ξ", @"Pi":@"Π", @"Sigma":@"Σ", @"Upsilon":@"Υ", @"Phi":@"Φ", @"Psi":@"Ψ", @"Omega":@"Ω"
             };
}

@end

@implementation LaTexCommander

//--------------------------
//--Primary Executor--------
//--------------------------
+(NSMutableAttributedString *)executeCommandFromComponent:(LaTeXComponent *)comp withString:(NSMutableAttributedString *)in{    
    NSString* command = comp.command;
    //first, look for universal commands
    NSArray* specialCommands = [LaTexCommander commandsSpecial];
    if ([command isEqualToString: @""]){
        [in insertAttributedString:[[NSAttributedString alloc]initWithString:@" "] atIndex:0];
        return in;
    }else if ([specialCommands containsObject:command]){
        return [LaTexCommander executeSpecialCommand:command withString:in];
    }
    
    //check for Math Mode
    if (comp.mathmode){
        return [LaTexCommander executeCommandInMathMode:comp withString:in];
    }else return [LaTexCommander executeCommandInTextMode:comp withString:in];
}

//--------------------------
//--Text Mode Executor------
//--------------------------
+(NSMutableAttributedString *)executeCommandInTextMode:(LaTeXComponent *)comp withString:(NSMutableAttributedString *)in{
    NSString* command = comp.command;
    
    if([LaTexCommander executeDiacriticCommand:command withString:in]) return in;
    else if ([LaTexCommander executeCharTransform:command withString:in treatingLiterally:comp.treatGapLiterally]) return in;
    
    //unsupported default
    [in insertAttributedString:[[NSAttributedString alloc]initWithString:command] atIndex:0];
    return in;
}

//--------------------------
//--Math Mode Executor------
//--------------------------
+(NSMutableAttributedString *)executeCommandInMathMode:(LaTeXComponent *)comp withString:(NSMutableAttributedString *)in{
    NSString* command = comp.command;
    
    if ([LaTexCommander executeMathModeTransforms:command withString:in treatingLiterally:comp.treatGapLiterally]) return in;
    
    //unsupported default
    [in insertAttributedString:[[NSAttributedString alloc]initWithString:command] atIndex:0];
    return in;
}


#pragma mark Commands and Executions: Universal

+(NSMutableAttributedString*)executeSpecialCommand:(NSString*)command withString:(NSMutableAttributedString *)in{
    if ([command isEqualToString:@"\\"]){
        [in insertAttributedString:[[NSAttributedString alloc]initWithString:@"\n"] atIndex:0];
    }else [in insertAttributedString:[[NSAttributedString alloc]initWithString:command] atIndex:0];
    return in;
}

#pragma mark Commands and Executions: Math Mode

+(BOOL)executeMathModeTransforms:(NSString *)command withString:(NSMutableAttributedString *)in treatingLiterally:(BOOL)lit{
    NSDictionary* greekDic = [LaTexCommander commandsGreekLettersMM];
    if([greekDic.allKeys containsObject:command]){
        if (!lit) [LaTexCommander trimOneLeadingWhitespace:in];
        [in insertAttributedString:[[NSAttributedString alloc]initWithString:[greekDic valueForKey:command]] atIndex:0];
        return TRUE;
    }
    return FALSE;
}

#pragma mark Commands and Executions: Text Mode

+(BOOL)executeCharTransform:(NSString *)command withString:(NSMutableAttributedString *)in treatingLiterally:(BOOL)lit{
    NSDictionary* dic = [LaTexCommander commandsCharacterTransforms];
    if (![dic.allKeys containsObject:command]) return FALSE;
    if (!lit) [LaTexCommander trimOneLeadingWhitespace:in];
    NSAttributedString* insertion = [[NSAttributedString alloc]initWithString:[dic valueForKey:command]];
    [in insertAttributedString:insertion atIndex:0];
    return TRUE;
}


#pragma mark String Utility Methods

+(BOOL)executeDiacriticCommand:(NSString *)command withString:(NSMutableAttributedString *)in{ //unicode diacritic goes after the letter;
    NSDictionary* diacriticDic = [LaTexCommander commandsDiacritic];
    if (![diacriticDic.allKeys containsObject:command]) return FALSE;
    
    [LaTexCommander trimLeadingWhitespace:in];
    if ([in.string isEqualToString:@""]){
        [in appendAttributedString:[[NSAttributedString alloc]initWithString:@" "]];
    }
    [in insertAttributedString:[[NSAttributedString alloc]initWithString:[diacriticDic valueForKey:command]] atIndex:1];
    return TRUE;
}


+(void)trimLeadingWhitespace:(NSMutableAttributedString *)in{
    NSCharacterSet* white = [NSCharacterSet whitespaceCharacterSet];
    NSInteger i;
    for (i=0 ;i<in.string.length; i++){
        unichar c = [in.string characterAtIndex:i];
        if (![white characterIsMember:c]) break;
    }
    if (i==0)return;
    else{
        NSRange rng = NSMakeRange(0, i);
        [in deleteCharactersInRange:rng];
    }
}

+(void)trimOneLeadingWhitespace:(NSMutableAttributedString *)in{
    NSCharacterSet* white = [NSCharacterSet whitespaceCharacterSet];
    if (in.length<1) return;
    unichar c= [in.string characterAtIndex:0];
    if ([white characterIsMember:c]){
        [in deleteCharactersInRange:NSMakeRange(0, 1)];
    }
}

@end
