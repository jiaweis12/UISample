//
//  Plot_Gallery_MacAppDelegate.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "Plot_MacAppDelegate.h"

@implementation Plot_MacAppDelegate

@synthesize window;
@synthesize cm = _cm;
@synthesize currentPeripheral = _currentPeripheral;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    NSLog(@"we are initing.......");
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.position = 1.0;
    self.sensorCount = 1;
}

- (IBAction)sendDataButtonPressed:(id)sender {
    /*
     [self.currentPeripheral writeString:@"aabbcc"];
     */
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:3000/accreaders?note=%@&commit=Load", self.text2Send.stringValue]]];
    
    NSLog(@"goto website");
}

- (IBAction)searchBLEclick:(id)sender {
    [self.statusLabel setStringValue:@"good to go"];
    
    switch (self.state) {
        case IDLE:
            self.state = SCANNING;
            
            NSLog(@"Started scan ...");
            [self.searchBLE setTitle:@"Scanning ..."];
            
            [self.cm scanForPeripheralsWithServices:@[[UARTPeripheral serviceUUID]] options:@{CBCentralManagerScanOptionAllowDuplicatesKey: [NSNumber numberWithBool:NO]}];
            break;
            
        case SCANNING:
            self.state = IDLE;
            NSLog(@"Stopped scan");
            [self.cm stopScan];
            break;
            
        case CONNECTED:
            NSLog(@"Disconnect peripheral %@", self.currentPeripheral.peripheral.name);
            [self.cm cancelPeripheralConnection:self.currentPeripheral.peripheral];
            self.sensorCount = 1;
            [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:3000/magneticreaders?note=%@&commit=Load", self.text2Send.stringValue]]];
            break;
    }
}

- (void)startInquiry
{
    
}

- (IOReturn)stopInquiry {
    return 1;
}

- (void) didReceiveData:(NSData *)sensorValueArray
{
    char sensorType;
    Float32 tempdata1;
    Float32 tempdata2;
    Float32 tempdata3;
    
    //[self addTextToConsole:string isInput:YES];
    //NSLog(@"Did receive data %@", string);
    
    [sensorValueArray getBytes:&sensorType range:NSMakeRange(0, 1)];
    [sensorValueArray getBytes:&tempdata1 range:NSMakeRange(1, 4)];
    [sensorValueArray getBytes:&tempdata2 range:NSMakeRange(5, 4)];
    [sensorValueArray getBytes:&tempdata3 range:NSMakeRange(9, 4)];
    NSLog(@"got the data: %f, %f, %f", tempdata1, tempdata2, tempdata3);
    
    if (sensorType == 'a') {
        [self.AccSensorXAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata1]];
        [self.AccSensorYAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata2]];
        [self.AccSensorZAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata3]];
        
        NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/accreaders"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSString * str = [NSString stringWithFormat:@"{\"acc\":[ \
                          {\"count\":\"%ld\", \"xaxis\":\"%f\", \"yaxis\":\"%f\", \"zaxis\":\"%f\", \"note\":\"%@\"} \
                          ]}", self.sensorCount, tempdata1, tempdata2, tempdata3, self.text2Send.stringValue];
        
        self.sensorCount++;
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLResponse *response;
        NSError *err;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
        //NSLog(@"responseData: %@", responseData);
        NSLog(@"responseData");
        
    } else if (sensorType == 'm') {
        [self.MagSensorXAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata1]];
        [self.MagSensorYAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata2]];
        [self.MagSensorZAxisTextLabel setStringValue:[NSString stringWithFormat:@"%f", tempdata3]];
        
        NSURL *url = [NSURL URLWithString:@"http://127.0.0.1:3000/magneticreaders"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSString * str = [NSString stringWithFormat:@"{\"mag\":[ \
                          {\"count\":\"%ld\", \"xaxis\":\"%f\", \"yaxis\":\"%f\", \"zaxis\":\"%f\", \"note\":\"%@\"} \
                          ]}", self.sensorCount, tempdata1, tempdata2, tempdata3, self.text2Send.stringValue];
        
        self.sensorCount++;
        
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Accept"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSURLResponse *response;
        NSError *err;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
        //NSLog(@"responseData: %@", responseData);
        NSLog(@"responseData");
    }
    
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Powered On");
    } else {
        NSLog(@"Powered Off");
    }
    
}

- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    NSLog(@"Did discover peripheral %@", peripheral.name);
    [self.cm stopScan];
    
    self.currentPeripheral = [[UARTPeripheral alloc] initWithPeripheral:peripheral delegate:self];
    
    [self.cm connectPeripheral:peripheral options:@{CBConnectPeripheralOptionNotifyOnDisconnectionKey: [NSNumber numberWithBool:YES]}];
}

- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Did connect peripheral %@", peripheral.name);
    
    [self.statusLabel setStringValue: peripheral.name];
    
    self.state = CONNECTED;
    [self.searchBLE setTitle:@"Disconnect"];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didConnect];
    }
}

- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Did disconnect peripheral %@", peripheral.name);
    
    NSLog(@"Did disconnect from %@", peripheral.name);
    
    self.state = IDLE;
    [self.searchBLE setTitle:@"Connect"];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
    }
    
}


-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction)connect:(id)sender {
    NSLog(@"Hello");
}
@end
