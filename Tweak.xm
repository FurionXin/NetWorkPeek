#import "./sources/FurionUtil.h"
#import <substrate.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#include <string.h>
#include <stdio.h>


#define PeekLog(s,...)   NSLog(@"[NetworkPeek]===>%@",[NSString stringWithFormat:(s),##__VA_ARGS__])


id replace_SSLRead(id context, void *data, size_t dataLength, size_t *processed);
id (*org_SSLRead)(id context, void *data, size_t dataLength, size_t *processed);

id replace_SSLWrite(id context, void *data, size_t dataLength, size_t *processed);
id (*org_SSLWrite)(id context, void *data, size_t dataLength, size_t *processed);

id replace_CFReadStreamCreateForHTTPRequest(id alloc, id request);
id (*org_CFReadStreamCreateForHTTPRequest)(id alloc, id request);

id replace_CFURLRequestCopyAllHTTPHeaderFields(id request);
id (*org_CFURLRequestCopyAllHTTPHeaderFields)(id request);

id replace_CFHTTPMessageCreateRequest(id context, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion);
id (*org_CFHTTPMessageCreateRequest)(id context, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion);


id replace_SSLRead(id context, void *data, size_t dataLength, size_t *processed){
	[FurionUtil logData:data withLength:dataLength];
	return org_SSLRead(context, data, dataLength, processed);
}

id replace_SSLWrite(id context, void *data, size_t dataLength, size_t *processed){
	[FurionUtil logData:data withLength:dataLength];
	return org_SSLWrite(context, data, dataLength, processed);
}

id replace_CFReadStreamCreateForHTTPRequest(id alloc, id request){
	PeekLog(@"%s: %p", __FUNCTION__, request);
    return org_CFReadStreamCreateForHTTPRequest(alloc, request);
}

id replace_CFHTTPMessageCreateRequest(id context, CFStringRef requestMethod, CFURLRef url, CFStringRef httpVersion){
	NSString *reqMethod = (__bridge_transfer NSString *)requestMethod;
    NSURL *requrl = (__bridge_transfer NSURL *)url;
    [FurionUtil logUrl:requrl withMethod:reqMethod];
    return org_CFHTTPMessageCreateRequest(context, requestMethod, url, httpVersion);
}

id replace_CFURLRequestCopyAllHTTPHeaderFields(id request){
    PeekLog(@"%s: %p", __FUNCTION__, request);
    return org_CFURLRequestCopyAllHTTPHeaderFields(request);
}


%hook NSURLConnection

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate{
    // NSLog(@"[LZX] request is------%@",request.URL.absoluteString);
    [FurionUtil logRequest:request];
    return %orig;    
}

+ (id)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate{
    // NSLog(@"[LZX] request is------%@",request.URL.absoluteString);
    [FurionUtil logRequest:request];
    return %orig;
}

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(id*)arg3{
    // NSLog(@"[LZX] request is------%@",request.URL.absoluteString);
    // NSLog(@"[LZX] response is------%@",*response);
    NSData *data = %orig;
    [FurionUtil logRequest:request];
    if(response){
        [FurionUtil logResponse:*response withData:data];
    }
    return %orig;
}

%end



%hook NSURLSession

- (id)dataTaskWithRequest:(NSURLRequest *)request{
    [FurionUtil logRequest:request];
    return %orig;
}

- (id)dataTaskWithURL:(NSURL*)url{
    [FurionUtil logRequest:[NSURLRequest requestWithURL:url]];
    // NSLog(@"[LZX] request is------%@",request.URL.absoluteString);
    return %orig;
}

- (id)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL{
    [FurionUtil logRequest:request];
    return %orig;
}

- (id)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData{
    [FurionUtil logRequest:request];
    return %orig;
}

- (id)uploadTaskWithStreamedRequest:(NSURLRequest *)request{
    [FurionUtil logRequest:request];
    return %orig;
}

- (id)downloadTaskWithRequest:(NSURLRequest *)request{
    [FurionUtil logRequest:request];
    return %orig;
}

- (id)downloadTaskWithURL:(NSURL *)url{
    [FurionUtil logRequest:[NSURLRequest requestWithURL:url]];
    return %orig;
}

- (id)downloadTaskWithResumeData:(NSData *)resumeData{
    return %orig;
}

- (id)streamTaskWithHostName:(NSString *)hostname port:(NSInteger)port{
    return %orig;
}

- (id)streamTaskWithNetService:(NSNetService *)service{
    return %orig;
}

