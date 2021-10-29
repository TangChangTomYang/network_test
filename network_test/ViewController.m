//
//  ViewController.m
//  netWorkTest
//
//  Created by yangrui on 2021/10/29.
//

#import "ViewController.h" 
#import "CinSocketAddress.h"
#import "CBReachability.h"

@interface ViewController ()

@end

@implementation ViewController

 
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSError *err = nil;
    NSArray *arr = [CinSocketAddress lookupHost:@"ucp.cib.com.cn" port:8085 error:&err];
    
    NSLog(@"-----domain: %@, port: %d",@"ucp.cib.com.cn", 8085);
    for (int i=0; i< arr.count; i++) {
        NSData *data = arr[i];
        
        
        NSString *host = nil;
        int port = 0;
        BOOL ret = [CinSocketAddress getHost:&host port:&port fromAddress:data];
        if (ret) {
            
            if([host containsString:@":"]){
                // 检测指定 ipv6 是否是通路状态
                CBReachability *reach6 = [CBReachability reachabilityWithIpv6Address:host];
                CBNetworkStatus status = [reach6 currentReachabilityStatus];
                NSLog(@"ipv6: (%@-%d), reach: %ld", host,port, status);
            }
            else{
                // 检测指定 ipv4 是否是通路状态
                CBReachability *reach4 = [CBReachability reachabilityWithIpv4Address:host];
                CBNetworkStatus status = [reach4 currentReachabilityStatus];
                NSLog(@"ipv4: (%@-%d), reach: %ld", host,port, status);
            }
           
        }
    }
    
    
    
    // 检测指定 ipv4 是否是通路状态
    CBReachability *reach4 = [CBReachability reachabilityWithIpv4Address:@"118.25.103.161"];
    NSLog(@"reach4, %ld",[reach4 currentReachabilityStatus]);
    
    // 检测指定 ipv6 是否是通路状态
    CBReachability *reach6 = [CBReachability reachabilityWithIpv6Address:@"2409:8734:411:10::24"];
    NSLog(@"reach6, %ld",[reach6 currentReachabilityStatus]);
    
    // 检测指定 域名 是否是通路状态
    CBReachability *reachName = [CBReachability reachabilityWithHostName:@"www.pgyer.com"];
    NSLog(@"reachName, %ld",[reachName currentReachabilityStatus]);
    
    // 检测指定 域名 是否是通路状态
    CBReachability *reachBaiDu = [CBReachability reachabilityWithHostName:@"baidu.com"];
    NSLog(@"reachBaiDu, %ld",[reachBaiDu currentReachabilityStatus]);
}

@end
