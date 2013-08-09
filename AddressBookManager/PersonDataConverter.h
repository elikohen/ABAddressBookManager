//
//  PersonDataConverter.h
//  fonyoukpn
//
//  Created by Eli Kohen.
//  Copyright 2013 fonYou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class ABContact;

@interface PersonDataConverter : NSObject{
    CFErrorRef * error;
}

- (void)convertContact:(ABContact*)theContact toPerson:(ABRecordRef)thePerson;

@end
