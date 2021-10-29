//
//  CinSocketAddress.m
//  Utility
//
//  Created by edz on 2021/7/21.
//  Copyright © 2021 p. All rights reserved.
//

#import "CinSocketAddress.h"

@implementation CinSocketAddress


+ (NSMutableArray *)lookupHost:(NSString *)host port:(uint16_t)port error:(NSError **)errPtr{
  
    
    NSMutableArray *addresses = nil;
    NSError *error = nil;
    
    if ([host isEqualToString:@"localhost"] || [host isEqualToString:@"loopback"]){
        // Use LOOPBACK address
        struct sockaddr_in nativeAddr4;
        nativeAddr4.sin_len         = sizeof(struct sockaddr_in);
        nativeAddr4.sin_family      = AF_INET;
        nativeAddr4.sin_port        = htons(port);
        nativeAddr4.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        memset(&(nativeAddr4.sin_zero), 0, sizeof(nativeAddr4.sin_zero));
        
        struct sockaddr_in6 nativeAddr6;
        nativeAddr6.sin6_len        = sizeof(struct sockaddr_in6);
        nativeAddr6.sin6_family     = AF_INET6;
        nativeAddr6.sin6_port       = htons(port);
        nativeAddr6.sin6_flowinfo   = 0;
        nativeAddr6.sin6_addr       = in6addr_loopback;
        nativeAddr6.sin6_scope_id   = 0;
        
        // Wrap the native address structures
        
        NSData *address4 = [NSData dataWithBytes:&nativeAddr4 length:sizeof(nativeAddr4)];
        NSData *address6 = [NSData dataWithBytes:&nativeAddr6 length:sizeof(nativeAddr6)];
        
        addresses = [NSMutableArray arrayWithCapacity:2];
        [addresses addObject:address4];
        [addresses addObject:address6];
    }
    else{
        NSString *portStr = [NSString stringWithFormat:@"%hu", port];
        
        struct addrinfo hints, *res, *res0;
        
        memset(&hints, 0, sizeof(hints));
        hints.ai_family   = PF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_protocol = IPPROTO_TCP;
        
        int gai_error = getaddrinfo([host UTF8String], [portStr UTF8String], &hints, &res0);
        
        if (gai_error)
        {
            error = [self gaiError:gai_error];
        }
        else
        {
            NSUInteger capacity = 0;
            for (res = res0; res; res = res->ai_next)
            {
                if (res->ai_family == AF_INET || res->ai_family == AF_INET6) {
                    capacity++;
                }
            }
            
            addresses = [NSMutableArray arrayWithCapacity:capacity];
            
            for (res = res0; res; res = res->ai_next)
            {
                if (res->ai_family == AF_INET)
                {
                    // Found IPv4 address.
                    // Wrap the native address structure, and add to results.
                    
                    NSData *address4 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
                    [addresses addObject:address4];
                }
                else if (res->ai_family == AF_INET6)
                {
                    // Found IPv6 address.
                    // Wrap the native address structure, and add to results.
                    
                    NSData *address6 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
                    [addresses addObject:address6];
                }
            }
            freeaddrinfo(res0);
            
            if ([addresses count] == 0)
            {
                error = [self gaiError:EAI_FAIL];
            }
        }
    }
    
    if (errPtr) *errPtr = error;
    return addresses;
}

+ (NSError *)gaiError:(int)gai_error{
    
    NSString *errMsg = [NSString stringWithCString:gai_strerror(gai_error) encoding:NSASCIIStringEncoding];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"kCFStreamErrorDomainNetDB" code:gai_error userInfo:userInfo];
}

+ (BOOL)isIPv4Address:(NSData *)address{
    if ([address length] >= sizeof(struct sockaddr)){
        const struct sockaddr *sockaddrX = [address bytes];
        
        if (sockaddrX->sa_family == AF_INET) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)isIPv6Address:(NSData *)address{
    if ([address length] >= sizeof(struct sockaddr)){
        const struct sockaddr *sockaddrX = [address bytes];
        
        if (sockaddrX->sa_family == AF_INET6) {
            return YES;
        }
    }
    
    return NO;
}

+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr fromAddress:(NSData *)address{
    return [self getHost:hostPtr port:portPtr family:NULL fromAddress:address];
}

+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr family:(sa_family_t *)afPtr fromAddress:(NSData *)address{
    if ([address length] >= sizeof(struct sockaddr)){
        
        const struct sockaddr *sockaddrX = [address bytes];
        // ipv4 家族
        if (sockaddrX->sa_family == AF_INET){
            
            if ([address length] >= sizeof(struct sockaddr_in)){
                struct sockaddr_in sockaddr4;
                memcpy(&sockaddr4, sockaddrX, sizeof(sockaddr4));
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr4:&sockaddr4];
                if (portPtr) *portPtr = [self portFromSockaddr4:&sockaddr4];
                if (afPtr)   *afPtr   = AF_INET;
                
                return YES;
            }
        }
        // ipv6 家族
        else if (sockaddrX->sa_family == AF_INET6){
            
            if ([address length] >= sizeof(struct sockaddr_in6)){
                struct sockaddr_in6 sockaddr6;
                memcpy(&sockaddr6, sockaddrX, sizeof(sockaddr6));
                
                if (hostPtr) *hostPtr = [self hostFromSockaddr6:&sockaddr6];
                if (portPtr) *portPtr = [self portFromSockaddr6:&sockaddr6];
                if (afPtr)   *afPtr   = AF_INET6;
                
                return YES;
            }
        }
    }
    
    return NO;
}


+ (NSString *)hostFromSockaddr4:(const struct sockaddr_in *)pSockaddr4{
    char addrBuf[INET_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET, &pSockaddr4->sin_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL){
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (NSString *)hostFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6{
    char addrBuf[INET6_ADDRSTRLEN];
    
    if (inet_ntop(AF_INET6, &pSockaddr6->sin6_addr, addrBuf, (socklen_t)sizeof(addrBuf)) == NULL){
        addrBuf[0] = '\0';
    }
    
    return [NSString stringWithCString:addrBuf encoding:NSASCIIStringEncoding];
}

+ (uint16_t)portFromSockaddr4:(const struct sockaddr_in *)pSockaddr4{
    return ntohs(pSockaddr4->sin_port);
}

+ (uint16_t)portFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6{
    return ntohs(pSockaddr6->sin6_port);
}
@end
