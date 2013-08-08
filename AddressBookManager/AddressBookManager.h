//
//  AddressBookManager.h
//
//  Created by Albert Hernández on 29/11/10.
//  Updated by Ivan Roige on 16/5/12.
//  Adapted to ARC by Eli Kohen on 24/04/13
//

/**
 * This object reads device native contacts using asynch method. Events are generated and fired using 'AddressBookManagerBasicInfoDelegate' protocol.
 */

#import <UIKit/UIKit.h>
#import "MobileContact.h"

#define kNotificationAddressBookManagerUpdated @"kNotificationAddressBookManagerUpdated"
#define kNotificationAddressBookManagerNoPermission @"kNotificationAddressBookManagerNoPermission"

@class MobileContacts;
@class ProgressData;

typedef enum{
	AddessBookManagerFilterAllContacts = 0,
	AddessBookManagerFilterOnlyWithNumbers,
	AddessBookManagerFilterOnlyNameAndNumbers
}AddessBookManagerFilter;

@protocol AddressBookManagerDelegate

@required
- (void)contactsLoaded;
@required
- (void)contactsPermissionDenied;

@optional

- (void)updateProgress:(ProgressData*)progress;

@end

#pragma mark -

@interface AddressBookManager : NSObject

/**
 *  Configuration parameter. If true, contact photo is skipped (so read process is faster)
 */
@property (nonatomic) BOOL readPhotos;

/**
 * Configuration parameter. Sets whether to filter contacts and with which values
 */
@property (nonatomic) AddessBookManagerFilter contactsFilter;

/*
 *  Contacts read process delegate
 */
@property (nonatomic, weak) NSObject<AddressBookManagerDelegate> *delegat;

/*
 * This method reads all contacts stored on iPhone AddressBook. Asynch method.
 */
- (void)retrieveContactsWithDelegate:(NSObject<AddressBookManagerDelegate>*)aDelegate;

/*
 * Refresh contacts list without delegate. This method will update 'contacts' property.
 */
- (void)refreshContacts;

/**
 * Indicates whether contacts has been loaded or not.
 */
- (BOOL) isStarted;

/**
 * Returns the contact list, must call 'refreshContacts' or 'retrieveContactsWithDelegate' first.
 */
- (NSArray*) contacts;

/**
 * Returns the contact list filtered by query, must call 'refreshContacts' or 'retrieveContactsWithDelegate' first.
 */
- (NSArray*) contactsWithQuery: (NSString*) query;

/**
 * Returns the contact that matches the phone number, must call 'refreshContacts' or 'retrieveContactsWithDelegate' first.
 */
- (MobileContact*) contactByPhoneNumber: (NSString*) phoneNumber;

/**
 * Returns whether or not we have access to the contacts programatically.
 * NOTE: Must be called AFTER first "retrieveContacts/refreshContacts" call.
 */
- (BOOL)hasContactAccessPermission;

/**
 * Returns whether the user selected order by last name
 */
- (BOOL)isOrderByLastName;

/**
 * Returns whether the user selected to show contacts by last name
 */
- (BOOL)isShowByLastName;


/*
 * Reads contact photo and stores/updates it in the contact
 */
- (BOOL)loadContactPhoto:(MobileContact*)contact;

/*
 *  Insert new contact on native addressbook.
 *  @param theContact contact to add.
 *  @return result YES means ok & MobileContact object updated.
 */
- (BOOL) insertContact:(MobileContact*)theContact;

/*
 *  Modify an existing contact on native addressbook.
 *  @param theContact contact to modify.
 *  @return result YES means ok & MobileContact object updated.
 */
- (BOOL) modifyContact:(MobileContact*)theContact;

/*
 *  Remove contact on native addressbook
 *  @param theContact contact to remove.
 *  @return result YES means ok.
 */
- (BOOL) removeContact:(MobileContact*)theContact;

/*
 *  Remove all contacts on native addressbook.
 */
- (BOOL) removeAllContacts;

/*
 * Get singleton instance
 */
+ (AddressBookManager*)sharedInstance;

@end
