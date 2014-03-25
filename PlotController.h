//
//  PlotGalleryController.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CorePlot/CorePlot.h>
#import <Quartz/Quartz.h>

#import "PlotGallery.h"
#import "PlotView.h"
#import "BLEDataTracker.h"

typedef enum
{
    IDLE = 0,
    SCANNING,
    CONNECTED,
} ConnectionState;
// @class Track;

@interface PlotController : NSObject</*NSSplitViewDelegate,*/
                                            PlotViewDelegate, CBCentralManagerDelegate, UARTPeripheralDelegate>
{
    @private

    //IBOutlet IKImageBrowserView *imageBrowser;
    IBOutlet NSPopUpButton *themePopUpButton;

    IBOutlet PlotView *hostingView;

    PlotItem *plotItem;

    NSString *currentThemeName;
}

@property (nonatomic, strong) PlotItem *plotItem;
@property (nonatomic, copy) NSString *currentThemeName;
@property CBCentralManager *cm;
@property ConnectionState state;
@property UARTPeripheral *currentPeripheral;

-(IBAction)themeSelectionDidChange:(id)sender;
- (IBAction)searchBLE:(id)sender;

@end
