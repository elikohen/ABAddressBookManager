//
//  ViewController.h
//  AddressBookManagerTest
//
//  Created by Eli Kohen on 8/7/13.
//  Copyright (c) 2013 EKGDev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UISearchDisplayDelegate, UISearchBarDelegate, ABNewPersonViewControllerDelegate, ABPersonViewControllerDelegate>

@end
