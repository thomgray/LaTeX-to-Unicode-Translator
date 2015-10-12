//
//  LaTexCommander.h
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LaTeXComponent.h"

@interface LaTexCommander : NSObject

+(NSMutableAttributedString*)executeCommandFromComponent:(LaTeXComponent*)comp withString:(NSMutableAttributedString*)in;

@end
