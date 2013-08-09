//
//  ABSynchroManager.m
//
//  Created by Eli Kohen on 8/09/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import "ABSynchroManager.h"
#import "AddressBookManager.h"

#define kContactIdKey @"contactId"
#define kModificationDateKey @"modificationDate"

#define kUDSynchMetadatas @"ABSynchMetadatas"

@interface ABSynchroManager ()
/**
 * current metadatas, used to detect local changes on addressbook.
 */
@property (nonatomic, retain) NSMutableArray *currentMetadatas;

@end

@implementation ABSynchroManager

#pragma mark - Public methods

- (NSArray*) addressBookModificationsSinceCheckpoint{
	if(![[AddressBookManager sharedInstance] isStarted]){
		NSLog(@"AddressBookManager has to be started to check modifications");
		return nil;
	}
	
	return [self parseAndUpdateMobileContacts];
}

- (void) asyncAddressBookModificationsSinceCheckpoint: (void (^)(NSArray* result))completion{
	dispatch_async(dispatch_get_global_queue(0,0), ^{
		NSArray *result = [self addressBookModificationsSinceCheckpoint];
		dispatch_async(dispatch_get_main_queue(), ^{
			completion(result);
		});
	});
}

- (void) revertLastCheckpoint{
	self.currentMetadatas = nil;
}

- (BOOL) saveLastCheckpoint{
	if(self.currentMetadatas){
		[self saveToUserDefaults:self.currentMetadatas key:kUDSynchMetadatas];
		return  YES;
	}
	return NO;
}

- (void) resetCheckpoint{
	self.currentMetadatas = nil;
	[self deleteFromUserDefaults:kUDSynchMetadatas];
}

#pragma mark - Private Methods

- (NSArray*) parseAndUpdateMobileContacts{
	NSArray *contacts = [[AddressBookManager sharedInstance] contacts];
	
    //This contact list will contain all the synchroContacts susceptible to be sent to server.
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    //Initializing synchronization list
    self.currentMetadatas = [[NSMutableArray alloc] init];
    
    //This list will determine deleted contacts (every contact parsed will be deleted from this list
    // so that the remaining elements will be the deleted ones).
    NSMutableArray *auxiliarList = [[NSMutableArray alloc] initWithArray:[self retrieveFromUserDefaults:kUDSynchMetadatas]];
    
    for(ABContact *contact in contacts) {
        NSMutableDictionary *metadata = [ABSynchroManager deleteMetadataOfContact:contact onMetadataList:auxiliarList];

        ABContact *syncContact = [self incrementalABContact:contact andMetadata:metadata];
        if(syncContact){            
            [result addObject:syncContact];
        }
    }
    
    //Metadatas left in auxiliarList are the ones that identify native deleted contacts.
    for(NSMutableDictionary *metadata in auxiliarList){
        ABContact *syncContact = [self incrementalABContact:nil andMetadata:metadata];
        if(syncContact) [result addObject:syncContact];
    }
	
	return result;
}

- (ABContact*) incrementalABContact: (ABContact*) contact andMetadata:(NSMutableDictionary*)metadata {
    ABContact *result = nil;
    if(!contact && metadata){ //Deleted one
        result = [[ABContact alloc] init];
        result.contactId = ((NSNumber*)[metadata objectForKey:kContactIdKey]).intValue;
		result.status = ABContactStatusDeleted;
    }
	else if(contact && !metadata){ //New one (when initial synchro, all contacts enter this group)
		result = contact;
		result.status = ABContactStatusNew;
        
        //Create metadata of the contact
        metadata = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:contact.contactId],kContactIdKey,
                    contact.modificationDate, kModificationDateKey, nil];
        [_currentMetadatas addObject:metadata]; //filling metadataList
    }
	else if(contact && metadata) { //Existing one, checking modifications
        NSDate *savedDate = [metadata objectForKey:kModificationDateKey];
        if(![savedDate isEqualToDate:contact.modificationDate]){
			result = contact;
			result.status = ABContactStatusModified;
            
            //Setting a new metadata
            metadata = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:contact.contactId],kContactIdKey,
                        contact.modificationDate, kModificationDateKey, nil];
            [_currentMetadatas addObject:metadata]; //filling metadataList
        }else {
            [_currentMetadatas addObject:metadata]; //filling metadataList
        }
        
    }
    return result;
}

+ (NSMutableDictionary*) deleteMetadataOfContact: (ABContact*) contact onMetadataList: (NSMutableArray*) metadataList {
    NSNumber * contactId;
    int i = 0;
    for(NSMutableDictionary* elem in metadataList){
        contactId = [elem objectForKey:kContactIdKey];
        if([contactId intValue] == contact.contactId){
            [metadataList removeObjectAtIndex:i];
            return elem;
        }
        ++i;
    }
    return nil;
}

#pragma mark - UserDefaults

- (void)saveToUserDefaults:(id)value key:(NSString*)aKey
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (standardUserDefaults && value != nil) {
			id oldval = [standardUserDefaults objectForKey:aKey];
			if (oldval != nil)	// Remove the old value
				[standardUserDefaults removeObjectForKey:aKey];
			
			[standardUserDefaults setObject:value forKey:aKey];
			[standardUserDefaults synchronize];
	}
}

- (id)retrieveFromUserDefaults:(NSString*)aKey {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	id val = nil;
	
	if (standardUserDefaults)
		val = [standardUserDefaults objectForKey:aKey];
	
	return val;
}

- (void)deleteFromUserDefaults:(NSString*)aKey {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (standardUserDefaults)
		[standardUserDefaults removeObjectForKey:aKey];
}


#pragma mark - Singleton

// just create new object when object doesnt created yet
+ (ABSynchroManager *)sharedInstance {
    static ABSynchroManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[ABSynchroManager alloc] init];
        // Do any other initialisation stuff here
    });
    return sharedInstance;
}

- (void)dealloc {
    self.currentMetadatas = nil;
}


@end
