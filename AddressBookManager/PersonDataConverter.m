//
//  PersonDataConverter.m
//  fonyoukpn
//
//  Created by Eli Kohen.
//  Copyright 2013 fonYou. All rights reserved.
//

#import "PersonDataConverter.h"
#import "MobileContact.h"

@implementation PersonDataConverter

#pragma mark - Public methods

- (void)convertContact:(MobileContact*)theContact toPerson:(ABRecordRef)thePerson{
    
    //String properties
    if (theContact.name) {
        [self setPersonProperty:thePerson property:kABPersonFirstNameProperty value:(CFStringRef)theContact.name];
    }
    if (theContact.middleName) {
        [self setPersonProperty:thePerson property:kABPersonMiddleNameProperty value:(CFStringRef)theContact.middleName];
    }
    if (theContact.lastName) {
        [self setPersonProperty:thePerson property:kABPersonLastNameProperty value:(CFStringRef)theContact.lastName];
    }    
    if (theContact.department) {
        [self setPersonProperty:thePerson property:kABPersonDepartmentProperty value:(CFStringRef)theContact.department];
    }
    if (theContact.jobTitle) {
        [self setPersonProperty:thePerson property:kABPersonJobTitleProperty value:(CFStringRef)theContact.jobTitle];
    }
    if (theContact.company) {
        [self setPersonProperty:thePerson property:kABPersonOrganizationProperty value:(CFStringRef)theContact.jobTitle];
    }
    if (theContact.suffix) {
        [self setPersonProperty:thePerson property:kABPersonSuffixProperty value:(CFStringRef)theContact.suffix];
    }
    if (theContact.nickName) {
        [self setPersonProperty:thePerson property:kABPersonNicknameProperty value:(CFStringRef)theContact.nickName];
    }
    
    //Multi-String properties
    if (theContact.emails && theContact.emailsLabels && [theContact.emails count] == [theContact.emailsLabels count]) {
        int i = 0;
        for (NSString *email in theContact.emails) {
            NSString *theLabel = [theContact.emailsLabels objectAtIndex:i];
            [self setPersonProperty:thePerson
                           property:kABPersonEmailProperty
                              value:(CFStringRef)email
                              label:(CFStringRef)theLabel];
            i++;
        }
    }
    
    if (theContact.phones && theContact.phonesLabels && [theContact.phones count] == [theContact.phonesLabels count]) {
        int i = 0;
        for (NSString *phone in theContact.phones) {
            NSString *theLabel = [theContact.phonesLabels objectAtIndex:i];
            [self setPersonProperty:thePerson
                           property:kABPersonPhoneProperty
                              value:(CFStringRef)phone
                              label:(CFStringRef)theLabel];
            i++;
        }
    }
    
    //Multi-Dictionary properties
    if (theContact.address && theContact.addressLabels && [theContact.address count] == [theContact.addressLabels count]) {
        int i = 0;
        for (NSDictionary *address in theContact.address) {
            NSString *theLabel = [theContact.addressLabels objectAtIndex:i];
            
            NSArray *keys = [NSArray arrayWithObjects:(NSString*)kABPersonAddressStreetKey,(NSString*)kABPersonAddressCityKey,(NSString*)kABPersonAddressStateKey,(NSString*)kABPersonAddressZIPKey,(NSString*)kABPersonAddressCountryKey,(NSString*)kABPersonAddressCountryCodeKey,nil];
            
            for (NSString *key in keys) {
                [self setPersonProperty:thePerson
                               property:kABPersonAddressProperty
                                  value:(CFStringRef)[address objectForKey:key]
                                   part:(CFStringRef)key
                                  label:(CFStringRef)theLabel];
            }
            
            i++;
        }
    }
    
    //Photo
    if (theContact.image) {
        NSData *dataImg = UIImagePNGRepresentation(theContact.image);
        [self setPersonPhoto:thePerson value:(CFDataRef)dataImg];
    }
    
    //Birthday
    if (theContact.birthday) {
        [self setBirthday:thePerson value:(CFDateRef)theContact.birthday];
    }
    
}

#pragma mark - Private methods

#pragma mark => Property type identification methods

- (BOOL)isMultiStringPropertyType:(ABPropertyID)property{
    
    if (property == kABPersonEmailProperty ||               // Email(s) - kABMultiStringPropertyType
        property == kABPersonURLProperty   ||               // URL - kABMultiStringPropertyType
        property == kABPersonRelatedNamesProperty ||        // Names - kABMultiStringPropertyType
        property == kABPersonPhoneProperty){                // Generic phone number - kABMultiStringPropertyType    
        return YES;
    }else {
        return NO;
    }
    
}

- (BOOL)isMultiDictionaryProperty:(ABPropertyID)property{
    if (property == kABPersonAddressProperty ||             // Street Address - kABMultiDictionaryPropertyType
        property == kABPersonInstantMessageProperty){       // IM Addresses - kABMultiDictionaryPropertyType
        return YES;
    }else{
        return NO;
    }
}

