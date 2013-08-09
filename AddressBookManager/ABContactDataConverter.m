//
//  ABContactDataConverter.m
//  AddressBookManagerTest
//
//  Created by Eli Kohen on 8/9/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import "ABContactDataConverter.h"
#import "ABContact.h"

@implementation ABContactDataConverter

#pragma mark > ABAddressBook modifications

+ (void)copyPropertiesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact{
	[self copyPropertiesOfPerson:person toABContact:contact readPhotos:NO];
}

+ (void)copyPropertiesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact readPhotos: (BOOL) readPhotos{
    
    //read direct properties from person
	NSString *compositeName = ( NSString*)CFBridgingRelease(ABRecordCopyCompositeName(person));
    NSString *name		 = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
    NSString *middleName = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonMiddleNameProperty));
    NSString *lastName	 = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
    NSDate *birthday = ( NSDate*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonBirthdayProperty));
    NSString *department = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonDepartmentProperty));
    NSString *jobTitle = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonJobTitleProperty));
    NSString *company = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
    NSString *suffix = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonSuffixProperty));
    NSString *nickName = ( NSString*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonNicknameProperty));
    NSDate *creationDate = ( NSDate*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonCreationDateProperty));
    NSDate *modificationDate = ( NSDate*)CFBridgingRelease(ABRecordCopyValue(person, kABPersonModificationDateProperty));
    ABRecordID contactId = ABRecordGetRecordID(person);
    
    //copy previous properties to contact
	contact.compositeName = compositeName;
    contact.name = name;
    contact.middleName = middleName;
    contact.lastName = lastName;
    contact.contactId = contactId;
    contact.birthday = birthday;
    contact.department = department;
    contact.jobTitle = jobTitle;
    contact.company = company;
    contact.suffix = suffix;
    contact.nickName = nickName;
    contact.creationDate = creationDate;
    contact.modificationDate = modificationDate;
    
    //read multi-value properties
    [self retrieveEmailsAndEmailsLabelsForContact:contact withABRecordRef:person];
    [self retrieveAddressAndAddressLabelsForContact:contact withABRecordRef:person];
    [self retrievePhonesAndPhoneLabelsForContact:contact withABRecordRef:person];
    
    //save photo if needed
    if (readPhotos) {
        // Retrieve contact img
        CFDataRef imageData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
        if (imageData) {
            contact.image = [UIImage imageWithData:(__bridge NSData*)imageData];
            CFRelease(imageData);
        }
    }
    
    //release related variables
	name = nil;
	middleName = nil;
	lastName = nil;
	birthday = nil;
	department = nil;
	jobTitle = nil;
	company = nil;
	suffix = nil;
	nickName = nil;
	creationDate = nil;
	modificationDate = nil;
}

+ (void)addValuesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact{
	[self addValuesOfPerson:person toABContact:contact readPhotos:NO];
}

+ (void)addValuesOfPerson:(ABRecordRef)person toABContact:(ABContact*)contact readPhotos: (BOOL) readPhotos{
	
	//read multi-value properties
    [self addEmailsAndEmailsLabelsForContact:contact withABRecordRef:person];
    [self addAddressAndAddressLabelsForContact:contact withABRecordRef:person];
    [self addPhonesAndPhoneLabelsForContact:contact withABRecordRef:person];
	
	if(readPhotos && !contact.image){
		// Retrieve contact img
        CFDataRef imageData = ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
        if (imageData) {
            contact.image = [UIImage imageWithData:(__bridge NSData*)imageData];
            CFRelease(imageData);
        }
	}
}

+ (void)retrieveEmailsAndEmailsLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
    
	NSMutableArray *emailsArr = [[NSMutableArray alloc] init];
	NSMutableArray *emailsLabelsArr = [[NSMutableArray alloc] init];
    ABMultiValueRef emails  = ABRecordCopyValue(person, kABPersonEmailProperty); // ABMutableMultiValueRef: value list
    
    [self addInfoFrom:emails toValuesArr:emailsArr andLabelsArr:emailsLabelsArr];
	
    if (emails) CFRelease(emails);
    
	contact.emails = emailsArr;
	contact.emailsLabels = emailsLabelsArr;
}

