//
//  UnicodeString.h
//  LaTeX
//
//  Created by Thomas Gray on 12/10/2015.
//  Copyright © 2015 Thomas Gray. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UnicodeString : NSObject

@property NSMutableAttributedString* unicodeString;
@property NSMutableArray<NSMutableAttributedString*>* lines;


-(instancetype)initWithString:(NSAttributedString*)str;

+(NSString*)translateAttributedString:(NSAttributedString*)str;
+(NSString*)translateString:(NSString *)str;
    
@end
