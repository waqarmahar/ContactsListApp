//
//  ViewController.m
//  ContactList
//
//  Created by Muhammad Zeeshan on 30/04/2015.
//  Copyright (c) 2015 Muhammad Zeeshan. All rights reserved.
//

#import "ViewController.h"
#import <AddressBook/AddressBook.h>
#import "Person.h"
#import "Persons.h"
#import "Numbers.h"
#import "MBProgressHUD.h"
@interface ViewController ()
/* Method for copying contacts from contacts application. It will return list of contacts*/
-(NSMutableArray *)copyAllContacts;
/* Method for saving contacts to local database*/
-(void)saveContactsToDB:(NSArray *)contacts;
/* Method for copying and storing contacts to local database */
-(void)loadAndStoreContacts;
/* Method which compares multiple numbers of a same contact from phonebook and local database */
-(BOOL)comparesNumbersInBothContacts:(NSArray *)localContacts realContactList:(NSArray *)realContacts;
/* Method for updating local database after scan*/
-(void)updateLocalDatabase:(NSArray*)realContacts;
/* Method for deleting all previous records in the database */
- (void)deleteAllEntities:(NSString *)nameEntity;
/* Methods for displaying the results*/
-(void)displayDatabaseChanges:(NSString *)newContacts changedContacts:(NSString *)contactsChanged deletedContacts:(NSString *)contactsDeleted;
@end


