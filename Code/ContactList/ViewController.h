//
//  ViewController.h
//  ContactList
//
//  Created by Muhammad Zeeshan on 30/04/2015.
//  Copyright (c) 2015 Muhammad Zeeshan. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
    ViewController used for displaying sync status, and changes in the phone book since last sync.
*/

@interface ViewController : UIViewController


/* UITextView for showing status messages and changes in Phonebook*/
@property (weak, nonatomic) IBOutlet UITextView *statusTextView;

/* managedObjectContext for managing core data*/
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
/* managedObjectModel for managing core data model*/
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
/* persistentStoreCoordinator for managing core data store*/
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
/* scanButton for comparison between original and local contacts*/
@property (weak, nonatomic) IBOutlet UIButton *scanButton;

/* start comparison method*/
- (IBAction)ScanRealDBAction:(id)sender;
@end

