//
//  ViewController.m
//  AddressBookManagerTest
//
//  Created by Eli Kohen on 8/7/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import "ViewController.h"
#import "AddressBookManager.h"
#import "ABSynchroManager.h"

#define kHEADER_HEIGHT 20.0

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, atomic) NSArray *mContactList;
@property (strong, atomic) NSArray *mSectionTitles;
@property (strong, atomic) NSArray *mFilteredContactList;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
	UIBarButtonItem *addContact = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(showAddContact)];
	self.navigationItem.rightBarButtonItem = addContact;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadData) name:kNotificationAddressBookManagerUpdated object:nil];
	//[[AddressBookManager sharedInstance] refreshContacts]; <- Done on applicationDidBecomeActive
	[self loadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods
- (void) showAddContact{
	[AddressBookManager showAddContactOnViewController:self withPhoneNumber:nil];
}

- (void)loadData{
	NSArray *contacts = [[AddressBookManager sharedInstance] contacts];
	if(!contacts || contacts.count == 0){
		return;
	}
	
	[self setSectionsFromList:contacts];
	[self.tableView reloadData];
	
	
	//Just to test
	NSArray *toSynch = [[ABSynchroManager sharedInstance] addressBookModificationsSinceCheckpoint];
	for(ABContact *contact in toSynch){
		NSLog(@"Contact: %@ - Status: %d", contact.compositeName, contact.status);
	}
	[[ABSynchroManager sharedInstance] saveLastRetrievalAsCheckpoint];
}

-(void) setSectionsFromList:(NSArray *)origin{
	if(!origin) return;
	
	NSMutableArray *contactList = [[NSMutableArray alloc] init];
	NSMutableArray *sectionTitles = [[NSMutableArray alloc] init];
    //Creating sections
    NSMutableArray * sectionArray = nil;
    NSString* lastSection = nil;
    for(ABContact * contact in origin){
        NSString * text = [contact indexCharacter];
        if([text length] == 0){
            NSLog(@"[Warning] empty complete name here ?!?!");
            //strange situation, just skip contact.
            continue;
        }
        if(lastSection && [lastSection compare:text options:NSDiacriticInsensitiveSearch] == NSOrderedSame){
            [sectionArray addObject: contact];
        }
        else {
			if(sectionArray){
				[contactList addObject:sectionArray];
				sectionArray = nil;
			}
            sectionArray = [[NSMutableArray alloc] initWithObjects:contact, nil];
            lastSection = text;
			[sectionTitles addObject:lastSection];
        }
    }
    if(sectionArray && [sectionArray count] > 0){
        [contactList addObject:sectionArray];
    }
    sectionArray = nil;
	
	self.mContactList = contactList;
	self.mSectionTitles = sectionTitles;
}


- (UITableViewCell*)createContactsCell:(ABContact*) contact{
	static NSString *cellIdentifier = @"ContactsCell";
	
	UITableViewCell *cell =[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (cell == nil) {
		//IB engineer approved
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	
	if([cell.textLabel respondsToSelector:@selector(attributedText)]){
		//Bold contact on iOS6 or above
		NSRange boldRange;
		if(contact.sortingName && contact.sortingName.length > 0){
			boldRange = [contact.fullName rangeOfString:contact.sortingName options:NSCaseInsensitiveSearch|NSDiacriticInsensitiveSearch];
		}
		else{
			boldRange = NSMakeRange(0, contact.fullName.length);
		}
		NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:contact.fullName];
		[attrStr addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:[UIFont labelFontSize]] range:boldRange];
		
		cell.textLabel.attributedText = attrStr;
	}
	else{
		cell.textLabel.text = contact.fullName;
	}
	
	return cell;
}

- (ABContact*) contactFromTableView:(UITableView*) tableView andIndexPath: (NSIndexPath*) indexPath{
	NSArray *arrayOfContacts = nil;
	if(tableView == self.tableView){
		if(!self.mContactList) return nil;
		arrayOfContacts = [self.mContactList objectAtIndex:indexPath.section];
	}
	else{
		arrayOfContacts = self.mFilteredContactList;
	}
	
	if(!arrayOfContacts) return nil;
	ABContact *contact = [arrayOfContacts objectAtIndex:indexPath.row];
	return contact;
}


#pragma mark - ABNewPersonViewControllerDelegate
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person{
	if(person){
		[[AddressBookManager sharedInstance] refreshContacts];
	}
	[newPersonView dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ABPersonViewControllerDelegate
- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
	return YES;
}

#pragma mark - UISearchDisplayDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
	
	self.mFilteredContactList = [[AddressBookManager sharedInstance] contactsWithQuery:searchString];
	
	return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	if(tableView == self.tableView){
		if(!self.mContactList) return 1;
		return self.mContactList.count;
	}
	else{
		return 1;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	if(tableView == self.tableView){
		if(!self.mContactList) return 0;
		NSArray *sectionArray = [self.mContactList objectAtIndex:section];
		if(!sectionArray) return 0;
		return sectionArray.count;
	}
	else{
		return self.mFilteredContactList.count;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
	if(tableView == self.tableView){
		return kHEADER_HEIGHT;
	}
	else{
		return 0.0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	ABContact *contact = [self contactFromTableView:tableView andIndexPath:indexPath];
	return [self createContactsCell:contact];
}

//Right selector
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	if(tableView == self.tableView){
		return self.mSectionTitles;
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if(tableView == self.tableView){
		return [self.mSectionTitles objectAtIndex:section];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	if(tableView == self.tableView){
		return index;
	}
	return 0;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	ABContact *contact = [self contactFromTableView:tableView andIndexPath:indexPath];
	
	[[AddressBookManager sharedInstance] showContact:contact onViewController:self allowingEdition:NO];
}

@end