- (BOOL)isPersonDatePropertyType:(ABPropertyID)property{
    return (property == kABPersonDateProperty);// Dates associated with this person - kABMultiDatePropertyType
}

- (BOOL)isIntegerPropertyType:(ABPropertyID)property{
    return (property == kABPersonKindProperty);// Person/Organization - kABIntegerPropertyType
}

#pragma mark => Specific set methods

- (void)setBirthday:(ABRecordRef)person
              value:(CFDateRef)value{
    if (value == nil){
        if (!ABRecordRemoveValue(person, kABPersonBirthdayProperty, error)){
            NSLog(@"[WARNING] Error removing birthday property");
        }
    }else{
        if (!ABRecordSetValue(person, kABPersonBirthdayProperty, value, error)) {
            NSLog(@"[WARNING] Error setting birthday property");
        }
    }
}

- (void)setPersonPhoto:(ABRecordRef)person
                 value:(CFDataRef)data{
    CFErrorRef err;
    if (data){
        if (!ABPersonSetImageData(person, data, &err)){
            NSLog(@"[WARNING] Error inserting picture into addressbook");
        }
    }
}

- (CFTypeRef)newMultiStringProperty:(ABRecordRef)person
                           property:(ABPropertyID)property
                              value:(CFStringRef)value
                              label:(CFStringRef)label{
    
    CFTypeRef realValue = nil;
    realValue = ABRecordCopyValue(person, property);
    if (!realValue){
        realValue = ABMultiValueCreateMutable(kABStringPropertyType);
    }else{
        CFTypeRef tempValue = ABMultiValueCreateMutableCopy(realValue);
        CFRelease(realValue);
        realValue = tempValue;
    }
    // TODO CHECK THIS COMPARISON!!!
    // The apple documentation says ABMultiValueGetPropertyType returns the type
    // of the values within it, and it really contains Strings, not MultiStrings
    if (ABMultiValueGetPropertyType(realValue) != kABStringPropertyType && ABMultiValueGetPropertyType(realValue) != kABMultiStringPropertyType){
        CFRelease(realValue);
        return nil;
    }
    
    CFStringRef aLabel = nil;
    
    int index;
    int total = ABMultiValueGetCount(realValue);
    for (index = 0; index < total; index++){
        aLabel = ABMultiValueCopyLabelAtIndex(realValue, index);
        if (aLabel){
            if (CFStringCompare(aLabel, label, 0) == 0){
                CFRelease(aLabel);
                aLabel = nil;
                break;
            }
            CFRelease(aLabel);
            aLabel = nil;
        }
    }    
    
    if (index < total){
        if (CFStringGetLength(value) == 0){
            ABMultiValueRemoveValueAndLabelAtIndex(realValue, index);            
        }else{
            ABMultiValueReplaceValueAtIndex(realValue, value, index);
        }
    }else{
        if (CFStringGetLength(value) != 0){
            ABMultiValueAddValueAndLabel(realValue, value, label, nil);
        }        
    }
    
    return realValue;
}

- (CFTypeRef)newMultiDictionaryProperty:(ABRecordRef)person
                               property:(ABPropertyID)property
                                  value:(CFStringRef)value
                                   part:(CFStringRef)part
                                  label:(CFStringRef)label{
    
    CFTypeRef realValue = nil;
    realValue = ABRecordCopyValue(person, property);
    if (!realValue){
        realValue = ABMultiValueCreateMutable(kABDictionaryPropertyType);
    }
    else{
        CFTypeRef tempValue = ABMultiValueCreateMutableCopy(realValue);
        CFRelease(realValue);
        realValue = tempValue;
    }
    
    // TODO CHECK THIS COMPARISON!!!
    // The apple documentation says ABMultiValueGetPropertyType returns the type
    // of the values within it, and it really contains Dictionary, not MultiDictionary
    if (ABMultiValueGetPropertyType(realValue) != kABDictionaryPropertyType
        && ABMultiValueGetPropertyType(realValue) !=kABMultiDictionaryPropertyType){        
        CFRelease(realValue);
        return nil;
    }
    
    CFMutableDictionaryRef indexValue = nil;
    CFStringRef aLabel = nil;
    
    int index;
    int total = ABMultiValueGetCount(realValue);
    for (index = 0; index < total; index++){
        aLabel = ABMultiValueCopyLabelAtIndex(realValue, index);
        if (aLabel){
            if (CFStringCompare(aLabel, label, 0) == 0){
                CFDictionaryRef tempdict = (CFDictionaryRef)ABMultiValueCopyValueAtIndex(realValue,index);
                if (!tempdict) {
                    CFRelease(aLabel);
                    aLabel = nil;
                    continue;
                }
                indexValue = (CFMutableDictionaryRef)CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0,tempdict);
                CFRelease(tempdict);
                CFRelease(aLabel);
                aLabel = nil;
                break;
            }
            CFRelease(aLabel);
            aLabel = nil;
        }
    }
    
    if (!indexValue){
        indexValue = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, nil, nil);
    }
    
    CFDictionarySetValue(indexValue, part, value);
    
    if (index < total){
        if (CFStringGetLength(value) == 0 && CFDictionaryGetCount(indexValue) == 0){
            ABMultiValueRemoveValueAndLabelAtIndex(realValue, index);
        }else{
            ABMultiValueReplaceValueAtIndex(realValue, indexValue, index);         
        }
    }else{
        if (CFStringGetLength(value) != 0){
            ABMultiValueAddValueAndLabel(realValue, indexValue, label, nil);            
        }
    }   

    CFRelease(indexValue);
    
    return realValue;
}

