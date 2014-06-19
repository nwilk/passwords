// Copyright 2014 Neil Wilkinson
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Stores actual passwords in a secure store. The label and uid (used to look it up) is stored in NSUserDefaults.

#import "PasswordList.h"
#import "PasswordInfoItem.h"
#import "JNKeychain.h"

#define kPrefsPasswordIds @"passwords"

@implementation PasswordList {
}

- (id)init {
    self = [super init];
    if (self) {

        NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
        NSData *passwordInfoData = [userPrefs objectForKey:kPrefsPasswordIds];

        if (passwordInfoData == nil) {
            _passwordInfoData = [[NSMutableArray alloc] init];
            [_passwordInfoData addObject:[[PasswordInfoItem alloc] initWithUid:1 label:@"iTunes"]];
        } else {
            _passwordInfoData = [NSKeyedUnarchiver unarchiveObjectWithData:passwordInfoData];
        }
    }

    return self;
}

- (void)savePasswordsInfos {
    NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.passwordInfoData];
    [userPrefs setObject:data forKey:kPrefsPasswordIds];
    [userPrefs synchronize];
}

- (NSUInteger)count {
    return [self.passwordInfoData count];
}

- (NSString *)password:(NSUInteger)index {
    return [JNKeychain loadValueForKey:[self getKeyForItem:[self.passwordInfoData objectAtIndex:index]]];
}

- (NSString *)getKeyForItem:(PasswordInfoItem *)item {
    return [[NSNumber numberWithInteger:item.uid] stringValue];
}

- (NSString *)label:(NSUInteger)index {
    id const o = [self.passwordInfoData objectAtIndex:index];
    return ((PasswordInfoItem *) o).label;
}

- (void)writeLabel:(NSString *)label forRow:(NSInteger)row {
    PasswordInfoItem *item = [self.passwordInfoData objectAtIndex:(NSUInteger) row];
    item.label = label;
}

- (void)writePassword:(NSString *)text forRow:(NSInteger)row {
    [JNKeychain saveValue:text forKey:[self getKeyForItem:[self.passwordInfoData objectAtIndex:(NSUInteger) row]]];
}

- (void)addNew:(NSString *)label password:(NSString *)password {
    NSInteger uid = [self allocateNewUid];
    PasswordInfoItem *newItem = [[PasswordInfoItem alloc] initWithUid:uid label:label];

    [self.passwordInfoData addObject:newItem];
    [self sortList];

    [JNKeychain saveValue:password forKey:[self getKeyForItem:newItem]];
}

- (void)deleteAtIndex:(NSUInteger)index {
    PasswordInfoItem *const item = [self.passwordInfoData objectAtIndex:index];
    [self.passwordInfoData removeObjectAtIndex:index];
    [JNKeychain deleteValueForKey:[self getKeyForItem:item]];
    [self sortList];
}

- (void)sortList {
    [self.passwordInfoData sortUsingComparator:^(PasswordInfoItem *item1, PasswordInfoItem *item2) {
        NSLog(@"sort comparing %@ vs %@", item1.label, item2.label);
        return [item1.label.uppercaseString compare:item2.label.uppercaseString];
    }];
}

- (NSInteger)allocateNewUid {
    NSInteger highest = 0;
    for (PasswordInfoItem *passwordItem in self.passwordInfoData) {
        if (passwordItem.uid > highest) {
            highest = passwordItem.uid;
        }
    }

    return highest + 1;
}
@end