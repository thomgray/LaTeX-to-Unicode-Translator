//
//  LaTeXString.m
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import "LaTeXString.h"

@interface LaTeXString (Private)

-(NSArray<NSString*>*)fixNewLinesInString:(NSString*)str;

@end

@implementation LaTeXString

@synthesize lines;

-(instancetype)initWithString:(NSString *)str{
    self = [super init];
    if (self) {
        NSArray* stringLines = [self fixNewLinesInString:str];
        //NSLog(@"%@", stringLines);
        NSMutableArray* componenets = [[NSMutableArray alloc]init];
        for (NSInteger i=0; i<stringLines.count; i++){
            NSString * line = [stringLines objectAtIndex:i];
            [componenets addObject:[[LaTeXComponent alloc]initWithString:line]];
        }
        lines = [[NSArray alloc]initWithArray:componenets];
    }
    return self;
}

-(NSAttributedString *)toString{
    NSMutableAttributedString* out = [[NSMutableAttributedString alloc]init];
    for (NSInteger i=0; i<lines.count; i++) {
        LaTeXComponent* comp = [lines objectAtIndex:i];
        NSMutableAttributedString* aStr = [comp toString];
        if (i<lines.count-1){
            [aStr appendAttributedString:[[NSAttributedString alloc]initWithString:@"\n"]] ;
            [out appendAttributedString:aStr];
        }else [out appendAttributedString:aStr];
    }
    return [[NSAttributedString alloc]initWithAttributedString:out];
}

+(instancetype)LaTeXStringWithString:(NSString *)str{
    return [[LaTeXString alloc]initWithString:str];
}


+(NSAttributedString *)translateString:(NSString *)str{
    LaTeXString* out = [[LaTeXString alloc]initWithString:str];
    return [out toString];
}

#pragma  mark Private Methods

-(NSArray<NSString*>*)fixNewLinesInString:(NSString *)str{
    NSArray* theseLines = [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray* lineTemp = [[NSMutableArray alloc]initWithCapacity:theseLines.count];
    for (NSInteger i=0; i<theseLines.count; i++) {
        NSString* str = [theseLines objectAtIndex:i];
        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        [lineTemp addObject:str];
    }
    theseLines = [NSArray arrayWithArray:lineTemp];
    NSMutableArray* newLines = [[NSMutableArray alloc]init];
    BOOL addnext = TRUE;
    for (NSInteger i=0; i<theseLines.count; i++) {
        NSString* currentline = [newLines lastObject];
        NSString* thisLine = [theseLines objectAtIndex:i];
        BOOL isempty = TRUE;
        for (NSInteger j=0; j<thisLine.length; j++) {
            unichar c = [thisLine characterAtIndex:j];
            if (![[NSCharacterSet whitespaceCharacterSet]characterIsMember:c]){
                isempty = FALSE;
                break;
            }
        }
        //if there is no line yet, add the current line if non-empty and continue;
        if (!currentline) {
            if (!isempty){
                [newLines addObject:thisLine];
                addnext = FALSE;
            }
            continue;
        }
        //othrwise...
        if (isempty){
            addnext = TRUE;
            continue;
        }
        if (addnext) {
            [newLines addObject:thisLine];
            addnext = FALSE;
        }else{
            NSString* appendedString;
            if ([[NSCharacterSet whitespaceCharacterSet]characterIsMember:[currentline characterAtIndex:currentline.length-1]]) {
                appendedString = [currentline stringByAppendingString:thisLine];
            }else appendedString = [currentline stringByAppendingFormat:@" %@", thisLine];
            [newLines replaceObjectAtIndex:newLines.count-1 withObject:appendedString];
        }
    }
    
    return [NSArray arrayWithArray:newLines];
}


@end
