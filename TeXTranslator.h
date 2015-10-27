//
//  TeXTranslator.h
//  LaTeX
//
//  Created by Thomas Gray on 15/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TeXTranslator : NSObject

+(NSAttributedString*)translateTexToAttributedString:(NSString*)texString;
+(NSString*)translateAttributedStringToTex:(NSAttributedString*)unicodeString;
+(NSString*)translateStringToTex:(NSString *)unicodeString;


@end
