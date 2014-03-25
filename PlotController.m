//
//  PlotGalleryController.m
//  CorePlotGallery
//
//  Created by Jeff Buck on 9/5/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "PlotController.h"
#import "BLEDataTracker.h"
#import "Header.h"

#import "dlfcn.h"
//#define EMBED_NU	1

const CGFloat CPT_SPLIT_VIEW_MIN_LHS_WIDTH = 150.0;

#define kThemeTableViewControllerNoTheme      @"None"
#define kThemeTableViewControllerDefaultTheme @"Default"

@implementation PlotController

@dynamic plotItem;
@synthesize currentThemeName;

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    if (central.state == CBCentralManagerStatePoweredOn)
    {
        NSLog(@"Powered On");
    } else {
        NSLog(@"Powered Off");
    }
    
}

- (void) didReceiveData:(NSData *)sensorValueArray
{
    char sensorType;
    [sensorValueArray getBytes:&sensorType range:NSMakeRange(0, 1)];
    NSLog(@"got the data: %c", sensorType);
    
    Float32 tempdata1;
     
    //[self addTextToConsole:string isInput:YES];
    //NSLog(@"Did receive data %@", string);
     
    [sensorValueArray getBytes:&sensorType range:NSMakeRange(0, 1)];
    [sensorValueArray getBytes:&tempdata1 range:NSMakeRange(1, 4)];
    
    gotData = (Float32)(tempdata1);
}


-(void)setupThemes
{
    [themePopUpButton addItemWithTitle:kThemeTableViewControllerDefaultTheme];
    [themePopUpButton addItemWithTitle:kThemeTableViewControllerNoTheme];

    for ( Class c in [CPTTheme themeClasses] ) {
        [themePopUpButton addItemWithTitle:[c name]];
    }

    self.currentThemeName = kThemeTableViewControllerDefaultTheme;
    [themePopUpButton selectItemWithTitle:kThemeTableViewControllerDefaultTheme];
    
    self.cm = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
}

-(void)awakeFromNib
{
    [[PlotGallery sharedPlotGallery] sortByTitle];

//    [splitView setDelegate:self];
//
//    [imageBrowser setDelegate:self];
//    [imageBrowser setDataSource:self];
//    [imageBrowser setCellsStyleMask:IKCellsStyleShadowed | IKCellsStyleTitled]; //| IKCellsStyleSubtitled];
//
//    [imageBrowser reloadData];

    [hostingView setDelegate:self];

    [self setupThemes];

#ifdef EMBED_NU
    // Setup a Nu console without the help of the Nu include files or
    // an explicit link of the Nu framework, which may not be installed
    nuHandle = dlopen("/Library/Frameworks/Nu.framework/Nu", RTLD_LAZY);

    if ( nuHandle ) {
        NSString *consoleStartup =
            @"(progn \
           (load \"console\") \
           (set $console ((NuConsoleWindowController alloc) init)))";

        Class nuClass = NSClassFromString(@"Nu");
        id parser     = [nuClass performSelector:@selector(parser)];
        id code       = [parser performSelector:@selector(parse:) withObject:consoleStartup];
        [parser performSelector:@selector(eval:) withObject:code];
    }
#endif
    
    self.plotItem = [[PlotGallery sharedPlotGallery] objectInSection:0 atIndex:0];
}

-(void)dealloc
{
    [self setPlotItem:nil];

//    [splitView setDelegate:nil];
//    [imageBrowser setDataSource:nil];
//    [imageBrowser setDelegate:nil];
    [hostingView setDelegate:nil];

#ifdef EMBED_NU
    if ( nuHandle ) {
        dlclose(nuHandle);
    }
#endif

}

-(void)setFrameSize:(NSSize)newSize
{
    if ( [plotItem respondsToSelector:@selector(setFrameSize:)] ) {
        [plotItem setFrameSize:newSize];
    }
}

#pragma mark -
#pragma mark Theme Selection

-(CPTTheme *)currentTheme
{
    CPTTheme *theme;

    if ( [currentThemeName isEqualToString:kThemeTableViewControllerNoTheme] ) {
        theme = (id)[NSNull null];
    }
    else if ( [currentThemeName isEqualToString:kThemeTableViewControllerDefaultTheme] ) {
        theme = nil;
    }
    else {
        theme = [CPTTheme themeNamed:currentThemeName];
    }

    return theme;
}

-(IBAction)themeSelectionDidChange:(id)sender
{
    self.currentThemeName = [sender titleOfSelectedItem];
    [plotItem renderInView:hostingView withTheme:[self currentTheme] animated:YES];
}

