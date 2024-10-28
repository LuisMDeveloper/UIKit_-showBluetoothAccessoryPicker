//
//  FontList.h
//  DatamaxONeilSDK_iPhone
//
//  Created by Dmitriy Bozko on 11/15/13.
//  Copyright (c) 2014 Datamax-O'Neil. All rights reserved.
//

#import "PrinterState.h"
#import "FontData.h"

/**
 * This class handles the data from an {FN?} query as well as
 * accessors to read the data values.
 * <p>
 * This class supports the following possible parameters:
 * <table border=1>
 *    <tr><th>Parameter</th><th>Description</th></tr>
 *    <tr><td></td><td>List of fonts, both resident and downloaded, loaded in the printer.</td></tr>
 * </table>
 */
@interface FontList : PrinterState

/**
 * The default constructor will initialize the class with default values.
 * <p>
 * Initially all of the _IsValid parameters will be false because no data has been processed.  To 'populate' the values, the object must invoke <see cref="PrinterState.Update(int)">Update</see> with the query response string.
 * @param conn connection to printer
 */
-(id) initWithConnection: (ConnectionBase *) conn;

/**
 * Indicates if getFonts parameter is present.
 * <p>
 * This function is useful to determine if the given parameter is supported on the current printer.  Because of differences in configuration, hardware or version certain parameter may not exist and the results returned by the parameter getFonts may not be valid.  Instead of trying to indicate this with 'Magic Values' this method was implemented.
 *
 * @see getFonts
 * @return If the parameter is present and valid true, false otherwise.
 */
-(bool) getFonts_IsPresent;

/**
 * List of fonts, both resident and downloaded, loaded in the printer.
 * <p>
 * The return value for this parameter is only valid if getFonts_IsPresent returns true.  Because of differences in configuration, hardware or version certain parameter may not exist and the results returned may not be valid.  Instead of trying to indicate this with 'Magic Values' this method was implemented.
 *
 * @see getFonts_IsPresent
 * @return The current value for the parameter.
 */
-(NSMutableArray *) getFonts;

@end
