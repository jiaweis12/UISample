//
//  Plot_Gallery_MacAppDelegate.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import "UARTPeripheral.h"

@interface Plot_MacAppDelegate : NSObject<NSApplicationDelegate, CBCentralManagerDelegate, UARTPeripheralDelegate>
{
    @private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)connect:(id)sender;

@end