- (id)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler{
    [FurionUtil logRequest:request];
    completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
    	[FurionUtil logResponse:response withData:data];
    };
    return %orig;
}

- (id)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler{
	[FurionUtil logRequest:[NSURLRequest requestWithURL:url]];
	completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
    	[FurionUtil logResponse:response withData:data];
    };
    return %orig;
}

- (id)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler{
	[FurionUtil logRequest:request];
	completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
    	[FurionUtil logResponse:response withData:data];
    };
    return %orig;
}

- (id)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler{
	[FurionUtil logRequest:request];
	completionHandler = ^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error){
    	[FurionUtil logResponse:response withData:data];
    };
    return %orig;
}

- (id)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler{
	[FurionUtil logRequest:request];
	completionHandler = ^(NSURL * _Nullable url, NSURLResponse * _Nullable response, NSError * _Nullable error){
    	[FurionUtil logResponse:response withData:nil];
    };
    return %orig;
}

- (id)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler{
	[FurionUtil logRequest:[NSURLRequest requestWithURL:url]];
	return %orig;
}

- (id)downloadTaskWithResumeData:(NSData *)resumeData completionHandler:(void (^)(NSURL *, NSURLResponse *, NSError *))completionHandler{
	completionHandler = ^(NSURL * _Nullable url, NSURLResponse * _Nullable response, NSError * _Nullable error){
		[FurionUtil logRequest:[NSURLRequest requestWithURL:url]];
    	[FurionUtil logResponse:response withData:nil];
    };
    return %orig;
}

%end



%hook NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
	[FurionUtil logResponse:dataTask.response withData:data];
	%orig;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(id /* block */)arg4{
	[FurionUtil logResponse:response withData:nil];
	%orig;
}

%end



%hook UIApplication

- (BOOL)canOpenURL:(NSURL *)url{
	PeekLog(@"%s: %@", __FUNCTION__, url);
	return %orig;
}

- (BOOL)openURL:(NSURL *)url{
	PeekLog(@"%s: %@", __FUNCTION__, url);
	return %orig;
}

%end



%hook UIWebView
- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType textEncodingName:(NSString *)encodingName baseURL:(NSURL *)baseURL{
	PeekLog(@"%s: %@", __FUNCTION__, baseURL);
	[FurionUtil LogWebView:self];
	%orig;
}

- (void)loadHTMLString:(NSString *)arg1 baseURL:(NSURL *)baseURL{
	PeekLog(@"%s: %@", __FUNCTION__, baseURL);
	[FurionUtil LogWebView:self];
	%orig;
}

- (void)loadRequest:(NSURLRequest *)request{
	PeekLog(@"%s: %@", __FUNCTION__, request);
	[FurionUtil LogWebView:self];
	%orig;
}
%end


%hook __NSCFURLProtocolClient_NS
- (void)URLProtocol:(id)protocol didLoadData:(NSData *)data
{
    [FurionUtil logProtocol:(NSURLProtocol*)protocol withData:data];
    %orig;
}
%end



%ctor
{
	@autoreleasepool
	{
		void *_sslread = MSFindSymbol(NULL, "_SSLRead");
		MSHookFunction((void *)_sslread, (void *)replace_SSLRead, (void **)&org_SSLRead);
		void *_sslwrite = MSFindSymbol(NULL, "_SSLWrite");
		MSHookFunction((void *)_sslwrite, (void *)replace_SSLWrite, (void **)&org_SSLWrite);
		void *_CFReadStreamCreateForHTTPRequest = MSFindSymbol(NULL, "_CFReadStreamCreateForHTTPRequest");
		MSHookFunction((void *)_CFReadStreamCreateForHTTPRequest, (void *)replace_CFReadStreamCreateForHTTPRequest, (void **)&org_CFReadStreamCreateForHTTPRequest);
		void *_CFURLRequestCopyAllHTTPHeaderFields = MSFindSymbol(NULL, "_CFURLRequestCopyAllHTTPHeaderFields");
		MSHookFunction((void *)_CFURLRequestCopyAllHTTPHeaderFields, (void *)replace_CFURLRequestCopyAllHTTPHeaderFields, (void **)&org_CFURLRequestCopyAllHTTPHeaderFields);
	    void *_CFHTTPMessageCreateRequest = MSFindSymbol(NULL, "_CFHTTPMessageCreateRequest");
        MSHookFunction((void *)_CFHTTPMessageCreateRequest, (void *)replace_CFHTTPMessageCreateRequest, (void **)&org_CFHTTPMessageCreateRequest);
    }
}


