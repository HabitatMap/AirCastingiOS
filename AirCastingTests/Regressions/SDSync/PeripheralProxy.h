#ifndef PeripheralProxy_h
#define PeripheralProxy_h

@interface PeripheralProxy : NSProxy

- (void)setupWithName:(NSString *)name peripheral:(CBPeripheral* )peripheral;

@end

#endif