- (IBAction)searchBLE:(id)sender {    
    switch (self.state) {
        case IDLE:
            self.state = SCANNING;
            
            NSLog(@"Started scan ...");
            
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
            //self.sensorCount = 1;
            /*
             [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:[NSString stringWithFormat:@"http://127.0.0.1:3000/magneticreaders?note=%@&commit=Load", self.text2Send.stringValue]]];
             break;
             */
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
    
    //[self.statusLabel setStringValue: peripheral.name];
    
    self.state = CONNECTED;
    //[self.searchBLE setTitle:@"Disconnect"];
    
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
    //[self.searchBLE setTitle:@"Connect"];
    
    if ([self.currentPeripheral.peripheral isEqual:peripheral])
    {
        [self.currentPeripheral didDisconnect];
    }
    
}


#pragma mark -
#pragma mark PlotItem Property

-(PlotItem *)plotItem
{
    return plotItem;
}

-(void)setPlotItem:(PlotItem *)item
{
    if ( plotItem != item ) {
        [plotItem killGraph];

        plotItem = item;

        [plotItem renderInView:hostingView withTheme:[self currentTheme] animated:YES];
    }
}

#pragma mark -
#pragma mark IKImageBrowserViewDataSource methods

-(NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
{
    return [[PlotGallery sharedPlotGallery] count];
}

-(id)imageBrowser:(IKImageBrowserView *)browser itemAtIndex:(NSUInteger)index
{
    return [[PlotGallery sharedPlotGallery] objectInSection:0 atIndex:index];
}

-(NSUInteger)numberOfGroupsInImageBrowser:(IKImageBrowserView *)aBrowser
{
    return [[PlotGallery sharedPlotGallery] numberOfSections];
}

-(NSDictionary *)imageBrowser:(IKImageBrowserView *)aBrowser groupAtIndex:(NSUInteger)index
{
    NSString *groupTitle = [[[PlotGallery sharedPlotGallery] sectionTitles] objectAtIndex:index];

    NSUInteger offset = 0;

    for ( NSUInteger i = 0; i < index; i++ ) {
        offset += [[PlotGallery sharedPlotGallery] numberOfRowsInSection:i];
    }

    NSValue *groupRange = [NSValue valueWithRange:NSMakeRange(offset, [[PlotGallery sharedPlotGallery] numberOfRowsInSection:index])];

    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSNumber numberWithInt:IKGroupDisclosureStyle], IKImageBrowserGroupStyleKey,
            groupTitle, IKImageBrowserGroupTitleKey,
            groupRange, IKImageBrowserGroupRangeKey,
            nil];
}

#pragma mark -
#pragma mark IKImageBrowserViewDelegate methods

-(void)imageBrowserSelectionDidChange:(IKImageBrowserView *)browser
{
    NSUInteger index = [[browser selectionIndexes] firstIndex];

    if ( index != NSNotFound ) {
        PlotItem *item = [[PlotGallery sharedPlotGallery] objectInSection:0 atIndex:index];
        self.plotItem = item;
    }
}

#pragma mark -
#pragma mark NSSplitViewDelegate methods

-(CGFloat)splitView:(NSSplitView *)sv constrainMinCoordinate:(CGFloat)coord ofSubviewAt:(NSInteger)index
{
    return coord + CPT_SPLIT_VIEW_MIN_LHS_WIDTH;
}

-(CGFloat)splitView:(NSSplitView *)sv constrainMaxCoordinate:(CGFloat)coord ofSubviewAt:(NSInteger)index
{
    return coord - CPT_SPLIT_VIEW_MIN_LHS_WIDTH;
}

-(void)splitView:(NSSplitView *)sender resizeSubviewsWithOldSize:(NSSize)oldSize
{
    // Lock the LHS width
    NSRect frame   = [sender frame];
    NSView *lhs    = [[sender subviews] objectAtIndex:0];
    NSRect lhsRect = [lhs frame];
    NSView *rhs    = [[sender subviews] objectAtIndex:1];
    NSRect rhsRect = [rhs frame];

    CGFloat dividerThickness = [sender dividerThickness];

    lhsRect.size.height = frame.size.height;

    rhsRect.size.width  = frame.size.width - lhsRect.size.width - dividerThickness;
    rhsRect.size.height = frame.size.height;
    rhsRect.origin.x    = lhsRect.size.width + dividerThickness;

    [lhs setFrame:lhsRect];
    [rhs setFrame:rhsRect];
}

@end
