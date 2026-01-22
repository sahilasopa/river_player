// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "BetterPlayerEzDrmAssetsLoaderDelegate.h"

@implementation BetterPlayerEzDrmAssetsLoaderDelegate

NSString *_assetId;

NSString * DEFAULT_LICENSE_SERVER_URL = @"https://fps.ezdrm.com/api/licenses/";

- (instancetype)init:(NSURL *)certificateURL withLicenseURL:(NSURL *)licenseURL{
    self = [super init];
    _certificateURL = certificateURL;
    _licenseURL = licenseURL;
    return self;
}

/*------------------------------------------
 **
 ** getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest
 **
 ** Takes the bundled SPC and sends it to the license server defined at licenseUrl or KEY_SERVER_URL (if licenseUrl is null).
 ** It returns CKC.
 ** ---------------------------------------*/
- (NSData *)getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:(NSData*)requestBytes and:(NSString *)assetId and:(NSString *)customParams and:(NSError *)errorOut {
    __block NSData * decodedData = nil;
    
    NSURL * finalLicenseURL;
    if (_licenseURL != nil && _licenseURL != (id)[NSNull null]){
        finalLicenseURL = _licenseURL;
    } else {
        finalLicenseURL = [[NSURL alloc] initWithString: DEFAULT_LICENSE_SERVER_URL];
    }
    NSURL * ksmURL = [[NSURL alloc] initWithString: [NSString stringWithFormat:@"%@%@%@",finalLicenseURL,assetId,customParams]];
    
    NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:ksmURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-type"];
    [request setHTTPBody:requestBytes];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"SDK Error, SDK responded with Error: %@", error.localizedDescription);
        } else {
            decodedData = data;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    [task resume];
    
    // Wait for the request to complete (synchronous behavior)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return decodedData;
}

/*------------------------------------------
 **
 ** getAppCertificate
 **
 ** returns the apps certificate for authenticating against your server
 ** the example here uses a local certificate
 ** but you may need to edit this function to point to your certificate
 ** ---------------------------------------*/
- (NSData *)getAppCertificate:(NSString *) String {
    NSData * certificate = nil;
    certificate = [NSData dataWithContentsOfURL:_certificateURL];
    return certificate;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForLoadingOfRequestedResource:(AVAssetResourceLoadingRequest *)loadingRequest {
    NSURL *assetURI = loadingRequest.request.URL;
    NSString * str = assetURI.absoluteString;
    NSString * mySubstring = [str substringFromIndex:str.length - 36];
    _assetId = mySubstring;
    NSString * scheme = assetURI.scheme;
    NSData * requestBytes;
    NSData * certificate;
    if (!([scheme isEqualToString: @"skd"])){
        return NO;
    }
    @try {
        certificate = [self getAppCertificate:_assetId];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:[[NSError alloc] initWithDomain:NSURLErrorDomain code:NSURLErrorClientCertificateRejected userInfo:nil]];
    }
    @try {
        requestBytes = [loadingRequest streamingContentKeyRequestDataForApp:certificate contentIdentifier: [str dataUsingEncoding:NSUTF8StringEncoding] options:nil error:nil];
    }
    @catch (NSException* excp) {
        [loadingRequest finishLoadingWithError:nil];
        return YES;
    }
    
    NSString * passthruParams = [NSString stringWithFormat:@"?customdata=%@", _assetId];
    NSData * responseData;
    NSError * error;
    
    responseData = [self getContentKeyAndLeaseExpiryFromKeyServerModuleWithRequest:requestBytes and:_assetId and:passthruParams and:error];
    
    if (responseData != nil && ![responseData isKindOfClass:[NSNull class]]){
        AVAssetResourceLoadingDataRequest * dataRequest = loadingRequest.dataRequest;
        [dataRequest respondWithData:responseData];
        [loadingRequest finishLoading];
    } else {
        [loadingRequest finishLoadingWithError:error];
    }
    
    return YES;
}

- (BOOL)resourceLoader:(AVAssetResourceLoader *)resourceLoader shouldWaitForRenewalOfRequestedResource:(AVAssetResourceRenewalRequest *)renewalRequest {
    return [self resourceLoader:resourceLoader shouldWaitForLoadingOfRequestedResource:renewalRequest];
}

@end
