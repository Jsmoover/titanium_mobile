/**
 * Appcelerator APSHTTPClient Library
 * Copyright (c) 2014 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, APSRequestError) {
	APSRequestErrorCancel = 0
};


@class APSHTTPResponse;
@class APSHTTPRequest;
@class APSHTTPPostForm;

@protocol APSConnectionDelegate <NSURLConnectionDelegate>
@optional
-(BOOL)willHandleChallenge:(NSURLAuthenticationChallenge *)challenge forConnection:(NSURLConnection *)connection;
@end

@protocol APSHTTPRequestDelegate <NSObject>
@optional
-(void)request:(APSHTTPRequest*)request onLoad:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onError:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onDataStream:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onSendStream:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onReadyStateChange:(APSHTTPResponse*)response;
-(void)request:(APSHTTPRequest*)request onRedirect:(APSHTTPResponse*)response;

-(void)request:(APSHTTPRequest*)request onRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
-(void)request:(APSHTTPRequest*)request onUseAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge;
- (BOOL)request:(APSHTTPRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (BOOL)request:(APSHTTPRequest *)request connectionShouldUseCredentialStorage:(NSURLConnection *)connection;

@end

@interface APSHTTPRequest : NSObject

@property(nonatomic, strong, readwrite) NSURL                            *url;
@property(nonatomic, strong, readwrite) NSString                         *method;
@property(nonatomic, strong, readwrite) NSString                         *filePath;
@property(nonatomic, strong, readwrite) NSString                         *requestUsername;
@property(nonatomic, strong, readwrite) NSString                         *requestPassword;
@property(nonatomic, strong, readwrite) APSHTTPPostForm                  *postForm;
@property(nonatomic, strong, readonly ) APSHTTPResponse                  *response;
@property(nonatomic, weak,   readwrite) NSObject<APSHTTPRequestDelegate> *delegate;
@property(nonatomic, weak,   readwrite) NSObject<APSConnectionDelegate>  *connectionDelegate;
@property(nonatomic, assign, readwrite) NSTimeInterval                   timeout;
@property(nonatomic, assign, readwrite) BOOL                             sendDefaultCookies;
@property(nonatomic, assign, readwrite) BOOL                             redirects;
@property(nonatomic, assign, readwrite) BOOL                             synchronous;
@property(nonatomic, assign, readwrite) BOOL                             validatesSecureCertificate;
@property(nonatomic, assign, readwrite) BOOL                             cancelled;
@property(nonatomic, strong, readwrite) NSOperationQueue                 *theQueue;
@property(nonatomic, assign, readwrite) NSURLRequestCachePolicy          cachePolicy;
@property(nonatomic, assign, readwrite) BOOL 							 showActivity;
@property(nonatomic, strong, readwrite) NSURLAuthenticationChallenge	 *authenticationChallenge;
@property(nonatomic, strong, readwrite) NSURLCredential					 *challengedCredential;
@property (nonatomic)                   NSURLCredentialPersistence       persistence;
@property(nonatomic, strong, readonly)  NSMutableURLRequest              *request;
@property(nonatomic, assign, readwrite) int                              authRetryCount;
// Only used in Titanium ImageLoader
@property(nonatomic, strong, readwrite) NSDictionary                     *userInfo;

-(void)send;
-(void)abort;
-(void)addRequestHeader:(NSString*)key value:(NSString*)value;
-(void)prepareAndSendFromDictionary:(NSDictionary*)dict;
@end
