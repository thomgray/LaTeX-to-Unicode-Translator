//
//  main.m
//  LaTeX
//
//  Created by Thomas Gray on 01/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LaTeXComponent.h"
#import "LaTeXString.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSString* str = @"$\\alpha \\beta$ blah blah blah \n\n something else \n goes here";
        LaTeXString* latexString = [[LaTeXString alloc]initWithString:str];
        
        NSLog(@"%@", [latexString toString].string);
    }
    return 0;
}
