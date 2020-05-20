//
//  FurionUtil.m
//  getInfo
//
//  Created by FurionLiu on 2020/5/8.
//  Copyright © 2020 FurionLiu. All rights reserved.
//

#import "FurionUtil.h"
#import <dlfcn.h>
#import <execinfo.h>
#import <unistd.h>
#import <UIKit/UIKit.h>
#import "NSUtil.h"
#import "NSData+GZIP.h"


#define SIZE 200
#define PeekLog(s,...)   NSLog(@"[NetworkPeek]===>%@",[NSString stringWithFormat:(s),##__VA_ARGS__])

@interface WebViewDelegate: NSObject <UIWebViewDelegate>
@end

NSMutableDictionary *_delegates;
WebViewDelegate *_webViewDelegate;

@implementation WebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{
    [FurionUtil logRequest:request];
    PeekLog(@"%s: %@, %@, navigationType:%d", __FUNCTION__, webView, [request.URL.absoluteString stringByRemovingPercentEncoding], (int)navigationType);
    id<UIWebViewDelegate> delegate = [_delegates objectForKey:[NSString stringWithFormat:@"%p", webView]];
    return [delegate respondsToSelector:@selector(webView: shouldStartLoadWithRequest: navigationType:)] ? [delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType] : YES;
}

//
- (void)webViewDidStartLoad:(UIWebView *)webView;
{
    PeekLog(@"%s: %@", __FUNCTION__, webView);
    id<UIWebViewDelegate> delegate = [_delegates objectForKey:[NSString stringWithFormat:@"%p", webView]];
    if ([delegate respondsToSelector:@selector(webViewDidStartLoad:)]) [delegate webViewDidStartLoad:webView];
}

