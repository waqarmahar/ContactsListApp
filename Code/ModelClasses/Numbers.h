//
//  Numbers.h
//  ContactList
//
//  Created by Muhammad Zeeshan on 30/04/2015.
//  Copyright (c) 2015 Muhammad Zeeshan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
/**
    Numbers NSManagedObject subclass used for saving contact numbers of a person contact in database.
 
 */

@interface Numbers : NSManagedObject

/*  this will return the NSString Object number */
@property (nonatomic, retain) NSString * number;

@end
