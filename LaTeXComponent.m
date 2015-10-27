
//
//  LaTeXComponent.m
//  LaTeX
//
//  Created by Thomas Gray on 11/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import "LaTeXComponent.h"
#import "LaTexCommander.h"

//extern NSString* newLine =@"\\LaTeXNewLine";
#define _newLine @"\\LaTeXNewLine"
#define LaTexMathModeConst @"\\mathMode"

@interface LaTeXComponent (Private)

-(void)initComponentsWithSource:(NSString*)str;

-(NSInteger)parseComponent:(NSString*)source atIndex:(NSInteger)i;
-(NSRange)rangeOfNextWord:(NSString*)str fromIndex:(NSInteger)i including:(BOOL)inc;
-(NSRange)rangeOfBraces:(NSString*)str fromIndex:(NSInteger)i includingBraces:(BOOL)inc;
-(NSArray<NSValue*>*)rangesOfCommandAndArgument:(NSString*)str fromIndex:(NSInteger)i;

-(NSMutableAttributedString*)configureString:(NSMutableAttributedString*)str;

@end

@implementation LaTeXComponent
@synthesize command;
@synthesize components;
@synthesize mathmode;
@synthesize treatGapLiterally;

-(instancetype)initWithString:(NSString *)str{
    self = [super init];
    if (self) {
        [self initComponentsWithSource:str];
    }
    return self;
}

-(instancetype)initWithString:(NSString *)str andCommand:(NSString *)cmmd inheritingFrom:(LaTeXComponent *)parent{
    self =[super init];
    if (self) {
        if ([cmmd isEqualToString:LaTexMathModeConst]) {
            mathmode = YES;
        }else{
            mathmode = parent? parent.mathmode:NO;
            command = [cmmd substringFromIndex:1];
        }
        [self initComponentsWithSource:str];
    }
    return self;
}


-(void)initComponentsWithSource:(NSString *)str{
    components = [[NSMutableArray alloc]init];
    NSInteger n = 0;
    for (NSInteger i=0; i<str.length;) {
        unichar c = [str characterAtIndex:i];
        if (c=='{' || c=='\\' || c=='$'){
            if (i>n){
                NSRange rng = NSMakeRange(n, i-n);
                NSMutableAttributedString* stringComp = [[NSMutableAttributedString alloc]initWithString:[str substringWithRange:rng]];
                [components addObject:stringComp];
            }
            i = [self parseComponent:str atIndex:i];
            n=i;
            continue;
        }
        
        if (i==str.length-1) {
            NSRange rng = NSMakeRange(n, i-n+1);
            NSMutableAttributedString* stringComp = [[NSMutableAttributedString alloc]initWithString:[str substringWithRange:rng]];
            [components addObject:stringComp];
            break;
        }
        i++;
    }
}

//return must be the end of the component (not after unless intentional)
-(NSInteger)parseComponent:(NSString *)source atIndex:(NSInteger)i{
    unichar c = [source characterAtIndex:i];
    if (c=='{') {
        NSRange rng = [self rangeOfBraces:source fromIndex:i includingBraces:YES];
        if (rng.length) {
            NSRange innerRange = NSMakeRange(rng.location+1, rng.length-2);
            NSString* argString = [source substringWithRange:innerRange];
            LaTeXComponent* newcomp = [[LaTeXComponent alloc]initWithString:argString andCommand:nil inheritingFrom:self];
            [components addObject:newcomp];
            return rng.location+rng.length;
        }else @throw [NSException exceptionWithName:@"Malfored" reason:@"Brace doesn't end" userInfo:@{@"Components":components, @"String":source}];
    }else if (c=='\\'){
        NSArray<NSValue*>* ranges = [self rangesOfCommandAndArgument:source fromIndex:i];
        NSRange commandRng = [ranges.firstObject rangeValue];
        NSString* commandStr = [source substringWithRange:commandRng];
        NSString* arg = nil;
        NSRange argRange = [ranges.lastObject rangeValue];
        if (argRange.location==0 && argRange.length==0) @throw [NSException exceptionWithName:@"F-Up" reason:@"Argument range is effective null, and infinite loop threatens" userInfo:nil];
        BOOL argInBraces;
        if (argRange.length){
            arg = [source substringWithRange:argRange];
            if ([arg characterAtIndex:0]=='{' && [arg characterAtIndex:arg.length-1]=='}') {
                arg = [arg substringWithRange:NSMakeRange(1, arg.length-2)];
                argInBraces = TRUE;
            }else{
                NSInteger begin= commandRng.location+commandRng.length;
                NSInteger end = argRange.location+argRange.length;
                argRange = NSMakeRange(begin, end-begin);
                arg = [source substringWithRange:argRange];
                argInBraces = FALSE;
            }
        }
        
        LaTeXComponent* newcomp = [[LaTeXComponent alloc]initWithString:arg andCommand:commandStr inheritingFrom:self];
        newcomp.treatGapLiterally = argInBraces;
        [components addObject:newcomp];
        i = [ranges.lastObject rangeValue].location+[ranges.lastObject rangeValue].length;
        return i;
    }else if (c=='$'){
        i++;
        for (NSInteger j=i+1; j<source.length; j++) {
            unichar d = [source characterAtIndex:j];
            if (d=='$') {
                NSRange mmrange = NSMakeRange(i, j-i);
                NSString* mmstring= [source substringWithRange:mmrange];
                LaTeXComponent* newcomp  = [[LaTeXComponent alloc]initWithString:mmstring andCommand:LaTexMathModeConst inheritingFrom:self];
                [components addObject:newcomp];
                return j+1;
            }else if (j==source.length-1){
                @throw [NSException exceptionWithName:@"Malformed" reason:@"MathMode doesn't end" userInfo:@{@"Components":components, @"String":source}];
            }
        }
    }
    @throw [NSException exceptionWithName:@"Illegal Argument" reason:@"parseComponent method requires index on a { $ or \\ character" userInfo:@{@"String":source, @"Components":components}];
}

