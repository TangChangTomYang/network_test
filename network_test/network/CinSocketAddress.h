//
//  CinSocketAddress.h
//  Utility
//
//  Created by edz on 2021/7/21.
//  Copyright © 2021 p. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <netdb.h>
#import <arpa/inet.h>

 

@interface CinSocketAddress : NSObject
+ (NSMutableArray *)lookupHost:(NSString *)host port:(uint16_t)port error:(NSError **)errPtr;

+ (NSError *)gaiError:(int)gai_error;

+ (BOOL)isIPv4Address:(NSData *)address;

+ (BOOL)isIPv6Address:(NSData *)address;


+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr fromAddress:(NSData *)address;

+ (BOOL)getHost:(NSString **)hostPtr port:(uint16_t *)portPtr family:(sa_family_t *)afPtr fromAddress:(NSData *)address;


+ (NSString *)hostFromSockaddr4:(const struct sockaddr_in *)pSockaddr4;

+ (NSString *)hostFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6;

+ (uint16_t)portFromSockaddr4:(const struct sockaddr_in *)pSockaddr4;

+ (uint16_t)portFromSockaddr6:(const struct sockaddr_in6 *)pSockaddr6;
@end
 
