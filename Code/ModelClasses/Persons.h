//
//  Persons.h
//  ContactList
//
//  Created by Muhammad Zeeshan on 30/04/2015.
//  Copyright (c) 2015 Muhammad Zeeshan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
/**
    Persons NSManagedObject subclass use to store the contact information into the database.
 
 */

@class Numbers;

@interface Persons : NSManagedObject

/* lName returns the last name of person */
@property (nonatomic, retain) NSString * lName;
/* fName returns the first name of person */
@property (nonatomic, retain) NSString * fName;
/* personID returns the unique contact ID of the contact */
@property (nonatomic, retain) NSNumber * personID;
/* contacts return arrays of numbers saved against this contact */
@property (nonatomic, retain) NSSet *contacts;
@end

@interface Persons (CoreDataGeneratedAccessors)

- (void)addContactsObject:(Numbers *)value;
- (void)removeContactsObject:(Numbers *)value;
- (void)addContacts:(NSSet *)values;
- (void)removeContacts:(NSSet *)values;

@end
