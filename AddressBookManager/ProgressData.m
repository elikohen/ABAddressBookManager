//
//  ProgressData.m
//
//  Created by Albert Hernández on 29/11/10.
//  Updated by Ivan on 16/5/12.
//

#import "ProgressData.h"

@implementation ProgressData

@synthesize itemsProcessed, itemsTotal, label;

#pragma mark - Object lifecycle

- (id) init{
	return [self initWithItemsProcessed:nil itemsTotal:nil andLabel:nil];
}

- (void) dealloc{
	self.itemsProcessed = nil;
	self.itemsTotal = nil;
	self.label = nil;
}

#pragma mark - Public methods

- (id)initWithItemsProcessed:(NSNumber*)itemsProc itemsTotal:(NSNumber*)itemsTot{
	return [self initWithItemsProcessed:itemsProc itemsTotal:itemsTot andLabel:nil];
}

- (id)initWithItemsProcessed:(NSNumber*)itemsProc itemsTotal:(NSNumber*)itemsTot andLabel:(NSString*)str{
	if (self = [super init])
	{
		self.itemsProcessed = itemsProc;
		self.itemsTotal = itemsTot;
		self.label = str;
	}
	return self;
}

- (NSNumber*)getProgress{
	if (self.itemsProcessed && self.itemsTotal)
		return [NSNumber numberWithFloat:([self.itemsProcessed floatValue]/[self.itemsTotal floatValue])];
	return nil;
}

@end
