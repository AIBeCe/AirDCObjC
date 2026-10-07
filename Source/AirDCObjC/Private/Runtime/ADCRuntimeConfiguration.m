#import <AirDCObjC/ADCRuntimeConfiguration.h>
#import <AirDCObjC/ADCError.h>

static BOOL ADCIsValidDirectoryURL(NSURL *url) {
    if (![url isKindOfClass:NSURL.class] || !url.isFileURL) {
        return NO;
    }

    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if (!components || components.query != nil || components.fragment != nil) {
        return NO;
    }

    NSString *host = components.host;
    if (host.length > 0 && [host caseInsensitiveCompare:@"localhost"] != NSOrderedSame) {
        return NO;
    }

    NSString *path = url.path;
    if (path.length == 0 || ![path hasPrefix:@"/"]) {
        return NO;
    }

    unichar nul = 0;
    NSString *nulString = [NSString stringWithCharacters:&nul length:1];
    if ([path rangeOfString:nulString].location != NSNotFound ||
        [components.percentEncodedPath rangeOfString:@"%00" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return NO;
    }

    return YES;
}

@interface ADCRuntimeConfiguration ()
@property(nonatomic, readwrite, copy) NSURL *profileDirectoryURL;
@property(nonatomic, readwrite, copy) NSURL *resourceDirectoryURL;
@property(nonatomic, readwrite, copy) NSURL *temporaryDirectoryURL;
@end

@implementation ADCRuntimeConfiguration

- (nullable instancetype)initWithProfileDirectoryURL:(NSURL *)profileDirectoryURL
                                resourceDirectoryURL:(NSURL *)resourceDirectoryURL
                               temporaryDirectoryURL:(NSURL *)temporaryDirectoryURL
                                               error:(NSError * _Nullable *)error {
    if (error) {
        *error = nil;
    }

    if (!ADCIsValidDirectoryURL(profileDirectoryURL) ||
        !ADCIsValidDirectoryURL(resourceDirectoryURL) ||
        !ADCIsValidDirectoryURL(temporaryDirectoryURL)) {
        if (error) {
            *error = [NSError errorWithDomain:ADCErrorDomain
                                        code:ADCErrorInvalidConfiguration
                                    userInfo:@{ NSLocalizedDescriptionKey: @"Runtime configuration requires absolute local file URLs without query or fragment components." }];
        }
        return nil;
    }

    self = [super init];
    if (self) {
        _profileDirectoryURL = profileDirectoryURL.standardizedURL.copy;
        _resourceDirectoryURL = resourceDirectoryURL.standardizedURL.copy;
        _temporaryDirectoryURL = temporaryDirectoryURL.standardizedURL.copy;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