-(NSRange)rangeOfNextWord:(NSString *)str fromIndex:(NSInteger)i including:(BOOL)inc{
    NSMutableCharacterSet* delimits = [NSMutableCharacterSet whitespaceCharacterSet];
    [delimits addCharactersInString:@"{}\\$"];
    //prime..
here:
    if ([delimits characterIsMember:[str characterAtIndex:i]]) {
        i++;
        while (true) {
            unichar c = [str characterAtIndex:i];
            if(![delimits characterIsMember:c]) break;
            if (i==str.length-1) return NSMakeRange(0, 0);
            i++;
        }
    }else if(!inc){
        inc=TRUE;
        i++;
        while (true) {
            unichar c = [str characterAtIndex:i];
            if ([delimits characterIsMember:c]) {
                goto here;
            }else if (i==str.length-1) return NSMakeRange(0, 0);
            i++;
        }
    }
    //now we are definitely on a word;
    for (NSInteger j=i; j<str.length; j++) {
        unichar c= [str characterAtIndex:j];
        if ([delimits characterIsMember:c]){
            return NSMakeRange(i, j-i);
        }else if (j==str.length-1){
            return NSMakeRange(i, j-i+1);
        }
    }
    return NSMakeRange(0, 0);
}

-(NSRange)rangeOfBraces:(NSString *)str fromIndex:(NSInteger)i includingBraces:(BOOL) inc{
    if ([str characterAtIndex:i]!='{') return NSMakeRange(0, 0);
    int lr=1;
    unichar prev = i>0? [str characterAtIndex:i-1]:'n';
    for (NSInteger j=i+1; j<str.length; j++) {
        unichar c = [str characterAtIndex:j];
        if (c=='{'&& prev!='\\') lr++;
        else if (c=='}' && prev!='\\') lr--;
        
        if(lr==0){
            return inc? NSMakeRange(i, j-i+1) : NSMakeRange(i+1, j-i-1);
        }
        
        prev = c;
    }
    return NSMakeRange(0, 0);
}

-(NSRange)rangeOfArgument:(NSString*)str fromIndex:(NSInteger)i{
    for (; i<str.length; i++) {
        unichar c = [str characterAtIndex:i];
        if (![[NSCharacterSet whitespaceCharacterSet]characterIsMember:c]) break;
    }
    if (i>=str.length) return NSMakeRange(str.length, 0);
    for (; i<str.length; i++) {
        unichar c = [str characterAtIndex:i];
        if ([[NSCharacterSet whitespaceCharacterSet]characterIsMember:c]) continue;
        else if(i==str.length-1) return NSMakeRange(i, 1);
        
        if (c=='{') {
            return [self rangeOfBraces:str fromIndex:i includingBraces:YES];
        }else if(c=='\\'){
            NSArray<NSValue*>* arr = [self rangesOfCommandAndArgument:str fromIndex:i];
            NSRange r1 = [arr.firstObject rangeValue];
            NSRange r2 = [arr.lastObject rangeValue];
            NSInteger length = r2.location-r1.location+r2.length;
            return NSMakeRange(r1.location, length);
        }else if (c=='$'){
            return NSMakeRange(i-1, 0);
        }else{
            return [self rangeOfNextWord:str fromIndex:i including:YES];
        }
    }
    return NSMakeRange(i, 0);
}

