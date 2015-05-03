//
//  Person.h
//

#import <Foundation/Foundation.h>

/**
    Person class is used for copying contacts from phonebook.
 
 */
@interface Person : NSObject {
	
}
/* firstName used for storing the first name of contact*/
@property(nonatomic,strong) NSString *firstName;
/* lastName used for storing the last name of contact*/
@property(nonatomic,strong) NSString *lastName;
/* numbersArray used for storing numbers of a contact*/
@property(nonatomic,strong) NSMutableArray *numbersArray;
/* personID used to store the unique Identifier of a contact*/
@property NSInteger personID;
@end