+ (void)addEmailsAndEmailsLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
    
	NSMutableArray *emailsArr = [[NSMutableArray alloc] initWithArray:contact.emails];
	NSMutableArray *emailsLabelsArr = [[NSMutableArray alloc] initWithArray:contact.emailsLabels];
    ABMultiValueRef emails  = ABRecordCopyValue(person, kABPersonEmailProperty); // ABMutableMultiValueRef: value list
    
    [self addInfoFrom:emails toValuesArr:emailsArr andLabelsArr:emailsLabelsArr];
	
    if (emails) CFRelease(emails);
    
	contact.emails = emailsArr;
	contact.emailsLabels = emailsLabelsArr;
}

+ (void)retrievePhonesAndPhoneLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
    
	NSMutableArray *phonesArr = [[NSMutableArray alloc] init];
	NSMutableArray *phonesLabelsArr = [[NSMutableArray alloc] init];
	ABMutableMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);	// ABMutableMultiValueRef: value list
	
    [self addInfoFrom:phones toValuesArr:phonesArr andLabelsArr:phonesLabelsArr];
	
    if (phones) CFRelease(phones);
	
	contact.phones = phonesArr;
	contact.phonesLabels = phonesLabelsArr;
}

+ (void)addPhonesAndPhoneLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
    
	NSMutableArray *phonesArr = [[NSMutableArray alloc] initWithArray:contact.phones];
	NSMutableArray *phonesLabelsArr = [[NSMutableArray alloc] initWithArray:contact.phonesLabels];
	ABMutableMultiValueRef phones = ABRecordCopyValue(person, kABPersonPhoneProperty);	// ABMutableMultiValueRef: value list
	
    [self addInfoFrom:phones toValuesArr:phonesArr andLabelsArr:phonesLabelsArr];
	
    if (phones) CFRelease(phones);
	
	contact.phones = phonesArr;
	contact.phonesLabels = phonesLabelsArr;
}

+ (void)retrieveAddressAndAddressLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
	
    NSMutableArray *addressArr = [[NSMutableArray alloc] init];
	NSMutableArray *addressLabelsArr = [[NSMutableArray alloc] init];
	ABMutableMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);	// ABMutableMultiValueRef: value list
	
    [self addInfoFrom:address toValuesArr:addressArr andLabelsArr:addressLabelsArr];
	
    if (address) CFRelease(address);
    
    contact.address = addressArr;
	contact.addressLabels = addressLabelsArr;
    
}

+ (void)addAddressAndAddressLabelsForContact:(ABContact*)contact withABRecordRef:(ABRecordRef)person{
	
    NSMutableArray *addressArr = [[NSMutableArray alloc] initWithArray:contact.address];
	NSMutableArray *addressLabelsArr = [[NSMutableArray alloc] initWithArray:contact.addressLabels];
	ABMutableMultiValueRef address = ABRecordCopyValue(person, kABPersonAddressProperty);	// ABMutableMultiValueRef: value list
	
    [self addInfoFrom:address toValuesArr:addressArr andLabelsArr:addressLabelsArr];
	
    if (address) CFRelease(address);
    
    contact.address = addressArr;
	contact.addressLabels = addressLabelsArr;
    
}

+ (void)addInfoFrom:(ABMutableMultiValueRef)baseArr toValuesArr:(NSMutableArray*)valuesArr andLabelsArr:(NSMutableArray*)labelsArr{
    
    if (baseArr){
        
		for (CFIndex idx = 0; idx < ABMultiValueGetCount(baseArr); idx++){
            
            CFTypeRef field = ABMultiValueCopyValueAtIndex(baseArr, idx);
            NSString *sField = (field) ? (__bridge NSString*)field : @"";
     		[valuesArr addObject:sField];
            if (field) CFRelease(field);
            
            CFTypeRef lbl = ABMultiValueCopyLabelAtIndex(baseArr, idx);
            NSString *sLbl = (lbl) ? (__bridge NSString*)lbl : @"";
			[labelsArr addObject:sLbl];
            if (lbl) CFRelease(lbl);
            
		}
        
	}
	
}



@end
