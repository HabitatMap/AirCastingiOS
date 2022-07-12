#ifndef CBPeripheralBuilder_h
#define CBPeripheralBuilder_h

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CBPeripheralBuilder : NSObject

+ (CBPeripheral *)createWithName:(NSString *)name;

@end

#endif
