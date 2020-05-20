//
//  FurionUtil.h
//  getInfo
//
//  Created by FurionLiu on 2020/5/8.
//  Copyright © 2020 FurionLiu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>



@interface FurionUtil : NSObject

+ (void)LogWebView:(UIWebView *)webView;
+ (NSURLRequest *)logRequest:(NSURLRequest *)request;
+ (NSURLResponse *)logResponse:(NSURLResponse *)response withData:(NSData *)data;
+ (const void *)logData:(const void *)data withLength:(size_t)datalength;
+ (void)logUrl:(NSURL *)url withMethod:(NSString *)method;
+ (void)logProtocol:(NSURLProtocol *)protocol withData:(NSData *)data;

@end