//
- (void)webViewDidFinishLoad:(UIWebView *)webView;
{
    PeekLog(@"%s: %@", __FUNCTION__, webView);
    id<UIWebViewDelegate> delegate = [_delegates objectForKey:[NSString stringWithFormat:@"%p", webView]];
    if ([delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) [delegate webViewDidFinishLoad:webView];
}

//
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error;
{
    PeekLog(@"%s: %@", __FUNCTION__, webView);
    id<UIWebViewDelegate> delegate = [_delegates objectForKey:[NSString stringWithFormat:@"%p", webView]];
    if ([delegate respondsToSelector:@selector(webView: didFailLoadWithError:)]) [delegate webView:webView didFailLoadWithError:error];
}

@end


NSString *logFilePath(NSString *fileName, NSString *extName){
    static NSString *logDir = nil;
    for (int i = 0; /*i < 3*/; i++)
    {
        NSString *temp;
        switch (i)
        {
            default: temp = @"/tmp"; break;
            case 1: temp = NSDocumentPath(); break;
            case 2: temp = NSTemporaryDirectory(); break;
        }
        logDir = [[NSString alloc] initWithFormat:@"%@/%@.req", temp, NSProcessInfo.processInfo.processName];
        BOOL ret = [[NSFileManager defaultManager] createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
        if (ret)
        {
            PeekLog(@"LOG to dir: %@", temp);
            break;
        }
        else if (i == 2)
        {
            PeekLog(@"ERROR!!! Could not create log dir: %@", temp);
            break;
        }
    }
    static int _index = 0;
    return [NSString stringWithFormat:@"%@/%03d-%@.%@", logDir, _index++, fileName, extName];
}


void logInfoData(NSString *info, NSURL *URL, NSData *data, NSString *typeName){
    
    NSString *logPath = logFilePath(NSUrlToFilename([URL.host stringByAppendingString:URL.path]),[typeName stringByAppendingString:@".txt"]);
    data = [data gunzippedData];
    if(data.length && data.length < 10240){
        NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(content){
            [[info stringByAppendingString:content] writeToFile:logPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
            PeekLog(@"%@ With Text Content: %@\n%@\n\n",typeName,info,content);
            return;
        }
    }
    PeekLog(@"%@: %@\n", typeName, info);
    [info writeToFile:logPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    if(data.length){
        PeekLog(@"With Binay Content <%d Bytes>", (int)data.length);
        [data writeToFile:[logPath stringByAppendingString:@".dat"] atomically:NO];
    }
    
}

NSString *printfStackInfo(){
    NSArray<NSString*> *stackAddr = [NSThread callStackSymbols];
    NSString *stackinfo = @"";
    if(stackAddr){
        PeekLog(@"callStackSymbols success");
        stackinfo = [NSString stringWithFormat:@"%@",stackAddr];
    }else{
        void *stackAdresses[200];
        char **strings;
        int stackSize,j;
        stackSize = backtrace(stackAdresses, 200);
        printf("backtrace() returned %d addresses\n", stackSize);
        strings = backtrace_symbols(stackAdresses, stackSize);
        NSMutableString *stack = [[NSMutableString alloc] initWithCapacity:200];
        for (j = 0; j < stackSize; j++){
            NSString *stackline = [NSString stringWithUTF8String:strings[j]];
            [stack appendString:stackline];
            [stack appendString:@"\n"];
        }
        stackinfo = [NSString stringWithFormat:@"%@",stack];
    }
    return stackinfo;
}



@implementation FurionUtil

+ (void)LogWebView:(UIWebView *)webView{
    [_delegates setValue:webView.delegate forKey:[NSString stringWithFormat:@"%p", webView]];
    webView.delegate = _webViewDelegate;
}

+ (const void *)logData:(const void *)data withLength:(size_t)datalength{
    if(data == nil || datalength == 0){
        return data;
    }
    Dl_info info = {0};
    dladdr(__builtin_return_address(0), &info);
    NSString *str = [NSString stringWithFormat:@"FROM %s(%p)---%s(%p=>%#08lx)\n<%@>\n\nStack Log==>\n%@", info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000, @"", printfStackInfo()];
    PeekLog(@"DATA: %@\n",str);
    NSMutableData *dat = [NSMutableData dataWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];
    [dat appendBytes:data length:datalength];
    NSString *txt = [[NSString alloc] initWithBytesNoCopy:(void *)data length:datalength encoding:NSUTF8StringEncoding freeWhenDone:NO];
    if(txt)
        PeekLog(@"%@\n\n", txt);
    return data;
}

+ (void)logProtocol:(NSURLProtocol *)protocol withData:(NSData *)data{
    NSURLRequest *req = protocol.request;
    [FurionUtil logRequest:req];
    Dl_info info = {0};
    dladdr(__builtin_return_address(0), &info);
    NSString *str = [NSString stringWithFormat:@"From %s(%p)---%s(%p=>%#08lx)\nStack Log==>\n%@",info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000, printfStackInfo()];
    logInfoData(str, req.URL, data, @"RESPONSE");
}

+ (void)logUrl:(NSURL *)url withMethod:(NSString *)method{
    Dl_info info = {0};
    dladdr(__builtin_return_address(0), &info);
    NSString *str = [NSString stringWithFormat:@"From %s(%p)---%s(%p=>%#08lx)\n<%@>\n%@: %@\n\nStack Log==>\n%@",info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000,@" ",method, url, printfStackInfo()];
    logInfoData(str, url, [method dataUsingEncoding:NSUTF8StringEncoding], @"REQUEST");
}

+ (NSURLRequest *)logRequest:(NSURLRequest *)request{
    if(![request respondsToSelector:@selector(HTTPMethod)]){
        PeekLog(@"NOT HTTP Request!");
        return request;
    }
    Dl_info info = {0};
    dladdr(__builtin_return_address(0), &info);
    NSString *str = [NSString stringWithFormat:@"From %s(%p)---%s(%p=>%#08lx)\n<%@>\n%@: %@\n%@\n\nStack Log==>\n%@",info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000,@" ",request.HTTPMethod, request.URL.absoluteURL, request.allHTTPHeaderFields ? request.allHTTPHeaderFields : @"", printfStackInfo()];
    logInfoData(str, request.URL, request.HTTPBody, @"REQUEST");
    return request;
}


+ (NSURLResponse *)logResponse:(NSURLResponse *)response withData:(NSData *)data{
    PeekLog(@"LogResponse: %@",response);
    Dl_info info = {0};
    dladdr(__builtin_return_address(0), &info);
    NSString *str = [NSString stringWithFormat:@"From %s(%p)---%s(%p=>%#08lx)\nResponse:%@\nStack Log==>\n%@",info.dli_fname, info.dli_fbase, info.dli_sname, info.dli_saddr, (long)info.dli_saddr-(long)info.dli_fbase-0x1000,response.description, printfStackInfo()];
    logInfoData(str, response.URL, data, @"RESPONSE");
    return response;

}

@end








