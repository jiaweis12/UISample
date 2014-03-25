//
//  PlotView.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/6/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOBluetooth/IOBluetooth.h>
#import "UARTPeripheral.h"

@protocol PlotViewDelegate<NSObject>

-(void)setFrameSize:(NSSize)newSize;

@end

@interface PlotView : NSView
{
    @private
    id<PlotViewDelegate> delegate;
}

@property (nonatomic, strong) id<PlotViewDelegate> delegate;

@end
