//
//  LaTeXString.h
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LaTeXComponent.h"

@interface LaTeXString : NSObject

@property NSArray<LaTeXComponent*>* lines;

-(instancetype)initWithString:(NSString*)str;

-(NSAttributedString*)toString;

+(instancetype)LaTeXStringWithString:(NSString*)str;

+(NSAttributedString*)translateString:(NSString*)str;

@end
