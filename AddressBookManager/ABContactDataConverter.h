//
//  ABContactDataConverter.h
//  AddressBookManagerTest
//
//  Created by Eli Kohen on 8/9/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class ABContact;

@interface ABContactDataConverter : NSObject

+ (void)copyPropertiesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact;
+ (void)copyPropertiesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact readPhotos: (BOOL) readPhotos;
+ (void)addValuesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact;

@end