@implementation ViewController

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize statusTextView;
@synthesize scanButton;
#pragma mark --
#pragma mark Views Loading Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.scanButton.hidden=YES;
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    // If didn't find any thing for the key. Then it means that app is running for the first time. Store contacts to DB.
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"loadContacts"]) {
        self.scanButton.hidden=YES;
        if(ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined){
            
            self.statusTextView.text = @"";
            ABAddressBookRequestAccessWithCompletion(ABAddressBookCreateWithOptions(NULL, nil), ^(bool granted, CFErrorRef error) {
                if (!granted){
                    //NSLog(@"not granted when not determined");
                    return;
                }
                //NSLog(@"granted when not determined");
                
                [self performSelectorOnMainThread:@selector(loadContacts) withObject:nil waitUntilDone:NO];
                
            });
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
            
            self.statusTextView.text = @"Syncing is in wait";
            MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:HUD];
            
            HUD.labelText = @"Syncing is in wait";
            
            [HUD showWhileExecuting:@selector(loadAndStoreContacts) onTarget:self withObject:nil animated:YES];
            self.statusTextView.text = @"Sync is done";
            
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied ||
                 ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusRestricted){
            
            self.statusTextView.text = @"Permission Denied. Please allow from settings.";
        }
    }
    else{
        self.scanButton.hidden=NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"loadContacts"];
    
}
#pragma mark -- 
#pragma mark Core Data Setup Methods

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL =[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"ContactList.sqlite"]];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        //NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"ContactList" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}
- (void)deleteAllEntities:(NSString *)nameEntity
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:nameEntity];
    [fetchRequest setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (NSManagedObject *object in fetchedObjects)
    {
        [self.managedObjectContext deleteObject:object];
    }
    
    error = nil;
    [self.managedObjectContext save:&error];
}
#pragma mark --
#pragma mark Contacts Sync Methods
-(void)loadAndStoreContacts{
    NSMutableArray *contacts = [self copyAllContacts];
    [self saveContactsToDB:contacts];
    [self performSelectorOnMainThread:@selector(updateStatus) withObject:nil waitUntilDone:NO];
}
-(void)updateStatus{
    self.scanButton.hidden=NO;
    self.statusTextView.text = @"Syncing is done";
}
-(void)saveContactsToDB:(NSArray *)contacts{
    for (int index = 0;index < [contacts count] ;index++) {
        
        Person *contact = [contacts objectAtIndex:index];
        
        Persons *person = [NSEntityDescription
                           insertNewObjectForEntityForName:@"Persons"
                           inManagedObjectContext:self.managedObjectContext];
        person.fName = contact.firstName;
        person.lName = contact.lastName;
        person.personID = [NSNumber numberWithInteger:contact.personID];
        
        for (NSString *phoneNumber in contact.numbersArray) {
            Numbers *number = [NSEntityDescription
                               insertNewObjectForEntityForName:@"Numbers"
                               inManagedObjectContext:self.managedObjectContext];
            number.number = phoneNumber;
            [person addContactsObject:number];
        }
        
    }
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    else{
        //NSLog(@"Save Successfully");
    }
}
-(NSMutableArray *)copyAllContacts{
    
    CFErrorRef error = NULL;
    NSMutableArray *contactsArray = [NSMutableArray array];
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    
    if (addressBook != nil) {
        
        NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
        
        NSUInteger i = 0; for (i = 0; i < [allContacts count]; i++)
        {
            Person *person = [[Person alloc] init];
            ABRecordRef contactPerson = (__bridge ABRecordRef)allContacts[i];
            person.personID = ABRecordGetRecordID(contactPerson);
            
           //NSLog(@"record ID %ld",(long)person.personID);

            person.firstName = (__bridge_transfer NSString *)ABRecordCopyValue(contactPerson,
                                                                                  kABPersonFirstNameProperty);
            if (person.firstName==nil) {
                person.firstName=@"";
            }
            person.lastName = (__bridge_transfer NSString *)ABRecordCopyValue(contactPerson, kABPersonLastNameProperty);
            
            if (person.lastName==nil) {
                person.lastName=@"";
            }
            //NSLog(@"last name is %@",person.lastName);
            
            //NSLog(@"name is %@ %@",person.firstName,person.lastName);

            ABMultiValueRef emails = ABRecordCopyValue(contactPerson, kABPersonPhoneProperty);
            

            NSUInteger j = 0;
            NSMutableArray *contactNumbers=[NSMutableArray array];
            for (j = 0; j < ABMultiValueGetCount(emails); j++) {
                NSString *number = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(emails, j);
                //NSLog(@"number is %@",number);
                [contactNumbers addObject:number];
            }
            person.numbersArray = contactNumbers;
            [contactsArray addObject:person];
        }
        
    
        CFRelease(addressBook);
    } else { 
    
        NSLog(@"Error reading Address Book");
    }
    return contactsArray;
}
-(void)loadContacts{
    self.statusTextView.text = @"Syncing is in wait";
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:HUD];
    
    HUD.labelText = @"Syncing is in wait";
    
    [HUD showWhileExecuting:@selector(loadAndStoreContacts) onTarget:self withObject:nil animated:YES];
}
#pragma mark --
#pragma mark User Interaction Methods
- (IBAction)ScanRealDBAction:(id)sender {
    //NSLog(@"Scanning Start");
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized){
        NSArray *realContacts = [self copyAllContacts];
        // Load all contacts from database
        NSFetchRequest * localDBContactsRequest = [[NSFetchRequest alloc] init];
        [localDBContactsRequest setEntity:[NSEntityDescription entityForName:@"Persons" inManagedObjectContext:self.managedObjectContext]];
        [localDBContactsRequest setIncludesPropertyValues:YES];
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"personID" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
        
        [localDBContactsRequest setSortDescriptors:sortDescriptors];
        NSError * error = nil;
        NSArray * localContacts = [self.managedObjectContext executeFetchRequest:localDBContactsRequest error:&error];
        //NSLog(@"local contacts count %lu",(unsigned long)localContacts.count);
        
        int index = 0;
        
        NSString *contactsDeleted = @"";
        NSString *contactsChanged = @"";
        for (Persons *localContact in localContacts) {
            //NSLog(@"local contact ID %ld",(long)[localContact.personID integerValue]);
            Person *realContact = nil;
            if (index<realContacts.count) {
                 realContact = [realContacts objectAtIndex:index];
            }
            
            //NSLog(@"real contact ID %d",realContact.personID );
            if(realContact==nil || localContact.personID.integerValue < realContact.personID){
                NSString *numbers=@"";
                for (Numbers *contactNumber in [localContact.contacts allObjects]) {
                    numbers = [numbers stringByAppendingString:[NSString stringWithFormat:@"<%@> ",contactNumber.number]];
                }
                contactsDeleted = [contactsDeleted stringByAppendingString:[NSString stringWithFormat:@"%@ %@ Ph# %@ \n",localContact.fName,localContact.lName,numbers]];
                contactsDeleted = [contactsDeleted stringByAppendingString:@" \n "];
            }
            if(localContact.personID.integerValue == realContact.personID){
                if (![realContact.firstName isEqualToString:localContact.fName] || ![realContact.lastName isEqualToString:localContact.lName] || [self comparesNumbersInBothContacts:[localContact.contacts allObjects] realContactList:realContact.numbersArray]) {
                    NSString *numbers=@"";
                    
                    for (NSString *contactNumber in realContact.numbersArray) {
                        numbers = [numbers stringByAppendingString:[NSString stringWithFormat:@"<%@> ",contactNumber]];
                    }
                    contactsChanged = [contactsChanged stringByAppendingString:[NSString stringWithFormat:@"%@ %@ Ph# %@ \n",realContact.firstName,realContact.lastName,numbers]];
                    
                    contactsChanged = [contactsChanged stringByAppendingString:@" \n "];
                }
                index++;
            }
        }
        NSString *newContacts = @"";
        if (index<realContacts.count) {
            for (int i = index; i < realContacts.count; i++) {
                Person *newContact=[realContacts objectAtIndex:i];
                NSString *numbers=@"";
                for (NSString *contactNumber in newContact.numbersArray) {
                    numbers = [numbers stringByAppendingString:[NSString stringWithFormat:@"<%@> ",contactNumber]];
                }
                newContacts = [newContacts stringByAppendingString:[NSString stringWithFormat:@"%@ %@ Ph# %@ \n",newContact.firstName,newContact.lastName,numbers]];
                
            }
        }
        
        if ([newContacts isEqualToString:@""]) {
            newContacts=@"No new contact added";
        }
        if ([contactsChanged isEqualToString:@""]) {
            contactsChanged=@"No contact changed";
        }
        if ([contactsDeleted isEqualToString:@""]) {
            contactsDeleted=@"No contact deleted";
        }
        [self displayDatabaseChanges:newContacts changedContacts:contactsChanged deletedContacts:contactsDeleted];
        ////Store contacts in DB///////
        MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:HUD];
        
        HUD.labelText = @"Syncing is in wait";
        
        [HUD showWhileExecuting:@selector(updateLocalDatabase:) onTarget:self withObject:realContacts animated:YES];
        
    }
    else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"You are not authorized to access phone book"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    
    
}
-(void)displayDatabaseChanges:(NSString *)newContacts changedContacts:(NSString *)contactsChanged deletedContacts:(NSString *)contactsDeleted{
    NSMutableAttributedString * textViewString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"New Contacts \n %@ \n Changed Contacts \n %@ \n Deleted Contacts \n %@ \n",newContacts,contactsChanged,contactsDeleted]];
    NSInteger startingIndex=0;
    //////for New Contacts //////////////////
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:20.0]
                           range:NSMakeRange(startingIndex, 12)];
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(99.0/255.0) green:(169.0/255.0) blue:(36.0/255.0) alpha:1] range:NSMakeRange(startingIndex,12)];
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:15.0]
                           range:NSMakeRange(startingIndex+15, [newContacts length])];
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(15, [newContacts length])];
    startingIndex=startingIndex+18+[newContacts length];
    //////for Changed Contacts//////////////////////////
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:(78.0/255.0) green:(105.0/255.0) blue:(162.0/255.0) alpha:1] range:NSMakeRange(startingIndex,17)];
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:20.0]
                           range:NSMakeRange(startingIndex, 17)];
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:15.0]
                           range:NSMakeRange(startingIndex+19, [contactsChanged length])];
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(startingIndex+19, [contactsChanged length])];
    startingIndex=startingIndex+21+[contactsChanged length];
    ///////for Contacts Deleted/////////////////
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.87 green:0.25 blue:0.025 alpha:1] range:NSMakeRange(startingIndex,17)];
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:20.0]
                           range:NSMakeRange(startingIndex, 17)];
    [textViewString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:15.0]
                           range:NSMakeRange(startingIndex+20, [contactsDeleted length])];
    [textViewString addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:NSMakeRange(startingIndex+20, [contactsDeleted length])];
    
    self.statusTextView.attributedText=textViewString;
}
-(void)updateLocalDatabase:(NSArray*)realContacts{
    [self deleteAllEntities:@"Persons"];
    [self saveContactsToDB:realContacts];
}
-(BOOL)comparesNumbersInBothContacts:(NSArray *)localContacts realContactList:(NSArray *)realContacts{
    BOOL isChanged=NO;
    
    if (localContacts.count!=realContacts.count) {
        return YES;
        
    }
    NSMutableArray *dbNumbers=[NSMutableArray array];
    for (Numbers *contactNumber in localContacts) {
        [dbNumbers addObject:contactNumber.number];
    }
    [dbNumbers removeObjectsInArray:realContacts];
    if (dbNumbers.count!=0) {
        isChanged=YES;
    }
    return isChanged;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
