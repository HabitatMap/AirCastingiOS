#import "CBPeripheralBuilder.h"
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "PeripheralProxy.h"

@implementation CBPeripheralBuilder

+ (id)createWithName:(NSString *)name {
    CBPeripheral *peripheral = [NSClassFromString(@"CBPeripheral") new];
    [peripheral addObserver:peripheral forKeyPath:@"delegate" options:NSKeyValueObservingOptionNew context:nil];
    PeripheralProxy* proxy = [PeripheralProxy alloc];
    [proxy setupWithName:name peripheral:peripheral];
    return proxy;
}

@end
