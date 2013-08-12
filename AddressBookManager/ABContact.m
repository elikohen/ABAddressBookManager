//
//  ABContact.m
//
//  Created by Albert Hernández on 29/11/10.
//  Updated by Ivan on 16/5/12.
//

#import "ABContact.h"
#import "AddressBookManager.h"

@implementation NSString (ABM)

- (BOOL)contains: (NSString*) another{
	return [self contains:another options:0];
}

- (BOOL)contains: (NSString*) another options: (NSStringCompareOptions) options{
	if(!another) return NO;
	
	NSRange range = [self rangeOfString:another options:options];
	return range.location != NSNotFound;
}

@end

#pragma mark -

@interface ABContact ()

@end

#pragma mark -

@implementation ABContact

#pragma mark - Object lifecycle

- (id)init{
    self = [super init];
    if (self) {
        self.contactId = -1;
		self.status = 0;
    }
    return self;
}

- (UIImage*) image{
	if(!_image){
		[[AddressBookManager sharedInstance] loadContactPhoto:self];
	}
	
	return _image;
}

- (NSString*)fullName{
	if(self.compositeName)
		return [self.compositeName capitalizedString];
	
	if(self.phones.count > 0)
		return [self.phones objectAtIndex:0];
	
	return nil;
}

- (NSString*)sortingName{
	NSString *sortingName = [self fullName];
	if(self.sortOrder == ABContactLocaleNameSurname && [sortingName contains: self.name options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch]){
		sortingName = self.name;
	}
	else if(self.sortOrder == ABContactLocaleSurnameName && [sortingName contains: self.lastName options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch]){
		sortingName = self.lastName;
	}
	return sortingName;
}

- (NSString*)indexCharacter{
	
	NSString *index = [[self.sortingName substringToIndex:1] capitalizedString];
	index = [[NSString alloc] initWithData:[index dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES] encoding:NSASCIIStringEncoding];
	if((([index compare:@"Z"] != NSOrderedDescending) && ([index compare:@"A"] != NSOrderedAscending)) ||
	   (([index compare:@"z"] != NSOrderedDescending) && ([index compare:@"a"] != NSOrderedAscending))){
		return index;
	}
	return @"#";
}

- (NSComparisonResult)compare:(ABContact *)otherObject {
	
	NSString *myName = [self indexCharacter];
	NSString *otherName = [otherObject indexCharacter];
    return [myName compare:otherName options:NSDiacriticInsensitiveSearch];
}

- (NSString*)description{
    return [NSString stringWithFormat:@"Composite Name: %@",self.compositeName];
}

@end
