//
//  RealTimePlot.h
//  CorePlotGallery
//

#import "PlotItem.h"
#import <IOBluetooth/IOBluetooth.h>
#import "UARTPeripheral.h"

@interface RealTimePlot : PlotItem<CPTPlotDataSource>
{
    @private
    NSMutableArray *plotData;
    NSUInteger currentIndex;
    NSTimer *dataTimer;
}



-(void)newData:(NSTimer *)theTimer;


@end
