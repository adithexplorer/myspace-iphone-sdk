//
//  NSMutableURLRequest+Parameters.m
//
//  Created by Jon Crosby on 10/19/07.
//  Copyright 2007 Kaboomerang LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


#import "NSMutableURLRequest+Parameters.h"

#import "NSURL+Base.h"
#import "OARequestParameter.h"

@implementation NSMutableURLRequest (OAParameterAdditions)

- (NSArray*) parameters {
    NSString* encodedParameters;

    if ([self.HTTPMethod isEqualToString:@"GET"] ||
        [self.HTTPMethod isEqualToString:@"DELETE"]) {
        encodedParameters = self.URL.query;
    } else if ([[[self allHTTPHeaderFields] valueForKey:@"Content-Type"] isEqualToString:@"application/x-www-form-urlencoded"]){
        // POST, PUT
        encodedParameters = [[[NSString alloc] initWithData:self.HTTPBody
                                                   encoding:NSASCIIStringEncoding] autorelease];
    }
	else
		encodedParameters = self.URL.query;
    if (encodedParameters.length == 0) {
        return nil;
    }

    NSArray* encodedParameterPairs = [encodedParameters componentsSeparatedByString:@"&"];
    NSMutableArray* requestParameters = [NSMutableArray array];

    for (NSString* encodedPair in encodedParameterPairs) {
        NSArray* encodedPairElements = [encodedPair componentsSeparatedByString:@"="];
        OARequestParameter* parameter = [OARequestParameter parameterWithName:[[encodedPairElements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                                        value:[[encodedPairElements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [requestParameters addObject:parameter];
    }

    return requestParameters;
}

- (void) setParameters:(NSArray*) parameters {
    NSMutableString* encodedParameterPairs = [NSMutableString string];

    int position = 1;
    for (OARequestParameter* requestParameter in parameters) {
        [encodedParameterPairs appendString:[requestParameter URLEncodedNameValuePair]];
        if (position < parameters.count) {
            [encodedParameterPairs appendString:@"&"];
        }
        position++;
    }

    if ([self.HTTPMethod isEqualToString:@"GET"] ||
        [self.HTTPMethod isEqualToString:@"DELETE"]) {
        [self setURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", [self.URL URLStringWithoutQuery], encodedParameterPairs]]];
    } else {
        // POST, PUT
        NSData* postData = [encodedParameterPairs dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
        [self setHTTPBody:postData];
        [self setValue:[NSString stringWithFormat:@"%d", postData.length] forHTTPHeaderField:@"Content-Length"];
        [self setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    }
}

@end