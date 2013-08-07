//
//  ProgressData.h
//
//  Created by Albert Hernández on 29/11/10.
//  Updated by Ivan on 16/5/12.
//

#import <Foundation/Foundation.h>

@interface ProgressData : NSObject

@property (nonatomic, retain) NSNumber *itemsProcessed;
@property (nonatomic, retain) NSNumber *itemsTotal;
@property (nonatomic, retain) NSString *label;

- (id)initWithItemsProcessed:(NSNumber*)itemsProc itemsTotal:(NSNumber*)itemsTot;
- (id)initWithItemsProcessed:(NSNumber*)itemsProc itemsTotal:(NSNumber*)itemsTot andLabel:(NSString*)str;
- (NSNumber*)getProgress;

@end
