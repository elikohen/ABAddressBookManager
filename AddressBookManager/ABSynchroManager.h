//
//  ABSynchroManager.h
//
//  Created by Eli Kohen on 8/09/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ABSynchroManager : NSObject

+ (ABSynchroManager*)sharedInstance;

- (NSArray*) addressBookModificationsSinceCheckpoint;
- (void) asyncAddressBookModificationsSinceCheckpoint: (void (^)(NSArray* result))completion;
- (BOOL) saveLastRetrievalAsCheckpoint;
- (void) resetCheckpoint;

@end