- (CFTypeRef)newPersonDateProperty:(ABRecordRef)person
                          property:(ABPropertyID)property
                             value:(CFStringRef)value{
	//Implement when required
	NSLog(@"Function not implemented error");
	abort();
    return nil;
}

- (CFTypeRef)newIntegerProperty:(ABRecordRef)person
                       property:(ABPropertyID)property
                          value:(CFStringRef)value{
	//Implement when required
	NSLog(@"Function not implemented error");
	abort();
    return nil;
}

#pragma mark => Generic set methods for string value properties

- (void) setPersonProperty:(ABRecordRef)person
                  property:(ABPropertyID)property
                     value:(CFStringRef)value{
    
    [self setPersonProperty:person
                   property:property
                      value:value
                       part:nil];
    
}

- (void) setPersonProperty:(ABRecordRef)person
                  property:(ABPropertyID)property
                     value:(CFStringRef)value
                      part:(CFStringRef)part{ // Only used for Multi Prop Values
    
    [self setPersonProperty:person
                   property:property
                      value:value
                       part:part
                      label:nil];
    
}

- (void) setPersonProperty:(ABRecordRef)person
                  property:(ABPropertyID)property
                     value:(CFStringRef)value
                     label:(CFStringRef)label{ // Only used for Multi Prop Values
    
    [self setPersonProperty:person
                   property:property
                      value:value
                       part:nil
                      label:label];
    
}    

- (void) setPersonProperty:(ABRecordRef)person
                  property:(ABPropertyID)property
                     value:(CFStringRef)value
                      part:(CFStringRef)part  // Only used for Multi Prop Values - @"" means ignore
                     label:(CFStringRef)label{ // Only used for Multi Prop Values
    /* Assume string type!
     kABPersonFirstNameProperty:          // First name - kABStringPropertyType
     kABPersonLastNameProperty:           // Last name - kABStringPropertyType
     kABPersonMiddleNameProperty:         // Middle name - kABStringPropertyType
     kABPersonPrefixProperty:             // Prefix ("Sir" "Duke" "General") - kABStringPropertyType
     kABPersonSuffixProperty:             // Suffix ("Jr." "Sr." "III") - kABStringPropertyType
     kABPersonNicknameProperty:           // Nickname - kABStringPropertyType
     kABPersonFirstNamePhoneticProperty:  // First name Phonetic - kABStringPropertyType
     kABPersonLastNamePhoneticProperty:   // Last name Phonetic - kABStringPropertyType
     kABPersonMiddleNamePhoneticProperty: // Middle name Phonetic - kABStringPropertyType
     kABPersonOrganizationProperty:       // Company name - kABStringPropertyType
     kABPersonJobTitleProperty:           // Job Title - kABStringPropertyType
     kABPersonDepartmentProperty:         // Department name - kABStringPropertyType
     kABPersonNoteProperty:               // Note - kABStringPropertyType
     */
    
    
    if (!value || !person){
        return;
    }
    
    CFTypeRef realValue = nil;
    
    if ([self isMultiStringPropertyType:property]) {
        realValue = [self newMultiStringProperty:person property:property value:value label:label];
    }else if([self isMultiDictionaryProperty:property]){
        realValue = [self newMultiDictionaryProperty:person property:property value:value part:part label:label];
    }else if([self isPersonDatePropertyType:property]){
        realValue = [self newPersonDateProperty:person property:property value:value];
    }else if([self isIntegerPropertyType:property]){
        realValue = [self newIntegerProperty:person property:property value:value];
    }else {
        if (CFStringGetLength(value) > 0){
            realValue = (CFTypeRef)CFBridgingRetain([[NSString alloc] initWithString: (__bridge NSString*)value]);
        }
    }
    
    if (realValue == nil){
        if (!ABRecordRemoveValue(person, property, error)){
            NSLog(@"[WARNING] Error removing property");
        }
    }else{        
        if (!ABRecordSetValue(person, property, realValue, error)) {
            NSLog(@"[WARNING] Error setting property");
        }
    }
    
    if(realValue){
        CFRelease(realValue);
    }
}

@end