//return ranges including the initial \ character of command
-(NSArray<NSValue*> *)rangesOfCommandAndArgument:(NSString *)str fromIndex:(NSInteger)i{
    NSRange commandRange;
    NSRange argRange;
    //prime: make sure we are on a command
    if ([str characterAtIndex:i]!='\\') return nil;
    if (i==str.length-1){ //in case this is the final char
        commandRange = NSMakeRange(i, 1); argRange = NSMakeRange(i+1, 0);
        //NSLog(@"Found Command: %@ with arg: %@", [str substringWithRange:commandRange], [str substringWithRange:argRange]);
        return [NSArray arrayWithObjects:[NSValue valueWithRange:commandRange], [NSValue valueWithRange:argRange], nil];
    }
    unichar c = [str characterAtIndex:i+1];
    //first, sort out a few trouble cases:
    //special characters
    NSCharacterSet* specials = [LaTeXComponent charactersSpecialEscape];
    NSCharacterSet* alpabetic = [LaTeXComponent charactersAlphabetic];
    if ([[NSCharacterSet whitespaceCharacterSet]characterIsMember:c]){ // a standalone backslash
        commandRange = NSMakeRange(i, 1); argRange = NSMakeRange(i+1, 0);
        //NSLog(@"Found Command: %@ with arg: %@", [str substringWithRange:commandRange], [str substringWithRange:argRange]);
        return [NSArray arrayWithObjects:[NSValue valueWithRange:commandRange], [NSValue valueWithRange:argRange], nil];
    }
    //special excape don't take arguments or require space e.g. \{
    else if ([specials characterIsMember:c]) {
        commandRange = NSMakeRange(i, 2);
        argRange = NSMakeRange(i+2, 0);
        //NSLog(@"Found Command: %@ with arg: %@", [str substringWithRange:commandRange], [str substringWithRange:argRange]);
        return [NSArray arrayWithObjects:[NSValue valueWithRange:commandRange], [NSValue valueWithRange:argRange], nil];
    }
    //symbolicCommands break immediately, but may take an arg, e.g.\"
    else if (![alpabetic characterIsMember:c]){
        commandRange = NSMakeRange(i, 2);
        NSInteger j=i+2; //index just after the command
        argRange= [self rangeOfArgument:str fromIndex:j];
        //NSLog(@"Found Command: %@ with arg: %@", [str substringWithRange:commandRange], [str substringWithRange:argRange]);
        return [NSArray arrayWithObjects:[NSValue valueWithRange:commandRange], [NSValue valueWithRange:argRange], nil];
    }

    commandRange = [self rangeOfNextWord:str fromIndex:i+1 including:YES];
    commandRange = NSMakeRange(commandRange.location-1, commandRange.length+1);
    NSInteger j=commandRange.location+commandRange.length;
    argRange = [self rangeOfArgument:str fromIndex:j];
    //NSLog(@"Found Command: %@ with arg: %@", [str substringWithRange:commandRange], [str substringWithRange:argRange]);
    return [NSArray arrayWithObjects:[NSValue valueWithRange:commandRange], [NSValue valueWithRange:argRange], nil];
}


-(NSMutableAttributedString *)toString{
    NSMutableAttributedString* out = [[NSMutableAttributedString alloc]init];
    for (NSInteger i=0; i<components.count; i++){
        id thing = [components objectAtIndex:i];
        if ([thing isMemberOfClass:[LaTeXComponent class]]) {
            LaTeXComponent* compThing = (LaTeXComponent*)thing;
            NSAttributedString* stringThing = [compThing toString];
            [out appendAttributedString:stringThing];
        }else{
            NSAttributedString* stringThing = (NSAttributedString*)thing;
            [out appendAttributedString:stringThing];
        }
    }
    out = [self configureString:out];
    return out;
}


-(NSMutableAttributedString *)configureString:(NSMutableAttributedString *)str{
    if (!command) return str;
    else return [LaTexCommander executeCommandFromComponent:self withString:str];
}

-(void)test{
    
}

-(void)print{
    if (command) {
        NSLog(@"Command: %@;", command);
    }
    for (NSInteger i=0; i<components.count; i++){
        id thing =[components objectAtIndex:i];
        if ([thing isMemberOfClass:[LaTeXComponent class]]) {
            [(LaTeXComponent*)thing print];
        }else{
            NSAttributedString* str = (NSAttributedString*)thing;
            NSLog(@"%@", str.string);
        }
    }
}

+(NSCharacterSet *)charactersSpecialEscape{
    return [NSCharacterSet characterSetWithCharactersInString:@"$%_{}&#\\"];
}
+(NSCharacterSet *)charactersAlphabetic{
    return [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"];
}













@end
