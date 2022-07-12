#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <objc/runtime.h>
#import "PeripheralProxy.h"

@interface PeripheralProxy ()

@property(strong, nonatomic) NSString* desiredName;
@property(strong, nonatomic) CBPeripheral* peripheral;

@end

@implementation PeripheralProxy

- (void)setupWithName:(NSString *)name peripheral:(CBPeripheral* )peripheral {
    self.desiredName = name;
    self.peripheral = peripheral;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.peripheral methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    if(sel_isEqual(NSSelectorFromString(@"name"), [invocation selector])) {
        [invocation setReturnValue:&_desiredName];
        return;
    }
    [self.peripheral methodSignatureForSelector:[invocation selector]];
    [invocation invokeWithTarget:self.peripheral];

}

- (NSString *)nameOverride {
    return self.desiredName;
}

@end
